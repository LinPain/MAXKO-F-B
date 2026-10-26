import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

/// Compact five destination navigation styled to match the Stitch mobile UI.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.orderBadgeCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int orderBadgeCount;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
    (Icons.storefront_outlined, Icons.storefront_rounded, 'Thương hiệu'),
    (Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded, 'Đặt món'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Đơn hàng'),
    (Icons.card_membership_outlined, Icons.card_membership_rounded, 'Hội viên'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 24,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                selectedIndex == index
                                    ? _items[index].$2
                                    : _items[index].$1,
                                size: 20,
                                color: selectedIndex == index
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              if (index == 3 && orderBadgeCount > 0)
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE53935),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      orderBadgeCount > 99
                                          ? '99+'
                                          : '$orderBadgeCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[index].$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: selectedIndex == index
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: selectedIndex == index
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
