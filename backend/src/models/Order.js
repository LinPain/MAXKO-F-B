const mongoose = require('mongoose');
const crypto = require('crypto');

const orderSchema = new mongoose.Schema({
  orderNumber: { type: String, unique: true },
  batchId: { type: String, default: '', index: true },
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'Customer', default: null },
  branchId: { type: String, default: '' },
  branchName: { type: String, default: '' },
  brandId: { type: String, default: 'brand-legia', index: true },
  deliveryCoordinates: { type: mongoose.Schema.Types.Mixed, default: null },
  orderType: { type: String, default: 'TAKEAWAY' },
  source: { type: String, default: 'APP' },
  customerName: String,
  customerPhone: String,
  deliveryAddress: String,
  note: String,
  items: [mongoose.Schema.Types.Mixed],
  subtotal: { type: Number, required: true },
  discount: { type: Number, default: 0 },
  shippingFee: { type: Number, default: 0 },
  finalTotal: { type: Number, required: true },
  paymentMethod: { type: String, default: 'CASH' },
  paymentStatus: { type: String, default: 'UNPAID' },
  status: { type: String, default: 'PENDING' },
  statusTimeline: [{ status: String, time: Date }],
  voucherCode: String,
  needCorporateInvoice: { type: Boolean, default: false },
  corporateInvoiceInfo: mongoose.Schema.Types.Mixed,
  paymentTransactionId: String,
}, { timestamps: true });

orderSchema.pre('validate', function(next) {
  if (!this.orderNumber) this.orderNumber = `MK-${Date.now().toString(36).toUpperCase()}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
  next();
});

module.exports = mongoose.model('Order', orderSchema);
