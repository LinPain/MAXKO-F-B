const mongoose = require('mongoose');

const promotionSchema = new mongoose.Schema({
  code: { type: String, uppercase: true, trim: true },
  title: { type: String, required: true, trim: true },
  description: { type: String, default: '' },
  type: { type: String, enum: ['PERCENT', 'FIXED'], required: true },
  value: { type: Number, required: true, min: 0 },
  maxDiscount: { type: Number, default: 0 },
  minOrderTotal: { type: Number, default: 0 },
  startDate: Date,
  endDate: Date,
  brandIds: { type: [String], default: [] },
  branchIds: { type: [String], default: [] },
  productIds: { type: [String], default: [] },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

promotionSchema.index({ code: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('Promotion', promotionSchema);
