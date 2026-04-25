import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/eCommerce/cart/cart_controller.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';

class CustomCartWidget extends StatelessWidget {
  const CustomCartWidget({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.nav.pushNamed(
          Routes.getMyCartViewRouteName(AppConstants.appServiceName),
          arguments: [false, false],
        );
      },
      child: Container(
        padding: EdgeInsets.all(10.w),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 28.sp,
              color: colors(context).primaryColor,
            ),
            Positioned(
              right: -6.w,
              top: -6.h,
              child: Consumer(builder: (context, ref, _) {
                final itemCount = ref.watch(cartController).cartItems.length;
                return itemCount > 0
                    ? Container(
                        padding: EdgeInsets.all(4.w),
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
                            itemCount > 9 ? '9+' : itemCount.toString(),
                            style: AppTextStyle(context).bodyTextSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox();
              }),
            )
          ],
        ),
      ),
    );
  }
}
