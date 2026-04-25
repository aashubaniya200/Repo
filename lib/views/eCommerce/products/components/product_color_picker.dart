import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/eCommerce/product/product_controller.dart';
import 'package:webpal_commerce/controllers/misc/misc_controller.dart';
import 'package:webpal_commerce/generated/l10n.dart';
import 'package:webpal_commerce/models/eCommerce/product/product_details.dart';

class ProductColorPicker extends ConsumerStatefulWidget {
  final ProductDetails productDetails;
  const ProductColorPicker({
    super.key,
    required this.productDetails,
  });

  @override
  ConsumerState<ProductColorPicker> createState() => _ProductColorPickerState();
}

class _ProductColorPickerState extends ConsumerState<ProductColorPicker> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.refresh(selectedProductColorIndex.notifier).state;
      ref.read(selectedColorPriceProvider.notifier).state =
          widget.productDetails.product.colors[0].price;
      ref.read(selectedColorProvider.notifier).state =
          widget.productDetails.product.colors[0];
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 20.sp,
                color: colors(context).primaryColor,
              ),
              Gap(8.w),
              Text(
                S.of(context).color,
                style: AppTextStyle(context).bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: List.generate(
              widget.productDetails.product.colors.length,
              (index) {
                final color = widget.productDetails.product.colors[index];
                final isSelected = ref.watch(selectedProductColorIndex) == index;
                
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedProductColorIndex.notifier).state = index;
                    ref.read(selectedColorPriceProvider.notifier).state = color.price;
                    ref.read(selectedColorProvider.notifier).state = color;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? colors(context).primaryColor
                          : colors(context).accentColor?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? colors(context).primaryColor!
                            : colors(context).accentColor!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      color.name[0].toUpperCase() + color.name.substring(1),
                      style: AppTextStyle(context).bodyText.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14.sp,
                        color: isSelected
                            ? Colors.white
                            : colors(context).bodyTextColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
