import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';

/// Widget to display MRP and selling price with discount badge
class PriceDisplayWidget extends StatelessWidget {
  final double sellingPrice;
  final double? mrp;
  final bool showDiscount;
  final double? discountPercentage;
  final TextStyle? sellingPriceStyle;
  final TextStyle? mrpStyle;
  final MainAxisAlignment alignment;

  const PriceDisplayWidget({
    super.key,
    required this.sellingPrice,
    this.mrp,
    this.showDiscount = true,
    this.discountPercentage,
    this.sellingPriceStyle,
    this.mrpStyle,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShowMRP = mrp != null && mrp! > sellingPrice;
    final effectiveDiscount = discountPercentage ?? 
      (shouldShowMRP ? ((mrp! - sellingPrice) / mrp!) * 100 : 0);

    return Row(
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Selling Price
        Text(
          '৳${sellingPrice.toStringAsFixed(2)}',
          style: sellingPriceStyle ??
              AppTextStyle(context).title.copyWith(
                    color: colors(context).primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
        ),
        
        if (shouldShowMRP) ...[
          SizedBox(width: 8.w),
          
          // MRP (Strikethrough)
          Text(
            '৳${mrp!.toStringAsFixed(2)}',
            style: mrpStyle ??
                AppTextStyle(context).bodyText.copyWith(
                      decoration: TextDecoration.lineThrough,
                      decorationColor: colors(context).bodyTextSmallColor,
                      color: colors(context).bodyTextSmallColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
          ),
        ],
        
        if (showDiscount && shouldShowMRP && effectiveDiscount > 0) ...[
          SizedBox(width: 8.w),
          
          // Discount Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: colors(context).errorColor?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              '${effectiveDiscount.toStringAsFixed(0)}% OFF',
              style: AppTextStyle(context).bodyTextSmall.copyWith(
                    color: colors(context).errorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact version for list items
class CompactPriceDisplayWidget extends StatelessWidget {
  final double sellingPrice;
  final double? mrp;

  const CompactPriceDisplayWidget({
    super.key,
    required this.sellingPrice,
    this.mrp,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShowMRP = mrp != null && mrp! > sellingPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selling Price
        Text(
          '৳${sellingPrice.toStringAsFixed(2)}',
          style: AppTextStyle(context).bodyText.copyWith(
                color: colors(context).primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
              ),
        ),
        
        if (shouldShowMRP) ...[
          SizedBox(height: 2.h),
          
          // MRP with discount percentage
          Row(
            children: [
              Text(
                '৳${mrp!.toStringAsFixed(2)}',
                style: AppTextStyle(context).bodyTextSmall.copyWith(
                      decoration: TextDecoration.lineThrough,
                      decorationColor: colors(context).bodyTextSmallColor,
                      color: colors(context).bodyTextSmallColor,
                      fontSize: 12.sp,
                    ),
              ),
              SizedBox(width: 4.w),
              Text(
                '(${(((mrp! - sellingPrice) / mrp!) * 100).toStringAsFixed(0)}% off)',
                style: AppTextStyle(context).bodyTextSmall.copyWith(
                      color: colors(context).errorColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
