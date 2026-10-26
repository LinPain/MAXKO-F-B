import 'package:get/get.dart';

import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/views/signup_view.dart';
import '../../modules/auth/views/forgot_password_view.dart';
import '../../modules/auth/views/change_password_view.dart';
import '../../modules/checkout/bindings/checkout_binding.dart';
import '../../modules/checkout/views/checkout_view.dart';
import '../../modules/main/bindings/main_binding.dart';
import '../../modules/main/views/main_view.dart';
import '../../modules/payment/bindings/payment_binding.dart';
import '../../modules/payment/views/payment_view.dart';
import '../../modules/menu/bindings/product_detail_binding.dart';
import '../../modules/menu/views/product_detail_view.dart';
import '../../modules/orders/views/order_history_view.dart';
import '../../modules/account/bindings/account_binding.dart';
import '../../modules/account/views/account_view.dart';
import '../../modules/notifications/views/notifications_view.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = [
    GetPage(
      name: AppRoutes.main,
      page: () => MainView(),
      binding: MainBinding(),
    ),

    GetPage(
      name: AppRoutes.productDetail,
      page: () => const ProductDetailView(),
      binding: ProductDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.checkout,
      page: () => const CheckoutView(),
      binding: CheckoutBinding(),
    ),
    GetPage(
      name: AppRoutes.payment,
      page: () => const PaymentView(),
      binding: PaymentBinding(),
    ),
    GetPage(name: AppRoutes.orderHistory, page: () => const OrderHistoryView()),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
    ),
    GetPage(
      name: AppRoutes.account,
      page: () => const AccountView(),
      binding: AccountBinding(),
    ),
  ];
}
