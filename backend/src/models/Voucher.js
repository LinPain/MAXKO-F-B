const mongoose = require('mongoose');

const voucherSchema = new mongoose.Schema({
  code: { type: String, unique: true, uppercase: true, trim: true },
  title: String,
  discountPercent: { type: Number, default: 0 },
  discountAmount: { type: Number, default: 0 },
  maxDiscount: { type: Number, default: 0 },
  minOrderTotal: { type: Number, default: 0 },
  pointsCost: { type: Number, default: 0, min: 0 },
  ownerCustomer: { type: mongoose.Schema.Types.ObjectId, ref: 'Customer', default: null, index: true },
  source: { type: String, default: 'CAMPAIGN' },
  usedAt: { type: Date, default: null },
  brandIds: { type: [String], default: [] },
  branchIds: { type: [String], default: [] },
  startDate: Date,
  endDate: Date,
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('Voucher', voucherSchema);
