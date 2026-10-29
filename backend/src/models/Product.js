const mongoose = require('mongoose');

const productOptionSchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, sparse: true, trim: true },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    extraPrice: {
      type: Number,
      default: 0,
      min: 0,
    },
    isDefault: { type: Boolean, default: false },
  },
  { _id: false },
);

const productSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
      default: '',
    },

    price: {
      type: Number,
      required: true,
      min: 0,
    },

    imageUrl: {
      type: String,
      default: '',
    },

    category: {
      type: String,
      required: true,
      trim: true,
    },

    brandId: { type: String, default: 'brand-legia', index: true },
    categoryId: { type: String, default: '' },
    basePrice: { type: Number, min: 0 },
    branchPriceOverrides: { type: Map, of: Number, default: {} },
    modifierGroupIds: { type: [String], default: [] },
    branchAvailability: {
      type: Map,
      of: Boolean,
      default: {},
    },

    isAvailable: {
      type: Boolean,
      default: true,
    },

    sizes: {
      type: [productOptionSchema],
      default: [],
    },

    sugarLevels: {
      type: [productOptionSchema],
      default: [],
    },

    iceLevels: {
      type: [productOptionSchema],
      default: [],
    },

    toppings: {
      type: [productOptionSchema],
      default: [],
    },
  },
  {
    timestamps: true,
  },
);

module.exports = mongoose.model('Product', productSchema);
