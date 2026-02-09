const {
  Warehouse,
  User,
  Product,
  ProductStock,
  SalesOrder,
  PickList,
  PackingTask,
  Customer,
} = require('../models');
const { Op } = require('sequelize');

/**
 * GET /api/dashboard/stats
 * Role-aware: company_admin/warehouse_manager/inventory_manager/viewer see company scope;
 * super_admin can pass ?companyId= for a company or get first-company stats;
 * picker/packer see their company scope.
 */
async function stats(req, res, next) {
  try {
    const user = req.user;
    let companyId = user.companyId || null;
    if (user.role === 'super_admin' && req.query.companyId) {
      companyId = parseInt(req.query.companyId, 10);
    }

    const baseWhere = companyId ? { companyId } : {};

    const counts = await Promise.all([
      Warehouse.count({ where: baseWhere }),
      User.count({ where: { ...baseWhere, status: 'ACTIVE' } }),
      Product.count({ where: { ...baseWhere, status: 'ACTIVE' } }),
      Customer.count({ where: baseWhere }),
      SalesOrder.count({
        where: {
          ...baseWhere,
          status: { [Op.in]: ['pending', 'pick_list_created', 'picking', 'packing'] },
        },
      }),
      SalesOrder.count({ where: baseWhere }),
      companyId
        ? PickList.count({
            where: { status: { [Op.in]: ['pending', 'in_progress'] } },
            include: [{ association: 'SalesOrder', where: { companyId }, required: true, attributes: [] }],
          })
        : PickList.count({ where: { status: { [Op.in]: ['pending', 'in_progress'] } } }),
      companyId
        ? PackingTask.count({
            where: { status: { [Op.in]: ['pending', 'packing'] } },
            include: [{ association: 'SalesOrder', where: { companyId }, required: true, attributes: [] }],
          })
        : PackingTask.count({ where: { status: { [Op.in]: ['pending', 'packing'] } } }),
    ]);

    // Total stock: sum of ProductStock.quantity (optionally scoped by company via Warehouse)
    let totalStock = 0;
    if (companyId) {
      const warehouses = await Warehouse.findAll({ where: { companyId }, attributes: ['id'] });
      const whIds = warehouses.map((w) => w.id);
      const result = await ProductStock.sum('quantity', {
        where: { warehouseId: { [Op.in]: whIds } },
      });
      totalStock = result || 0;
    } else {
      const result = await ProductStock.sum('quantity');
      totalStock = result || 0;
    }

    // Low stock: products where sum(stock) < reorderLevel (company-scoped)
    let lowStockCount = 0;
    if (companyId) {
      const products = await Product.findAll({
        where: { ...baseWhere, status: 'ACTIVE' },
        attributes: ['id', 'reorderLevel'],
      });
      const whIds = (await Warehouse.findAll({ where: { companyId }, attributes: ['id'] })).map((w) => w.id);
      for (const p of products) {
        const sum = await ProductStock.sum('quantity', {
          where: { productId: p.id, warehouseId: { [Op.in]: whIds } },
        });
        if ((sum || 0) < (p.reorderLevel || 0)) lowStockCount += 1;
      }
    }

    res.json({
      success: true,
      data: {
        warehouses: counts[0],
        users: counts[1],
        products: counts[2],
        customers: counts[3],
        pendingOrders: counts[4],
        totalOrders: counts[5],
        totalStock,
        lowStockCount,
        pickingPendingCount: counts[6],
        packingPendingCount: counts[7],
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/dashboard/charts
 * Returns chart-ready data: ordersByDay, ordersByStatus, stockByWarehouse, topProducts
 */
async function charts(req, res, next) {
  try {
    const user = req.user;
    let companyId = user.companyId || null;
    if (user.role === 'super_admin' && req.query.companyId) {
      companyId = parseInt(req.query.companyId, 10);
    }
    const baseWhere = companyId ? { companyId } : {};

    const daysBack = 14;
    const startDate = new Date();
    startDate.setHours(0, 0, 0, 0);
    startDate.setDate(startDate.getDate() - daysBack);

    const [orders, warehouses, productStocks] = await Promise.all([
      SalesOrder.findAll({
        where: { ...baseWhere, createdAt: { [Op.gte]: startDate } },
        attributes: ['id', 'status', 'totalAmount', 'createdAt'],
        raw: true,
      }),
      Warehouse.findAll({
        where: baseWhere,
        attributes: ['id', 'name'],
        raw: true,
      }),
      ProductStock.findAll({
        include: [{
          model: Warehouse,
          as: 'Warehouse',
          attributes: ['id', 'name'],
          required: true,
          ...(companyId ? { where: { companyId } } : {}),
        }, {
          model: Product,
          as: 'Product',
          attributes: ['id', 'name', 'sku'],
          required: true,
          ...(companyId ? { where: { companyId } } : {}),
        }],
        raw: true,
      }),
    ]);

    const whMap = {};
    (warehouses || []).forEach((w) => { whMap[w.id] = w.name; });

    const dateMap = {};
    (orders || []).forEach((o) => {
      const d = o.createdAt ? new Date(o.createdAt).toISOString().slice(0, 10) : null;
      if (!d) return;
      if (!dateMap[d]) dateMap[d] = { date: d, count: 0, totalAmount: 0 };
      dateMap[d].count += 1;
      dateMap[d].totalAmount += Number(o.totalAmount) || 0;
    });
    const ordersByDay = Object.values(dateMap).sort((a, b) => (a.date > b.date ? 1 : -1));

    const statusMap = {};
    (orders || []).forEach((o) => {
      const s = o.status || 'unknown';
      statusMap[s] = (statusMap[s] || 0) + 1;
    });
    const ordersByStatus = Object.entries(statusMap).map(([status, count]) => ({ status, count }));

    const whStock = {};
    (productStocks || []).forEach((ps) => {
      const name = ps['Warehouse.name'] || whMap[ps.warehouseId] || 'Unknown';
      whStock[name] = (whStock[name] || 0) + (Number(ps.quantity) || 0);
    });
    const stockByWarehouse = Object.entries(whStock).map(([warehouseName, quantity]) => ({ warehouseName, quantity }));

    const productStock = {};
    (productStocks || []).forEach((ps) => {
      const key = ps['Product.id'];
      if (!productStock[key]) productStock[key] = { productName: ps['Product.name'] || ps['Product.sku'] || 'Unknown', sku: ps['Product.sku'], quantity: 0 };
      productStock[key].quantity += Number(ps.quantity) || 0;
    });
    const topProducts = Object.values(productStock)
      .sort((a, b) => b.quantity - a.quantity)
      .slice(0, 10);

    res.json({
      success: true,
      data: {
        ordersByDay,
        ordersByStatus,
        stockByWarehouse,
        topProducts,
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/reports
 * Returns list of report entries for company (Operations, Orders, Inventory, Low Stock)
 */
async function reports(req, res, next) {
  try {
    const user = req.user;
    let companyId = user.companyId || null;
    if (user.role === 'super_admin' && req.query.companyId) {
      companyId = parseInt(req.query.companyId, 10);
    }
    const baseWhere = companyId ? { companyId } : {};

    const counts = await Promise.all([
      Warehouse.count({ where: baseWhere }),
      User.count({ where: { ...baseWhere, status: 'ACTIVE' } }),
      Product.count({ where: { ...baseWhere, status: 'ACTIVE' } }),
      Customer.count({ where: baseWhere }),
      SalesOrder.count({
        where: {
          ...baseWhere,
          status: { [Op.in]: ['pending', 'pick_list_created', 'picking', 'packing'] },
        },
      }),
      SalesOrder.count({ where: baseWhere }),
    ]);

    let totalStock = 0;
    let lowStockCount = 0;
    if (companyId) {
      const warehouses = await Warehouse.findAll({ where: { companyId }, attributes: ['id'] });
      const whIds = warehouses.map((w) => w.id);
      const result = await ProductStock.sum('quantity', { where: { warehouseId: { [Op.in]: whIds } } });
      totalStock = result || 0;
      const products = await Product.findAll({
        where: { ...baseWhere, status: 'ACTIVE' },
        attributes: ['id', 'reorderLevel'],
      });
      for (const p of products) {
        const sum = await ProductStock.sum('quantity', {
          where: { productId: p.id, warehouseId: { [Op.in]: whIds } },
        });
        if ((sum || 0) < (p.reorderLevel || 0)) lowStockCount += 1;
      }
    } else {
      const result = await ProductStock.sum('quantity');
      totalStock = result || 0;
    }

    const now = new Date().toISOString();
    const list = [
      {
        id: 'ops-summary',
        reportName: 'Operations Summary',
        name: 'Operations Summary',
        category: 'OPERATIONAL',
        schedule: 'LIVE',
        format: 'PDF',
        createdAt: now,
        metadata: {
          warehouses: counts[0],
          users: counts[1],
          products: counts[2],
          customers: counts[3],
          pendingOrders: counts[4],
          totalOrders: counts[5],
          totalStock,
          lowStockCount,
        },
      },
      {
        id: 'order-summary',
        reportName: 'Order Summary',
        name: 'Order Summary',
        category: 'ORDERS',
        schedule: 'LIVE',
        format: 'PDF',
        createdAt: now,
        metadata: { pendingOrders: counts[4], totalOrders: counts[5] },
      },
      {
        id: 'inventory-summary',
        reportName: 'Inventory Summary',
        name: 'Inventory Summary',
        category: 'INVENTORY',
        schedule: 'LIVE',
        format: 'PDF',
        createdAt: now,
        metadata: { products: counts[2], totalStock, lowStockCount },
      },
      {
        id: 'low-stock',
        reportName: 'Low Stock Alert',
        name: 'Low Stock Alert',
        category: 'INVENTORY',
        schedule: 'LIVE',
        format: 'PDF',
        createdAt: now,
        metadata: { lowStockCount },
      },
    ];

    res.json({ success: true, data: list });
  } catch (err) {
    next(err);
  }
}

module.exports = { stats, charts, reports };
