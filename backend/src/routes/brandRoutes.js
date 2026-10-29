const express = require('express');
const mongoose = require('mongoose');
const Brand = require('../models/Brand');

const router = express.Router();

router.get('/brands/:id', async (req, res, next) => {
  try {
    const query = mongoose.isValidObjectId(req.params.id)
      ? { $or: [{ _id: req.params.id }, { id: req.params.id }], isActive: true }
      : { id: req.params.id, isActive: true };
    const brand = await Brand.findOne(query).lean();
    if (!brand) return res.status(404).json({ success: false, error: 'Không tìm thấy thương hiệu.', code: 'BRAND_NOT_FOUND' });
    res.json({ success: true, data: { ...brand, id: brand.id || String(brand._id) } });
  } catch (error) { next(error); }
});

module.exports = router;
