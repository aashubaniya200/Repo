import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/eCommerce/cart/cart_controller.dart';
import 'package:webpal_commerce/controllers/misc/misc_controller.dart';
import 'package:webpal_commerce/views/eCommerce/dashboard/layouts/dashboard_layout.dart';

class AppBottomNavbar extends ConsumerWidget {
  const AppBottomNavbar({
    super.key,
    required this.bottomItem,
    required this.onSelect,
  });
  final List<BottomItem> bottomItem;
  final Function(int? index) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          bottomItem.length,
          (index) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  onSelect(index);
                },
                child: Container(
                  color: Colors.transparent,
                  child: _buildBottomItem(
                    bottomItem: bottomItem[index],
                    index: index,
                    context: context,
                    ref: ref,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomItem({
    required BottomItem bottomItem,
    required int index,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final int selectedIndex = ref.watch(selectedTabIndexProvider);
    final isSelected = index == selectedIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Animated background circle for selected item
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 40.h,
                width: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colors(context).primaryColor?.withOpacity(0.15)
                      : Colors.transparent,
                ),
              ),
              
              // Icon
              Container(
                height: 40.h,
                width: 40.w,
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? bottomItem.activeIcon : bottomItem.icon,
                    key: ValueKey(isSelected),
                    color: isSelected
                        ? colors(context).primaryColor
                        : colors(context).bodyTextSmallColor?.withOpacity(0.6),
                    size: isSelected ? 26.sp : 24.sp,
                  ),
                ),
              ),
              
              // Cart badge
              if (index == 1) ...[
                Positioned(
                  top: -2,
                  right: -2,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final cartItemCount = ref.watch(cartController).cartItems.length;
                      return cartItemCount > 0
                          ? Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: colors(context).errorColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 18.w,
                                minHeight: 18.h,
                              ),
                              child: Center(
                                child: Text(
                                  cartItemCount > 9 ? '9+' : cartItemCount.toString(),
                                  style: AppTextStyle(context).bodyTextSmall.copyWith(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox();
                    },
                  ),
                )
              ]
            ],
          ),
          
          // Label with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isSelected ? 16.h : 14.h,
            margin: EdgeInsets.only(top: 4.h),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: AppTextStyle(context).bodyTextSmall.copyWith(
                fontSize: isSelected ? 11.sp : 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? colors(context).primaryColor
                    : colors(context).bodyTextSmallColor?.withOpacity(0.6),
                height: 1.2,
              ),
              child: Text(
                bottomItem.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
