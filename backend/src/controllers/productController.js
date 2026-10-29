const mongoose = require('mongoose');
const Product = require('../models/Product');
const Branch = require('../models/Branch');
const ModifierGroup = require('../models/ModifierGroup');

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const getProducts = async (req, res) => {
  try {
    const filter = { isAvailable: true };
    if (req.query.availableOnly === 'false') delete filter.isAvailable;
    if (req.query.brandId) {
      filter.brandId = String(req.query.brandId) === 'brand-legia'
        ? { $in: ['brand-legia', null] }
        : String(req.query.brandId);
    }
    if (req.query.branchId) {
      const branch = await Branch.findOne({ id: String(req.query.branchId), isActive: true }).lean();
      if (!branch) return res.status(404).json({ success: false, error: 'Không tìm thấy cơ sở.', code: 'BRANCH_NOT_FOUND' });
      if (!branch.isOpen) return res.json({ success: true, data: [] });
      filter[`branchAvailability.${String(req.query.branchId)}`] = { $ne: false };
    }
    if (req.query.category && req.query.category !== 'all') filter.category = req.query.category;
    if (req.query.categoryId && req.query.categoryId !== 'all') {
      const categories = (await Product.distinct('category', { ...filter, category: { $exists: true } })).sort();
      const category = categories.find((name, index) => `cat-${index + 1}` === req.query.categoryId || name === req.query.categoryId);
      if (!category) return res.json({ success: true, data: [] });
      filter.category = category;
    }
    if (req.query.search) filter.name = { $regex: escapeRegex(String(req.query.search).trim()), $options: 'i' };
    const products = await Product.find(filter).sort({ createdAt: -1 }).lean();
    const groupIds = [...new Set(products.flatMap((product) => product.modifierGroupIds || []))];
    const groups = groupIds.length ? await ModifierGroup.find({ id: { $in: groupIds }, isActive: true }).lean() : [];
    const groupById = new Map(groups.map((group) => [group.id, group]));
    const data = products.map((product) => ({
      ...product,
      id: String(product.id || product._id),
      basePrice: product.basePrice ?? product.price,
      effectivePrice: product.branchPriceOverrides instanceof Map
        ? product.branchPriceOverrides.get(String(req.query.branchId || '')) ?? product.basePrice ?? product.price
        : product.branchPriceOverrides?.[String(req.query.branchId || '')] ?? product.basePrice ?? product.price,
      branchId: req.query.branchId || '',
      modifierGroups: (product.modifierGroupIds || []).map((id) => groupById.get(id)).filter(Boolean),
      branchAvailability: product.branchAvailability instanceof Map
        ? Object.fromEntries(product.branchAvailability)
        : product.branchAvailability || {},
    }));

    res.json({
      success: true,
      data,
    });
  } catch (error) {
    const status = error.name === 'CastError' ? 400 : 500;
    res.status(status).json({
      success: false,
      error: status === 500 && process.env.NODE_ENV === 'production' ? 'Lỗi máy chủ.' : error.message,
      code: status === 400 ? 'INVALID_QUERY' : 'INTERNAL_ERROR',
    });
  }
};

const getProductById = async (req, res) => {
  try {
    const product = mongoose.isValidObjectId(req.params.id)
      ? await Product.findOne({ $or: [{ _id: req.params.id }, { id: req.params.id }] }).lean()
      : await Product.findOne({ id: req.params.id }).lean();

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    const groups = product.modifierGroupIds?.length
      ? await ModifierGroup.find({ id: { $in: product.modifierGroupIds }, isActive: true }).lean()
      : [];
    const branchId = String(req.query.branchId || '');
    const branchOverride = product.branchPriceOverrides instanceof Map
      ? product.branchPriceOverrides.get(branchId)
      : product.branchPriceOverrides?.[branchId];
    res.json({
      success: true,
      data: {
        ...product,
        id: String(product.id || product._id),
        basePrice: product.basePrice ?? product.price,
        effectivePrice: branchOverride ?? product.basePrice ?? product.price,
        branchId,
        modifierGroups: groups,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get product',
      error: error.message,
    });
  }
};

module.exports = {
  getProducts,
  getProductById,
};
