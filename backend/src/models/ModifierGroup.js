const mongoose = require('mongoose');

const optionSchema = new mongoose.Schema({
  id: { type: String, required: true },
  code: { type: String, default: '' },
  name: { type: String, required: true, trim: true },
  priceAdjustment: { type: Number, default: 0, min: 0 },
  isDefault: { type: Boolean, default: false },
  isAvailable: { type: Boolean, default: true },
}, { _id: false });

const modifierGroupSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true, index: true },
  brandId: { type: String, required: true, index: true },
  productIds: { type: [String], default: [] },
  code: { type: String, required: true },
  name: { type: String, required: true, trim: true },
  selectionType: { type: String, enum: ['SINGLE', 'MULTIPLE'], default: 'SINGLE' },
  minSelections: { type: Number, default: 0, min: 0 },
  maxSelections: { type: Number, default: 1, min: 1 },
  isActive: { type: Boolean, default: true },
  options: { type: [optionSchema], default: [] },
}, { timestamps: true });

modifierGroupSchema.index({ brandId: 1, code: 1 }, { unique: true });

module.exports = mongoose.model('ModifierGroup', modifierGroupSchema);
