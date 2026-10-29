const express = require('express');
const Branch = require('../models/Branch');
const Product = require('../models/Product');
const ModifierGroup = require('../models/ModifierGroup');

const router = express.Router();
const success = (res, data) => res.json({ success: true, data });

function formatBranch(branch) {
  return { ...branch, gps: { latitude: branch.latitude, longitude: branch.longitude } };
}

function distanceKm(lat1, lng1, lat2, lng2) {
  const radians = (value) => value * Math.PI / 180;
  const dLat = radians(lat2 - lat1);
  const dLng = radians(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(radians(lat1)) * Math.cos(radians(lat2)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

router.get('/branches', async (req, res, next) => {
  try {
    const filter = { isActive: true };
    if (req.query.activeOnly !== 'false') filter.isOpen = true;
    const branches = await Branch.find(filter).sort({ name: 1 }).lean();
    success(res, branches.map(formatBranch));
  } catch (error) { next(error); }
});

router.get('/branches/:id', async (req, res, next) => {
  try {
    const branch = await Branch.findOne({ id: req.params.id, isActive: true }).lean();
    if (!branch) return res.status(404).json({ success: false, error: 'Không tìm thấy cơ sở.', code: 'BRANCH_NOT_FOUND' });
    success(res, formatBranch(branch));
  } catch (error) { next(error); }
});

router.get('/branches/:id/menu-matrix', async (req, res, next) => {
  try {
    const branch = await Branch.findOne({ id: req.params.id, isActive: true }).lean();
    if (!branch) return res.status(404).json({ success: false, error: 'Không tìm thấy cơ sở.', code: 'BRANCH_NOT_FOUND' });
    if (!branch.isOpen) return success(res, { branchId: branch.id, branchName: branch.name, isOpen: false, categories: [], products: [] });
    const filter = { isAvailable: true, [`branchAvailability.${branch.id}`]: { $ne: false } };
    if (req.query.brandId) filter.brandId = String(req.query.brandId);
    const products = await Product.find(filter).sort({ category: 1, name: 1 }).lean();
    const modifierIds = [...new Set(products.flatMap((product) => product.modifierGroupIds || []))];
    const modifierGroups = modifierIds.length
      ? await ModifierGroup.find({ id: { $in: modifierIds }, isActive: true }).lean()
      : [];
    const groupsById = new Map(modifierGroups.map((group) => [group.id, group]));
    const items = products.map((product) => ({
      ...product,
      id: String(product.id || product._id),
      basePrice: product.basePrice ?? product.price,
      effectivePrice: product.branchPriceOverrides instanceof Map
        ? product.branchPriceOverrides.get(branch.id) ?? product.basePrice ?? product.price
        : product.branchPriceOverrides?.[branch.id] ?? product.basePrice ?? product.price,
      branchId: branch.id,
      modifierGroups: (product.modifierGroupIds || []).map((id) => groupsById.get(id)).filter(Boolean),
    }));
    success(res, {
      branchId: branch.id,
      branchName: branch.name,
      isOpen: true,
      categories: [...new Set(items.map((item) => item.category))].map((name) => ({ id: name, name })),
      products: items,
    });
  } catch (error) { next(error); }
});

router.get('/geofence/config', (_req, res) => success(res, {
  maxDeliveryDistanceKm: Number(process.env.MAX_DELIVERY_DISTANCE_KM || 4),
  maxTakeawayDistanceMeters: Number(process.env.MAX_TAKEAWAY_DISTANCE_METERS || 600),
  outOfRangeMessage: 'Địa chỉ nằm ngoài khu vực phục vụ.',
}));

router.post('/geofence/find-nearest-branches', async (req, res, next) => {
  try {
    const lat = Number(req.body.customerLat ?? req.body.latitude);
    const lng = Number(req.body.customerLng ?? req.body.longitude);
    if (!Number.isFinite(lat) || lat < -90 || lat > 90 || !Number.isFinite(lng) || lng < -180 || lng > 180) {
      return res.status(400).json({ success: false, error: 'Tọa độ khách hàng chưa hợp lệ.', code: 'INVALID_COORDINATES' });
    }
    const filter = { isActive: true, isOpen: true };
    if (req.body.brandId) filter.brandIds = String(req.body.brandId);
    const branches = await Branch.find(filter).lean();
    if (!branches.length) return res.status(503).json({ success: false, error: 'Chưa cấu hình cơ sở phục vụ thương hiệu này.', code: 'BRANCHES_NOT_CONFIGURED' });
    const nearestBranches = branches.map((branch) => ({
      ...formatBranch(branch),
      distanceKm: Number(distanceKm(lat, lng, branch.latitude, branch.longitude).toFixed(2)),
    })).sort((a, b) => a.distanceKm - b.distanceKm);
    success(res, { nearestBranch: nearestBranches[0], branches: nearestBranches, maxDeliveryDistanceKm: Number(process.env.MAX_DELIVERY_DISTANCE_KM || 4) });
  } catch (error) { next(error); }
});

router.post('/geofence/proximity-alert', async (req, res, next) => {
  try {
    const lat = Number(req.body.latitude ?? req.body.customerLat);
    const lng = Number(req.body.longitude ?? req.body.customerLng);
    if (!Number.isFinite(lat) || lat < -90 || lat > 90 || !Number.isFinite(lng) || lng < -180 || lng > 180) {
      return res.status(400).json({ success: false, error: 'Tọa độ khách hàng chưa hợp lệ.', code: 'INVALID_COORDINATES' });
    }
    const branches = await Branch.find({ isActive: true, isOpen: true }).lean();
    if (!branches.length) return res.status(503).json({ success: false, error: 'Chưa cấu hình cơ sở đang hoạt động.', code: 'BRANCHES_NOT_CONFIGURED' });
    const nearest = branches.map((branch) => ({
      branch: formatBranch(branch),
      distanceMeters: Math.round(distanceKm(lat, lng, branch.latitude, branch.longitude) * 1000),
    })).sort((a, b) => a.distanceMeters - b.distanceMeters)[0];
    const defaultRadius = Number(process.env.MAX_TAKEAWAY_DISTANCE_METERS || 600);
    const radiusMeters = Math.max(0, Number(nearest.branch.allowedGpsRadiusMeters || defaultRadius));
    const alertTriggered = nearest.distanceMeters <= radiusMeters;
    success(res, {
      alertTriggered,
      nearestBranch: nearest.branch,
      distanceMeters: nearest.distanceMeters,
      radiusMeters,
      message: alertTriggered ? 'Bạn đang ở gần cơ sở MAXKO.' : 'Chưa có cơ sở trong vùng lân cận.',
    });
  } catch (error) { next(error); }
});

router.post('/geofence/validate-distance', (req, res) => {
  const values = ['branchLat', 'branchLng', 'customerLat', 'customerLng'].map((key) => Number(req.body[key]));
  const [branchLat, branchLng, customerLat, customerLng] = values;
  if (!values.every(Number.isFinite) || branchLat < -90 || branchLat > 90 || customerLat < -90 || customerLat > 90 || branchLng < -180 || branchLng > 180 || customerLng < -180 || customerLng > 180) {
    return res.status(400).json({ success: false, error: 'Tọa độ chưa hợp lệ.', code: 'INVALID_COORDINATES' });
  }
  const distance = distanceKm(branchLat, branchLng, customerLat, customerLng);
  const maxDistance = Number(process.env.MAX_DELIVERY_DISTANCE_KM || 4);
  const isValid = String(req.body.orderType || 'DELIVERY').toUpperCase() !== 'DELIVERY' || distance <= maxDistance;
  success(res, {
    isValid,
    distanceKm: Number(distance.toFixed(2)),
    distanceMeters: Math.round(distance * 1000),
    maxDistanceKm: maxDistance,
    maxAllowedDistance: `${maxDistance} km`,
    message: isValid ? 'Địa chỉ nằm trong khu vực phục vụ.' : `Khoảng cách vượt quá bán kính giao hàng ${maxDistance} km.`,
  });
});

module.exports = router;
