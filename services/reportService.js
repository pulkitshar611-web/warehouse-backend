const { Report } = require('../models');
const { Op } = require('sequelize');

async function list(reqUser, query = {}) {
  const where = {};
  if (reqUser.role !== 'super_admin') where.companyId = reqUser.companyId;
  else if (query.companyId) where.companyId = query.companyId;
  if (query.category) where.category = query.category;
  if (query.reportType) where.reportType = query.reportType;
  if (query.format) where.format = query.format;
  if (query.schedule) where.schedule = query.schedule;
  if (query.status) where.status = query.status;
  if (query.startDate || query.endDate) {
    where.lastRunAt = {};
    if (query.startDate) where.lastRunAt[Op.gte] = new Date(query.startDate);
    if (query.endDate) where.lastRunAt[Op.lte] = new Date(query.endDate + 'T23:59:59.999Z');
  }
  if (query.search) {
    where[Op.or] = [
      { reportName: { [Op.like]: `%${query.search}%` } },
      { category: { [Op.like]: `%${query.search}%` } },
    ];
  }

  const reports = await Report.findAll({
    where,
    order: [['createdAt', 'DESC']],
  });
  return reports.map((r) => r.get({ plain: true }));
}

async function getById(id, reqUser) {
  const report = await Report.findByPk(id);
  if (!report) throw new Error('Report not found');
  if (reqUser.role !== 'super_admin' && report.companyId !== reqUser.companyId) throw new Error('Report not found');
  return report.get({ plain: true });
}

async function update(id, data, reqUser) {
  const report = await Report.findByPk(id);
  if (!report) throw new Error('Report not found');
  if (reqUser.role !== 'super_admin' && report.companyId !== reqUser.companyId) throw new Error('Report not found');
  const updates = {};
  if (data.reportName != null) updates.reportName = data.reportName;
  if (data.reportType != null) updates.reportType = data.reportType;
  if (data.category != null) updates.category = data.category;
  if (data.startDate != null) updates.startDate = data.startDate;
  if (data.endDate != null) updates.endDate = data.endDate;
  if (data.format != null) updates.format = data.format;
  if (data.schedule != null) updates.schedule = data.schedule;
  if (data.status != null) updates.status = data.status;
  await report.update(updates);
  return report.get({ plain: true });
}

async function create(data, reqUser) {
  const companyId = reqUser.companyId;
  if (!companyId && reqUser.role !== 'super_admin') throw new Error('companyId required');

  const reportType = (data.reportType || data.category || 'INVENTORY').toUpperCase().replace(/\s+/g, '_');
  const validTypes = ['INVENTORY', 'ORDERS', 'FINANCIAL', 'PERFORMANCE'];
  const type = validTypes.includes(reportType) ? reportType : 'INVENTORY';

  const startDate = data.startDate ? (data.startDate.split('T')[0] || data.startDate) : null;
  const endDate = data.endDate ? (data.endDate.split('T')[0] || data.endDate) : null;

  const report = await Report.create({
    companyId: companyId || data.companyId,
    reportName: data.reportName || `Report ${type} ${new Date().toISOString().slice(0, 10)}`,
    reportType: type,
    category: type,
    startDate,
    endDate,
    format: (data.format || 'PDF').toUpperCase(),
    schedule: (data.schedule || 'ONCE').toUpperCase(),
    status: 'COMPLETED',
    lastRunAt: new Date(),
  });
  return report.get({ plain: true });
}

async function remove(id, reqUser) {
  const report = await Report.findByPk(id);
  if (!report) throw new Error('Report not found');
  if (reqUser.role !== 'super_admin' && report.companyId !== reqUser.companyId) throw new Error('Report not found');
  await report.destroy();
  return { message: 'Report deleted' };
}

module.exports = { list, getById, create, update, remove };
