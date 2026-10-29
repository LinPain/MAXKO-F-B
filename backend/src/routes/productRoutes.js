const express = require('express');

const {
  getProducts,
  getProductById,
} = require('../controllers/productController');

const router = express.Router();

router.get('/', getProducts);
router.get('/price-overrides', async (req, res, next) => {
  try {
    const filter = { isAvailable: true };
    if (req.query.brandId) filter.brandId = String(req.query.brandId);
    if (req.query.branchId) filter[`branchPriceOverrides.${String(req.query.branchId)}`] = { $exists: true };
    const products = await require('../models/Product').find(filter).lean();
    const overrides = products.flatMap((product) => {
      const entries = product.branchPriceOverrides instanceof Map
        ? [...product.branchPriceOverrides.entries()]
        : Object.entries(product.branchPriceOverrides || {});
      return entries
        .filter(([branchId, price]) => Number.isFinite(Number(price)) && (!req.query.branchId || branchId === String(req.query.branchId)))
        .map(([branchId, price]) => ({
          productId: String(product.id || product._id),
          productName: product.name,
          brandId: product.brandId || 'brand-legia',
          branchId,
          price: Number(price),
          basePrice: Number(product.basePrice ?? product.price),
        }));
    });
    res.json({ success: true, data: overrides });
  } catch (error) { next(error); }
});
router.get('/:id', getProductById);

module.exports = router;
