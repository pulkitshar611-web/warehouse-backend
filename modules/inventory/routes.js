const express = require('express');
const router = express.Router();
const inventoryController = require('../../controllers/inventoryController');
const { authenticate, requireRole } = require('../../middlewares/auth');

router.use(authenticate);

router.get('/products', requireRole('super_admin', 'company_admin', 'inventory_manager', 'viewer'), inventoryController.listProducts);
router.get('/products/:id', requireRole('super_admin', 'company_admin', 'inventory_manager', 'viewer'), inventoryController.getProduct);
router.post('/products', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.createProduct);
router.post('/products/bulk', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.bulkCreateProducts);
router.post('/products/:id/alternative-skus', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.addAlternativeSku);
router.put('/products/:id', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.updateProduct);
router.delete('/products/:id', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.removeProduct);

router.get('/categories', requireRole('super_admin', 'company_admin', 'inventory_manager', 'viewer'), inventoryController.listCategories);
router.post('/categories', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.createCategory);
router.put('/categories/:id', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.updateCategory);
router.delete('/categories/:id', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.removeCategory);

router.get('/stock', requireRole('super_admin', 'company_admin', 'inventory_manager', 'viewer'), inventoryController.listStock);
router.get('/stock/by-best-before-date', requireRole('super_admin', 'company_admin', 'inventory_manager', 'viewer'), inventoryController.listStockByBestBeforeDate);
router.get('/stock/by-location', requireRole('super_admin', 'company_admin', 'inventory_manager', 'viewer'), inventoryController.listStockByLocation);
router.post('/stock', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.createStock);
router.put('/stock/:id', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.updateStock);
router.delete('/stock/:id', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.removeStock);

router.get('/adjustments', requireRole('super_admin', 'company_admin', 'inventory_manager', 'viewer'), inventoryController.listAdjustments);
router.post('/adjustments', requireRole('super_admin', 'company_admin', 'inventory_manager'), inventoryController.createAdjustment);

router.get('/cycle-counts', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager', 'viewer'), inventoryController.listCycleCounts);
router.post('/cycle-counts', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager'), inventoryController.createCycleCount);

router.get('/batches', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager', 'viewer'), inventoryController.listBatches);
router.get('/batches/:id', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager', 'viewer'), inventoryController.getBatch);
router.post('/batches', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager'), inventoryController.createBatch);
router.put('/batches/:id', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager'), inventoryController.updateBatch);
router.delete('/batches/:id', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager'), inventoryController.removeBatch);

router.get('/movements', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager', 'viewer'), inventoryController.listMovements);
router.get('/movements/:id', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager', 'viewer'), inventoryController.getMovement);
router.post('/movements', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager'), inventoryController.createMovement);
router.put('/movements/:id', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager'), inventoryController.updateMovement);
router.delete('/movements/:id', requireRole('super_admin', 'company_admin', 'warehouse_manager', 'inventory_manager'), inventoryController.removeMovement);

module.exports = router;
