const { ReplenishmentConfig, Product, Company, ProductStock } = require('../models');
const { Op } = require('sequelize');

async function list(reqUser, query = {}) {
  const where = {};
  if (reqUser.role !== 'super_admin') where.companyId = reqUser.companyId;
  else if (query.companyId) where.companyId = query.companyId;
  if (query.status) where.status = query.status;

  const configs = await ReplenishmentConfig.findAll({
    where,
    order: [['createdAt', 'DESC']],
    include: [{ association: 'Product', attributes: ['id', 'name', 'sku'] }],
  });
  return configs.map((c) => c.get({ plain: true }));
}

async function getById(id, reqUser) {
  const config = await ReplenishmentConfig.findByPk(id, {
    include: [{ association: 'Product' }],
  });
  if (!config) throw new Error('Replenishment config not found');
  if (reqUser.role !== 'super_admin' && config.companyId !== reqUser.companyId) throw new Error('Replenishment config not found');
  return config.get({ plain: true });
}

async function create(data, reqUser) {
  const companyId = reqUser.companyId || data.companyId;
  if (!companyId) throw new Error('companyId required');

  const config = await ReplenishmentConfig.create({
    companyId,
    productId: data.productId,
    minStockLevel: Number(data.minStockLevel) || 0,
    maxStockLevel: Number(data.maxStockLevel) || 0,
    reorderPoint: Number(data.reorderPoint) || 0,
    reorderQuantity: Number(data.reorderQuantity) || 0,
    autoCreateTasks: data.autoCreateTasks !== false,
    status: data.status || 'ACTIVE',
  });
  return getById(config.id, reqUser);
}

async function update(id, data, reqUser) {
  const config = await ReplenishmentConfig.findByPk(id);
  if (!config) throw new Error('Replenishment config not found');
  if (reqUser.role !== 'super_admin' && config.companyId !== reqUser.companyId) throw new Error('Replenishment config not found');

  const updates = {};
  if (data.productId != null) updates.productId = data.productId;
  if (data.minStockLevel != null) updates.minStockLevel = Number(data.minStockLevel);
  if (data.maxStockLevel != null) updates.maxStockLevel = Number(data.maxStockLevel);
  if (data.reorderPoint != null) updates.reorderPoint = Number(data.reorderPoint);
  if (data.reorderQuantity != null) updates.reorderQuantity = Number(data.reorderQuantity);
  if (data.autoCreateTasks !== undefined) updates.autoCreateTasks = !!data.autoCreateTasks;
  if (data.status != null) updates.status = data.status;
  await config.update(updates);
  return getById(id, reqUser);
}

async function remove(id, reqUser) {
  const config = await ReplenishmentConfig.findByPk(id);
  if (!config) throw new Error('Replenishment config not found');
  if (reqUser.role !== 'super_admin' && config.companyId !== reqUser.companyId) throw new Error('Replenishment config not found');
  await config.destroy();
  return { message: 'Replenishment config deleted' };
}

/** Run auto-check: products below reorder point (Settings → flow → create Tasks) */
async function runAutoCheck(reqUser) {
  const where = { status: 'ACTIVE', autoCreateTasks: true };
  if (reqUser.role !== 'super_admin') where.companyId = reqUser.companyId;

  const configs = await ReplenishmentConfig.findAll({
    where,
    include: [{ association: 'Product', attributes: ['id', 'name', 'sku'] }],
  });

  const productWhere = { productId: { [Op.in]: configs.map((c) => c.productId) } };
  const stocks = await ProductStock.findAll({
    where: productWhere,
    attributes: ['productId', 'quantity', 'reserved'],
  });

  const stockByProduct = {};
  for (const s of stocks) {
    const pid = s.productId;
    if (!stockByProduct[pid]) stockByProduct[pid] = { quantity: 0, reserved: 0 };
    stockByProduct[pid].quantity += Number(s.quantity) || 0;
    stockByProduct[pid].reserved += Number(s.reserved) || 0;
  }

  const suggestions = [];
  for (const c of configs) {
    const total = (stockByProduct[c.productId]?.quantity ?? 0) - (stockByProduct[c.productId]?.reserved ?? 0);
    const reorderPoint = Number(c.reorderPoint) || 0;
    if (reorderPoint > 0 && total < reorderPoint) {
      suggestions.push({
        configId: c.id,
        productId: c.productId,
        productName: c.Product?.name,
        productSku: c.Product?.sku,
        currentStock: total,
        reorderPoint,
        reorderQuantity: Number(c.reorderQuantity) || 0,
      });
    }
  }
  return { suggestions };
}

module.exports = { list, getById, create, update, remove, runAutoCheck };
