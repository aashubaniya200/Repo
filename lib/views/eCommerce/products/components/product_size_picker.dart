// ignore_for_file: public_member_api_docs, sort_constructors_first
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

class ProductSizePicker extends ConsumerStatefulWidget {
  final ProductDetails productDetails;
  const ProductSizePicker({
    super.key,
    required this.productDetails,
  });

  @override
  ConsumerState<ProductSizePicker> createState() => _ProductSizePickerState();
}

class _ProductSizePickerState extends ConsumerState<ProductSizePicker> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.refresh(selectedProductSizeIndex.notifier).state;
      ref.read(selectedSizePriceProvider.notifier).state =
          widget.productDetails.product.productSizeList[0].price;
      ref.read(selectedSizeProvider.notifier).state =
          widget.productDetails.product.productSizeList[0];
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
                Icons.straighten_outlined,
                size: 20.sp,
                color: colors(context).primaryColor,
              ),
              Gap(8.w),
              Text(
                S.of(context).size,
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
              widget.productDetails.product.productSizeList.length,
              (index) {
                final size = widget.productDetails.product.productSizeList[index];
                final isSelected = ref.watch(selectedProductSizeIndex) == index;
                
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedProductSizeIndex.notifier).state = index;
                    ref.read(selectedSizePriceProvider.notifier).state = size.price;
                    ref.read(selectedSizeProvider.notifier).state = size;
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
                      size.name,
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
