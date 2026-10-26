import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.onMenuTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.onHistoryTap,
    this.onCartTap,
    this.onProfileTap,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _HeaderAction(
              icon: Icons.menu_rounded,
              onPressed: onMenuTap,
              tooltip: 'Mở danh mục',
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'MAXKO',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_cafe_rounded,
                        color: AppColors.primary,
                        size: 11,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'F&B GROUP',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _HeaderAction(
              icon: Icons.search_rounded,
              onPressed: onSearchTap,
              tooltip: 'Tìm kiếm',
            ),
            _HeaderAction(
              icon: onCartTap == null
                  ? Icons.receipt_long_outlined
                  : Icons.shopping_bag_outlined,
              onPressed: onCartTap ?? onHistoryTap,
              tooltip: onCartTap == null ? 'Lịch sử đơn hàng' : 'Giỏ hàng',
            ),
            _HeaderAction(
              icon: Icons.person_outline_rounded,
              onPressed: onProfileTap,
              tooltip: 'Tài khoản',
              accent: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: accent ? AppColors.primary : Colors.transparent,
        foregroundColor: accent ? Colors.white : AppColors.textPrimary,
      ),
      icon: Icon(icon, size: 21),
    );
  }
}
