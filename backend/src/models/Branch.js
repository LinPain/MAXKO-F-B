const mongoose = require('mongoose');

const branchSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true, index: true },
  code: { type: String, default: '' },
  name: { type: String, required: true, trim: true },
  address: { type: String, default: '' },
  phone: { type: String, default: '' },
  hubType: { type: String, default: 'STANDALONE' },
  latitude: { type: Number, required: true, min: -90, max: 90 },
  longitude: { type: Number, required: true, min: -180, max: 180 },
  allowedGpsRadiusMeters: { type: Number, default: 150 },
  isOpen: { type: Boolean, default: true },
  isActive: { type: Boolean, default: true },
  openTime: { type: String, default: '08:00' },
  closeTime: { type: String, default: '22:00' },
  brandIds: { type: [String], default: ['brand-legia'] },
}, { timestamps: true });

module.exports = mongoose.model('Branch', branchSchema);
