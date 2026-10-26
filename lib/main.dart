import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';

void main() {
  runApp(const MaxkoApp());
}
class MaxkoApp extends StatelessWidget {
  const MaxkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

        title: 'MAXKO F&B',

        theme: AppTheme.light,

      initialRoute: AppRoutes.main,

        getPages: AppPages.routes,
    );
  }
}
