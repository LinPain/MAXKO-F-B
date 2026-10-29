import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../cart/controllers/cart_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/providers/api_client.dart';

class CheckoutController extends GetxController {
  final CartController cartController;
  final ApiClient apiProvider;

  CheckoutController({required this.cartController, required this.apiProvider});

  final selectedOrderType = ''.obs;

  final voucherController = TextEditingController();
  final noteController = TextEditingController();
  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final deliveryAddressController = TextEditingController();

  final isApplyingVoucher = false.obs;

  final appliedVoucher = ''.obs;
  final discountAmount = 0.0.obs;
  final savedAddresses = <Map<String, dynamic>>[].obs;
  final isSavingAddress = false.obs;
  final isLocatingDelivery = false.obs;
  final deliveryLocationStatus = ''.obs;
  final nearestBranchName = ''.obs;
  final deliveryCoordinates = Rxn<Map<String, double>>();
  final deliveryBranchIdsByBrand = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedAddresses();
  }

  Future<void> loadSavedAddresses() async {
    if (!await apiProvider.hasAccessToken()) return;
    try {
      final response = await apiProvider.get('/api/customers/me/addresses');
      savedAddresses.assignAll(response is List ? response.whereType<Map>().map((item) => Map<String, dynamic>.from(item)) : const <Map<String, dynamic>>[]);
    } catch (_) { savedAddresses.clear(); }
  }

  Future<void> requestDeliveryLocation() async {
    if (isLocatingDelivery.value) return;
    if (deliveryAddressController.text.trim().isEmpty) {
      Get.snackbar(
        'Nhập địa chỉ giao hàng',
        'Nhập địa chỉ trước khi xác định khu vực giao hàng.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isLocatingDelivery.value = true;
    deliveryLocationStatus.value = 'Đang xin quyền truy cập vị trí...';
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        deliveryLocationStatus.value = 'Dịch vụ vị trí đang tắt.';
        Get.snackbar(
          'Cần bật vị trí',
          'Bật Location Services để tìm cơ sở giao hàng gần nhất.',
          snackPosition: SnackPosition.BOTTOM,
          mainButton: TextButton(
            onPressed: Geolocator.openLocationSettings,
            child: const Text('Cài đặt'),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        deliveryLocationStatus.value = 'Quyền vị trí bị từ chối trong cài đặt.';
        Get.snackbar(
          'Cần cấp quyền vị trí',
          'Cho phép MAXKO truy cập vị trí khi dùng ứng dụng để giao hàng.',
          snackPosition: SnackPosition.BOTTOM,
          mainButton: TextButton(
            onPressed: Geolocator.openAppSettings,
            child: const Text('Cài đặt'),
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        deliveryLocationStatus.value = 'Chưa được cấp quyền vị trí.';
        Get.snackbar(
          'Chưa có quyền vị trí',
          'Cần quyền vị trí để kiểm tra khu vực giao hàng.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      deliveryLocationStatus.value = 'Đang lấy vị trí hiện tại...';
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final coordinates = <String, double>{
        'lat': position.latitude,
        'lng': position.longitude,
      };
      final brands = cartController.cartItems
          .map((item) => item.brandId)
          .where((brandId) => brandId.isNotEmpty)
          .toSet();
      if (brands.isEmpty) brands.add('brand-legia');

      final branchIds = <String, String>{};
      final names = <String>[];
      for (final brandId in brands) {
        final nearest = await apiProvider.post(
          '/api/geofence/find-nearest-branches',
          body: {
            'customerLat': coordinates['lat'],
            'customerLng': coordinates['lng'],
            'brandId': brandId,
          },
        );
        final branch = _nearestBranch(nearest);
        if (branch == null) {
          throw Exception('Không tìm thấy cơ sở phục vụ thương hiệu $brandId.');
        }
        final branchId =
            (branch['id'] ?? branch['_id'] ?? branch['branchId'])?.toString() ??
            '';
        if (branchId.isEmpty) {
          throw Exception('Dữ liệu cơ sở gần nhất không có mã cơ sở.');
        }
        var selectedBranch = branch;
        var branchCoordinates = _branchCoordinates(selectedBranch);
        if (branchCoordinates == null) {
          final branchResponse = await apiProvider.get(
            '/api/branches/$branchId',
          );
          selectedBranch = _nearestBranch(branchResponse) ?? selectedBranch;
          branchCoordinates = _branchCoordinates(selectedBranch);
        }
        if (branchCoordinates == null) {
          throw Exception('Máy chủ không trả vị trí của cơ sở gần nhất.');
        }
        final validation = await apiProvider.post(
          '/api/geofence/validate-distance',
          body: {
            'branchLat': branchCoordinates['lat'],
            'branchLng': branchCoordinates['lng'],
            'customerLat': coordinates['lat'],
            'customerLng': coordinates['lng'],
            'orderType': 'DELIVERY',
          },
        );
        final validationMap = _asMap(validation);
        if (_isDistanceRejected(validationMap)) {
          throw Exception(
            validationMap?['message']?.toString() ??
                validationMap?['reason']?.toString() ??
                'Địa chỉ nằm ngoài khu vực giao hàng.',
          );
        }
        branchIds[brandId] = branchId;
        final branchName = selectedBranch['name']?.toString();
        if (branchName != null && branchName.isNotEmpty) names.add(branchName);
      }

      deliveryCoordinates.value = coordinates;
      deliveryBranchIdsByBrand.assignAll(branchIds);
      nearestBranchName.value = names.join(', ');
      deliveryLocationStatus.value = nearestBranchName.value.isEmpty
          ? 'Đã kiểm tra vị trí giao hàng.'
          : 'Cơ sở gần nhất: ${nearestBranchName.value}';
    } catch (error) {
      deliveryCoordinates.value = null;
      deliveryBranchIdsByBrand.clear();
      nearestBranchName.value = '';
      deliveryLocationStatus.value = error.toString().replaceFirst(
        'Exception: ',
        '',
      );
      Get.snackbar(
        'Không thể xác nhận khu vực giao hàng',
        deliveryLocationStatus.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLocatingDelivery.value = false;
    }
  }

  void onDeliveryAddressChanged() {
    deliveryCoordinates.value = null;
    deliveryBranchIdsByBrand.clear();
    nearestBranchName.value = '';
    deliveryLocationStatus.value = 'Địa chỉ đã đổi. Hãy kiểm tra lại vị trí.';
  }

  Map<String, dynamic>? _nearestBranch(dynamic response) {
    if (response is List) {
      for (final item in response) {
        final branch = _nearestBranch(item);
        if (branch != null) return branch;
      }
      return null;
    }
    final map = _asMap(response);
    if (map == null) return null;
    for (final key in const [
      'nearestBranch',
      'nearest',
      'branch',
      'closestBranch',
    ]) {
      final branch = _nearestBranch(map[key]);
      if (branch != null) return branch;
    }
    for (final key in const [
      'branches',
      'nearestBranches',
      'results',
      'items',
    ]) {
      if (map[key] is List) return _nearestBranch(map[key]);
    }
    if (map.containsKey('id') ||
        map.containsKey('_id') ||
        map.containsKey('branchId')) {
      return map;
    }
    if (map['data'] != null) return _nearestBranch(map['data']);
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  Map<String, double>? _branchCoordinates(Map<String, dynamic> branch) {
    final location = _asMap(branch['location']);
    final rawCoordinates = location?['coordinates'] ?? branch['coordinates'];
    final coordinateMap = _asMap(rawCoordinates);
    final coordinates = rawCoordinates;
    final lat =
        branch['latitude'] ??
        branch['lat'] ??
        location?['latitude'] ??
        location?['lat'];
    final lng =
        branch['longitude'] ??
        branch['lng'] ??
        location?['longitude'] ??
        location?['lng'];
    final coordinateLat =
        lat ?? coordinateMap?['latitude'] ?? coordinateMap?['lat'];
    final coordinateLng =
        lng ?? coordinateMap?['longitude'] ?? coordinateMap?['lng'];
    if (coordinateLat is num && coordinateLng is num) {
      return {'lat': coordinateLat.toDouble(), 'lng': coordinateLng.toDouble()};
    }
    if (coordinates is List &&
        coordinates.length >= 2 &&
        coordinates[0] is num &&
        coordinates[1] is num) {
      return {
        'lat': (coordinates[1] as num).toDouble(),
        'lng': (coordinates[0] as num).toDouble(),
      };
    }
    return null;
  }

  bool _isDistanceRejected(Map<String, dynamic>? response) {
    if (response == null) return false;
    for (final key in const [
      'isValid',
      'valid',
      'allowed',
      'withinRange',
      'isWithinRange',
      'isWithinDeliveryRange',
      'isDeliveryAvailable',
      'eligible',
    ]) {
      if (response[key] == false) return true;
    }
    final status = response['status']?.toString().toUpperCase();
    return status == 'REJECTED' || status == 'OUT_OF_RANGE';
  }

  Future<void> saveDeliveryAddress() async {
    final address = deliveryAddressController.text.trim();
    if (address.isEmpty || isSavingAddress.value) return;
    isSavingAddress.value = true;
    try {
      if (savedAddresses.any(
        (item) =>
            item['address']?.toString().toLowerCase() == address.toLowerCase(),
      )) {
        Get.snackbar(
          'Địa chỉ đã lưu',
          'Địa chỉ này đã có trong danh sách.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      if (savedAddresses.length >= 10) {
        Get.snackbar(
          'Đã đủ địa chỉ',
          'Bạn có thể lưu tối đa 10 địa chỉ.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final addresses = [
        ...savedAddresses.map((item) => Map<String, dynamic>.from(item)),
        {'label': savedAddresses.isEmpty ? 'Nhà' : 'Khác', 'address': address},
      ];
      savedAddresses.assignAll(addresses);
      Get.snackbar(
        'Đã lưu địa chỉ',
        'Địa chỉ đã được lưu thành công.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Không thể lưu địa chỉ',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSavingAddress.value = false;
    }
  }

  Future<void> removeSavedAddress(Map<String, dynamic> address) async {
    final updated = savedAddresses
        .where((item) => item['address'] != address['address'])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    savedAddresses.assignAll(updated);
  }

  double get subtotal => cartController.subtotal;

  double get deliveryFee => selectedOrderType.value == 'delivery' ? 15000 : 0;

  double get total => subtotal - discountAmount.value + deliveryFee;

  bool get canContinue {
    return cartController.cartItems.isNotEmpty &&
        selectedOrderType.value.isNotEmpty;
  }

  void selectOrderType(String type) {
    selectedOrderType.value = type;
  }

  Future<void> applyVoucher() async {
    final code = voucherController.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        'Mã giảm giá',
        'Vui lòng nhập mã giảm giá.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isApplyingVoucher.value) return;
    isApplyingVoucher.value = true;
    try {
      final response = await apiProvider.post(
        '/api/customers/vouchers/validate',
        body: {
          'code': code,
          'orderTotal': subtotal,
        },
      );
      final discount = (response['discountAmount'] as num?)?.toDouble() ?? 0.0;
      discountAmount.value = discount;
      appliedVoucher.value = code;
      Get.snackbar(
        'Đã áp dụng mã giảm giá',
        'Giảm ${_price(discount)} cho đơn hàng.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      discountAmount.value = 0;
      appliedVoucher.value = '';
      Get.snackbar(
        'Không thể áp dụng voucher',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isApplyingVoucher.value = false;
    }
  }

  static String _price(double value) =>
      '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';

  Future<void> continueToPayment() async {
    if (cartController.cartItems.isEmpty) {
      Get.snackbar(
        'Giỏ hàng trống',
        'Vui lòng thêm món trước khi thanh toán.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedOrderType.value.isEmpty) {
      Get.snackbar(
        'Chưa chọn hình thức nhận hàng',
        'Vui lòng chọn Mang đi, Tại quán hoặc Giao hàng.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (customerNameController.text.trim().isEmpty ||
        customerPhoneController.text.trim().isEmpty) {
      Get.snackbar(
        'Thiếu thông tin nhận đơn',
        'Vui lòng nhập tên và số điện thoại.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (selectedOrderType.value == 'delivery' &&
        deliveryAddressController.text.trim().isEmpty) {
      Get.snackbar(
        'Thiếu địa chỉ giao hàng',
        'Vui lòng nhập địa chỉ giao hàng.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (selectedOrderType.value == 'delivery' &&
        deliveryCoordinates.value == null) {
      Get.snackbar(
        'Chưa xác định vị trí',
        'Hãy xác định vị trí giao hàng trước khi tiếp tục.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      await apiProvider.post(
        '/api/orders/precheck',
        body: {
          'customerPhone': customerPhoneController.text.trim(),
          'customerName': customerNameController.text.trim(),
          'orderType': selectedOrderType.value == 'delivery'
              ? 'DELIVERY'
              : selectedOrderType.value == 'dine_in'
              ? 'DINE_IN'
              : 'TAKEAWAY',
          'deliveryAddress': deliveryAddressController.text.trim(),
          if (selectedOrderType.value == 'delivery')
            'deliveryCoordinates': deliveryCoordinates.value,
          'items': cartController.cartItems
              .map(
                (item) => {
                  'productId': item.productId,
                  'productName': item.productName,
                  'branchId': selectedOrderType.value == 'delivery'
                      ? deliveryBranchIdsByBrand[item.brandId] ?? item.branchId
                      : item.branchId,
                  'brandId': item.brandId,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                  'customization': item.customization.toJson(),
                  'selectedModifiers': item.customization.selectedModifiers,
                },
              )
              .toList(),
        },
      );
    } catch (error) {
      Get.snackbar(
        'Chưa thể kiểm tra đơn hàng',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.toNamed(
      AppRoutes.payment,
      arguments: {
        'orderType': selectedOrderType.value == 'delivery'
            ? 'DELIVERY'
            : selectedOrderType.value == 'dine_in'
            ? 'DINE_IN'
            : 'TAKEAWAY',
        'voucherCode': appliedVoucher.value,
        'customerName': customerNameController.text.trim(),
        'customerPhone': customerPhoneController.text.trim(),
        'deliveryAddress': deliveryAddressController.text.trim(),
        'note': noteController.text.trim(),
        'total': total,
        'deliveryFee': deliveryFee,
        if (selectedOrderType.value == 'delivery')
          'deliveryCoordinates': deliveryCoordinates.value,
        'branchIdsByBrand': Map<String, String>.from(deliveryBranchIdsByBrand),
      },
    );
  }

  void clearVoucher() {
    voucherController.clear();
    appliedVoucher.value = '';
    discountAmount.value = 0;
  }

  @override
  void onClose() {
    voucherController.dispose();
    noteController.dispose();
    customerNameController.dispose();
    customerPhoneController.dispose();
    deliveryAddressController.dispose();

    super.onClose();
  }
}
