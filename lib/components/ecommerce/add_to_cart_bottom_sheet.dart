import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:webpal_commerce/config/app_color.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/common/master_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/cart/cart_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/product/product_controller.dart';
import 'package:webpal_commerce/controllers/misc/misc_controller.dart';
import 'package:webpal_commerce/generated/l10n.dart';
import 'package:webpal_commerce/models/eCommerce/cart/add_to_cart_model.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/services/common/hive_service_provider.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';
import 'package:webpal_commerce/utils/responsive_helper.dart';
// import 'package:webpal_commerce/views/eCommerce/products/layouts/product_details_layout.dart';

import '../../models/eCommerce/product/product.dart';

class AddToCartBottomSheet extends ConsumerStatefulWidget {
  final Product product;
  const AddToCartBottomSheet({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<AddToCartBottomSheet> createState() => _AddToCartBottomSheetState();
}

class _AddToCartBottomSheetState extends ConsumerState<AddToCartBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Reset quantity to 1 when opening the bottom sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedProductQuantity.notifier).state = 1;
    });
  }

  @override
  void dispose() {
    // Defensive cleanup: Ensure any loading dialogs are closed when bottom sheet is disposed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        GlobalFunction.hideLoading();
      } catch (_) {
        // Ignore
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Constrain width on tablets for better UX
    final maxWidth = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context)
        ? 600.0
        : double.infinity;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          // Add padding for keyboard - this pushes content up when keyboard appears
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 24.h,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).select,
                    style: AppTextStyle(context).subTitle.copyWith(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Clear any loading dialogs before closing
                      GlobalFunction.hideLoading();
                      ref.read(selectedProductQuantity.notifier).state = 1;
                      context.nav.pop();
                    },
                    icon: Container(
                      padding: EdgeInsets.all(8.sp),
                      decoration: BoxDecoration(
                        color: colors(context).accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20.sp,
                      ),
                    ),
                  )
                ],
              ),
              Gap(16.h),
              
              // Product card
              _buildProductCard(),
              
              Gap(16.h),
              
              // Quantity selector
              _buildQuantitySelector(),
              
              Gap(16.h),
              
              // Attributes (color/size)
              Visibility(
                visible: widget.product.colors.isNotEmpty ||
                    widget.product.productSizeList.isNotEmpty,
                child: _buildAttributeWidget(),
              ),
              
              Gap(24.h),
              
              // Bottom buttons
              _buildBottomRow(),
              
              Gap(8.h),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Consumer(builder: (context, ref, _) {
      final quantity = ref.watch(selectedProductQuantity);
      final quantityController = TextEditingController(text: quantity.toString());
      
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: colors(context).accentColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: colors(context).primaryColor!.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  size: 20.sp,
                  color: colors(context).primaryColor,
                ),
                Gap(8.w),
                Text(
                  'Quantity',
                  style: AppTextStyle(context).bodyText.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Gap(12.h),
            Row(
              children: [
                // Decrease button
                Material(
                  color: colors(context).primaryColor,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: () {
                      if (quantity > 1) {
                        ref.read(selectedProductQuantity.notifier).state = quantity - 1;
                      }
                    },
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
                
                Gap(12.w),
                
                // Quantity input field
                Expanded(
                  child: Container(
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: colors(context).primaryColor!.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: AppTextStyle(context).bodyText.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                        hintText: '1',
                      ),
                      onChanged: (value) {
                        final qty = int.tryParse(value);
                        if (qty != null && qty > 0 && qty <= widget.product.quantity) {
                          ref.read(selectedProductQuantity.notifier).state = qty;
                        }
                      },
                    ),
                  ),
                ),
                
                Gap(12.w),
                
                // Increase button
                Material(
                  color: colors(context).primaryColor,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: () {
                      if (quantity < widget.product.quantity) {
                        ref.read(selectedProductQuantity.notifier).state = quantity + 1;
                      }
                    },
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Gap(8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available: ${widget.product.quantity}',
                  style: AppTextStyle(context).bodyTextSmall.copyWith(
                    color: EcommerceAppColor.gray,
                    fontSize: 12.sp,
                  ),
                ),
                if (quantity == widget.product.quantity)
                  Text(
                    'Max reached',
                    style: AppTextStyle(context).bodyTextSmall.copyWith(
                      color: EcommerceAppColor.red,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProductCard() {
    return Consumer(builder: (context, ref, _) {
      return Container(
        height: 140.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors(context).accentColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: colors(context).primaryColor!.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Product image
            Container(
              width: 120.w,
              height: 140.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.product.thumbnail,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colors(context).accentColor,
                    child: Icon(
                      Icons.image,
                      size: 40.sp,
                      color: colors(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            
            // Product details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.product.name}\n',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(ContextLess.context)
                          .bodyText
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    Gap(8.h),
                    if (widget.product.discountPrice > 0) ...[
                      Text(
                        ref
                                .read(masterControllerProvider.notifier)
                                .materModel
                                .data
                                .currency
                                .symbol +
                            (widget.product.discountPrice +
                                    ref.watch(selectedColorPriceProvider) +
                                    ref.watch(selectedSizePriceProvider))
                                .toString(),
                        style: AppTextStyle(context)
                            .bodyText
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      Text(
                        ref
                                .read(masterControllerProvider.notifier)
                                .materModel
                                .data
                                .currency
                                .symbol +
                            (widget.product.price +
                                    ref.watch(selectedColorPriceProvider) +
                                    ref.watch(selectedSizePriceProvider))
                                .toString(),
                        style: AppTextStyle(context)
                            .bodyText
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                    if (widget.product.discountPrice > 0) ...[
                      Text(
                        ref
                                .read(masterControllerProvider.notifier)
                                .materModel
                                .data
                                .currency
                                .symbol +
                            widget.product.price.toString(),
                        style: AppTextStyle(context).bodyText.copyWith(
                              color: EcommerceAppColor.lightGray,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: EcommerceAppColor.lightGray,
                            ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAttributeWidget() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors(ContextLess.context).accentColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colors(ContextLess.context).primaryColor!.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Visibility(
            visible: widget.product.colors.isNotEmpty,
            child: _buildColorPickerWidget(),
          ),
          if (widget.product.colors.isNotEmpty && widget.product.productSizeList.isNotEmpty)
            Gap(16.h),
          Visibility(
            visible: widget.product.productSizeList.isNotEmpty,
            child: _buildSizePicker(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerWidget() {
    return Consumer(builder: (context, ref, _) {
      return Column(
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
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Gap(12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: List.generate(
                  widget.product.colors.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(5.r),
                        onTap: () {
                          ref.read(selectedProductColorIndex.notifier).state =
                              index;
                          ref.read(selectedColorPriceProvider.notifier).state =
                              widget.product.colors[index].price;
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.dm),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.r),
                            border: Border.all(
                              color:
                                  ref.watch(selectedProductColorIndex) == index
                                      ? EcommerceAppColor.primary
                                      : colors(context).accentColor!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.product.colors[index].name[0].toUpperCase() +
                                  widget.product.colors[index].name.substring(1),
                              style: AppTextStyle(context).bodyText.copyWith(
                                    color:
                                        ref.watch(selectedProductColorIndex) ==
                                                index
                                            ? EcommerceAppColor.primary
                                            : EcommerceAppColor.gray,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  // Widget _buildColorPickerWidget() {
  //   return Consumer(builder: (context, ref, _) {
  //     return Container(
  //       width: double.infinity,
  //       padding: EdgeInsets.all(16.dm),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(8.r),
  //         color: GlobalFunction.getContainerColor(),
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             S.of(context).color,
  //             style: AppTextStyle(context).bodyText.copyWith(fontSize: 16.sp),
  //           ),
  //           Gap(8.h),
  //           Row(
  //             children: [
  //               Wrap(
  //                 alignment: WrapAlignment.start,
  //                 direction: Axis.horizontal,
  //                 children: List.generate(
  //                   widget.product.colors.length,
  //                   (index) => Padding(
  //                     padding: EdgeInsets.only(right: 8.w),
  //                     child: Material(
  //                       color: Theme.of(context).scaffoldBackgroundColor,
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(5.r),
  //                       ),
  //                       child: InkWell(
  //                         borderRadius: BorderRadius.circular(5.r),
  //                         onTap: () {
  //                           ref.read(selectedProductColorIndex.notifier).state =
  //                               index;
  //                           ref
  //                               .read(selectedColorPriceProvider.notifier)
  //                               .state = widget.product.colors[index].price;
  //                         },
  //                         child: Container(
  //                           padding: EdgeInsets.all(8.dm),
  //                           decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(5.r),
  //                             border: Border.all(
  //                               color: ref.watch(selectedProductColorIndex) ==
  //                                       index
  //                                   ? EcommerceAppColor.primary
  //                                   : colors(context).accentColor!,
  //                             ),
  //                           ),
  //                           child: Center(
  //                             child: Text(
  //                               widget.product.colors[index].name[0].toUpperCase() +
  //                                   widget.product.colors[index].name.substring(1),
  //                               style: AppTextStyle(context).bodyText.copyWith(
  //                                     color: ref.watch(
  //                                                 selectedProductColorIndex) ==
  //                                             index
  //                                         ? EcommerceAppColor.primary
  //                                         : EcommerceAppColor.gray,
  //                                   ),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           )
  //         ],
  //       ),
  //     );
  //   });
  // }
  Widget _buildSizePicker() {
    return Consumer(builder: (context, ref, _) {
      return Column(
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
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Gap(12.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  widget.product.productSizeList.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(5.r),
                        onTap: () {
                          ref.read(selectedProductSizeIndex.notifier).state =
                              index;
                          ref.read(selectedSizePriceProvider.notifier).state =
                              widget.product.productSizeList[index].price;
                        },
                        child: IntrinsicWidth(
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.r),
                              border: Border.all(
                                color:
                                    ref.watch(selectedProductSizeIndex) == index
                                        ? EcommerceAppColor.primary
                                        : colors(context).accentColor!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.product.productSizeList[index].name,
                                style: AppTextStyle(context).bodyText.copyWith(
                                      color:
                                          ref.watch(selectedProductSizeIndex) ==
                                                  index
                                              ? EcommerceAppColor.primary
                                              : EcommerceAppColor.gray,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  // Widget _buildSizePicker() {
  //   return Consumer(builder: (context, ref, _) {
  //     return Container(
  //       width: double.infinity,
  //       padding: EdgeInsets.all(16.dm),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(8.r),
  //         color: GlobalFunction.getContainerColor(),
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             S.of(context).size,
  //             style: AppTextStyle(context).bodyText.copyWith(
  //                   fontSize: 16.sp,
  //                 ),
  //           ),
  //           Gap(10.h),
  //           Wrap(
  //             alignment: WrapAlignment.start,
  //             direction: Axis.horizontal,
  //             runSpacing: 8.w,
  //             children: List.generate(
  //               widget.product.productSizeList.length,
  //               (index) => Padding(
  //                 padding: EdgeInsets.only(right: 8.w),
  //                 child: Material(
  //                   color: Theme.of(context).scaffoldBackgroundColor,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(5.r),
  //                   ),
  //                   child: InkWell(
  //                     borderRadius: BorderRadius.circular(5.r),
  //                     onTap: () {
  //                       ref.read(selectedProductSizeIndex.notifier).state =
  //                           index;
  //                       ref.read(selectedSizePriceProvider.notifier).state =
  //                           widget.product.productSizeList[index].price;
  //                     },
  //                     child: IntrinsicWidth(
  //                       child: Container(
  //                         padding: EdgeInsets.all(8.r),
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(5.r),
  //                           border: Border.all(
  //                             color:
  //                                 ref.watch(selectedProductSizeIndex) == index
  //                                     ? EcommerceAppColor.primary
  //                                     : colors(context).accentColor!,
  //                           ),
  //                         ),
  //                         child: Center(
  //                           child: Text(
  //                             widget.product.productSizeList[index].name,
  //                             style: AppTextStyle(context).bodyText.copyWith(
  //                                   color:
  //                                       ref.watch(selectedProductSizeIndex) ==
  //                                               index
  //                                           ? EcommerceAppColor.primary
  //                                           : EcommerceAppColor.gray,
  //                                 ),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           )
  //         ],
  //       ),
  //     );
  //   });
  // }

  Widget _buildBottomRow() {
    return Consumer(builder: (context, ref, _) {
      final quantity = ref.watch(selectedProductQuantity);
      final bool isOutOfStock = widget.product.quantity == 0;
      final bool canAddToCart = quantity > 0 && quantity <= widget.product.quantity && !isOutOfStock;
      
      return Row(
        children: [
          // Add to Cart Button
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: canAddToCart
                    ? () async {
                        if (!ref.read(hiveServiceProvider).userIsLoggedIn()) {
                            _showTheWarningDialog();
                        } else {
                          // Don't use global loading for add to cart - just close the sheet
                          await _onTapCart(false, ref, context);
                          
                          // Close the bottom sheet
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      }
                    : null,
                child: Container(
                  height: 50.h,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: canAddToCart
                          ? colors(context).primaryColor!
                          : colors(context).primaryColor!.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: canAddToCart
                              ? colors(context).primaryColor
                              : colors(context).primaryColor!.withOpacity(0.3),
                          size: 20.sp,
                        ),
                        Gap(8.w),
                        Text(
                          S.of(context).addToCart,
                          style: AppTextStyle(context).bodyText.copyWith(
                            color: canAddToCart
                                ? colors(context).primaryColor
                                : colors(context).primaryColor!.withOpacity(0.3),
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Gap(12.w),
          
          // Buy Now Button
          Expanded(
            child: Material(
              color: canAddToCart
                  ? colors(context).primaryColor
                  : colors(context).primaryColor!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12.r),
              elevation: canAddToCart ? 2 : 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: canAddToCart
                    ? () async {
                        if (!ref.read(hiveServiceProvider).userIsLoggedIn()) {
                          _showTheWarningDialog();
                        } else {
                          // Don't use global loading for buy now - just execute and navigate
                          await _onTapCart(true, ref, context);
                        }
                      }
                    : null,
                child: SizedBox(
                  height: 50.h,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        Gap(8.w),
                        Text(
                          S.of(context).buyNow,
                          style: AppTextStyle(context).bodyText.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showTheWarningDialog() {
    GlobalFunction.navigatorKey.currentContext!.nav
        .pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  Future<void> _onTapCart(bool isBuyNow, WidgetRef ref,
      BuildContext context) async {
    final AddToCartModel addToCartModel = AddToCartModel(
      productId: widget.product.id,
      quantity: ref.read(selectedProductQuantity),
      size: widget.product.productSizeList.isNotEmpty
          ? widget.product.productSizeList[ref.read(selectedProductSizeIndex)].id
          : null,
      color: widget.product.colors.isNotEmpty
          ? widget.product.colors[ref.read(selectedProductColorIndex)!].id
          : null,
    );

    if (!ref.read(hiveServiceProvider).userIsLoggedIn()) {
      _showTheWarningDialog();
    } else {
      await ref
          .read(cartController.notifier)
          .addToCart(addToCartModel: addToCartModel);
      if (isBuyNow) {
        context.nav.pop();
        context.nav.pushNamed(
            Routes.getMyCartViewRouteName(
              AppConstants.appServiceName,
            ),
            arguments: [false, isBuyNow]);
      }
    }
  }
}
