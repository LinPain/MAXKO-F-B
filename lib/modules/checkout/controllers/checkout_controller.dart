import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../cart/controllers/cart_controller.dart';
import '../../../app/routes/app_routes.dart';

class CheckoutController extends GetxController {
  final CartController cartController;

  CheckoutController({required this.cartController});

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

  @override
  void onInit() {
    super.onInit();
    loadSavedAddresses();
  }

  Future<void> loadSavedAddresses() async {
    if (savedAddresses.isEmpty) {
      savedAddresses.assignAll([
        {'label': 'Nhà', 'address': '128 Cầu Giấy, Hà Nội'},
      ]);
    }
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
        'Địa chỉ được lưu tạm trong phiên xem trước này.',
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
    final voucher = voucherController.text.trim();

    if (voucher.isEmpty) {
      Get.snackbar(
        'Mã giảm giá',
        'Vui lòng nhập mã giảm giá.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isApplyingVoucher.value = true;
      final code = voucher.toUpperCase();
      if (code == 'MAXKO20' && subtotal >= 80000) {
        discountAmount.value = subtotal * 0.2;
      } else if (code == 'FREESHIP' && deliveryFee > 0) {
        discountAmount.value = deliveryFee;
      } else {
        throw Exception(
          'Dùng MAXKO20 cho đơn từ 80.000đ hoặc FREESHIP cho đơn giao hàng.',
        );
      }
      appliedVoucher.value = code;
      Get.snackbar(
        'Đã áp dụng voucher',
        'Bạn được giảm ${discountAmount.value.toStringAsFixed(0)}đ.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      discountAmount.value = 0;
      appliedVoucher.value = '';
      Get.snackbar(
        'Voucher không áp dụng được',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isApplyingVoucher.value = false;
    }
  }

  void continueToPayment() {
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
