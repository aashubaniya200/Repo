// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:webpal_commerce/components/ecommerce/custom_cart.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/eCommerce/cart/cart_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/product/product_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/shop/shop_controller.dart';
import 'package:webpal_commerce/controllers/misc/misc_controller.dart';
import 'package:webpal_commerce/generated/l10n.dart';
import 'package:webpal_commerce/models/eCommerce/cart/add_to_cart_model.dart';
import 'package:webpal_commerce/models/eCommerce/product/product_details.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/services/common/hive_service_provider.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';
import 'package:webpal_commerce/views/eCommerce/products/components/product_color_picker.dart';
import 'package:webpal_commerce/views/eCommerce/products/components/product_description.dart';
import 'package:webpal_commerce/views/eCommerce/products/components/product_details_and_review.dart';
import 'package:webpal_commerce/views/eCommerce/products/components/product_image_page_view.dart';
import 'package:webpal_commerce/views/eCommerce/products/components/product_size_picker.dart';
import 'package:webpal_commerce/views/eCommerce/products/components/similar_products_widget.dart';

class EcommerceProductDetailsLayout extends ConsumerStatefulWidget {
  final int productId;
  const EcommerceProductDetailsLayout({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<EcommerceProductDetailsLayout> createState() =>
      _EcommerceProductDetailsLayoutState();
}

class _EcommerceProductDetailsLayoutState
    extends ConsumerState<EcommerceProductDetailsLayout> {
  bool isTextExpanded = false;
  bool isFavorite = false;
  bool isLoading = false;
  int selectedQuantity = 1;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didpop, result) {
        ref.invalidate(selectedSizePriceProvider);
        ref.invalidate(selectedColorPriceProvider);
      },
      child: LoadingWrapperWidget(
        isLoading: ref.watch(cartController).isLoading,
        child: Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () {
                ref.read(shopControllerProvider.notifier).review.clear();
                context.nav.pop();
              },
              icon: Icon(
                Icons.arrow_back,
                color: colors(context).primaryColor,
              ),
            ),
            actions: [
              _buildAppBarRightRow(context: context),
            ],
          ),
          backgroundColor: colors(context).accentColor,
          bottomNavigationBar: ref
              .watch(productDetailsControllerProvider(widget.productId))
              .whenOrNull(
                data: (productDetails) => _buildBottomNavigationBar(
                    context: context, productDetails: productDetails),
              ),
          body: ref
              .watch(productDetailsControllerProvider(widget.productId))
              .when(
                data: (productDetails) => SingleChildScrollView(
                  child: AnimationLimiter(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 500),
                        childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.h,
                            child: FadeInAnimation(
                              child: widget,
                            )),
                        children: [
                          Gap(2.h),
                          ProductImagePageView(productDetails: productDetails),
                          Gap(2.h),
                          ProductDescription(productDetails: productDetails),
                          Gap(2.h),
                          Visibility(
                            visible: productDetails.product.colors.isNotEmpty,
                            child: ProductColorPicker(
                                productDetails: productDetails),
                          ),
                          Visibility(
                            visible: productDetails
                                .product.productSizeList.isNotEmpty,
                            child: ProductSizePicker(
                                productDetails: productDetails),
                          ),     
                          ProductDetailsAndReview(
                            productDetails: productDetails,
                          ),
                          Gap(14.h),
                          SimilarProductsWidget(
                            productDetails: productDetails,
                          ),
                          Gap(14.h),
                        ],
                      ),
                    ),
                  ),
                ),
                error: ((error, stackTrace) => Center(
                      child: Text(
                        error.toString(),
                      ),
                    )),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
        ),
      ),
    );
  }

  SizedBox _buildAppBarRightRow({required BuildContext context}) {
    return SizedBox(
      child: Padding(
        padding: EdgeInsets.only(right: 20.w, bottom: 6.h),
        child: Row(
          children: [
            CustomCartWidget(context: context),
          ],
        ),
      ),
    );
  }

  Container _buildBottomNavigationBar(
      {required BuildContext context, required ProductDetails productDetails}) {
    final isOutOfStock = productDetails.product.quantity == 0;
    final maxQuantity = productDetails.product.quantity;
    
    return Container(
      decoration: BoxDecoration(
        color: colors(context).light,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: IntrinsicHeight(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
            children: [
              // Quantity Selector
              if (!isOutOfStock) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors(context).primaryColor!.withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      // Decrement button
                      InkWell(
                        onTap: () {
                          if (selectedQuantity > 1) {
                            setState(() {
                              selectedQuantity--;
                            });
                          }
                        },
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.r),
                          bottomLeft: Radius.circular(12.r),
                        ),
                        child: Container(
                          width: 25.w,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Icon(
                            Icons.remove,
                            size: 18.sp,
                            color: selectedQuantity > 1
                                ? colors(context).primaryColor
                                : colors(context).bodyTextColor!.withOpacity(0.3),
                          ),
                        ),
                      ),
                      // Quantity display (tappable to edit)
                      InkWell(
                        onTap: () => _showQuantityInputDialog(maxQuantity),
                        child: Container(
                          constraints: BoxConstraints(minWidth: 35.w),
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                          child: Center(
                            child: Text(
                              selectedQuantity.toString(),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: colors(context).bodyTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Increment button
                      InkWell(
                        onTap: () {
                          if (selectedQuantity < maxQuantity) {
                            setState(() {
                              selectedQuantity++;
                            });
                          }
                        },
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12.r),
                          bottomRight: Radius.circular(12.r),
                        ),
                        child: Container(
                          width: 32.w,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Icon(
                            Icons.add,
                            size: 18.sp,
                            color: selectedQuantity < maxQuantity
                                ? colors(context).primaryColor
                                : colors(context).bodyTextColor!.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(8.w),
              ],
              // Add to Cart Button
              Expanded(
                flex: isOutOfStock ? 1 : 2,
                child: AbsorbPointer(
                  absorbing: isOutOfStock,
                  child: InkWell(
                    onTap: () => _onTapCart(productDetails, false),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
                      decoration: BoxDecoration(
                        gradient: isOutOfStock
                            ? null
                            : LinearGradient(
                                colors: [
                                  colors(context).primaryColor!,
                                  colors(context).primaryColor!.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: isOutOfStock
                            ? colors(context).bodyTextColor!.withOpacity(0.3)
                            : null,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              isOutOfStock
                                  ? 'Out of Stock'
                                  : S.of(context).addToCart,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!isOutOfStock) ...[
                Gap(8.w),
                // Buy Now Button
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => _onTapCart(productDetails, true),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: colors(context).light,
                        border: Border.all(
                          color: colors(context).primaryColor!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flash_on,
                            color: colors(context).primaryColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              S.of(context).buyNow,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: colors(context).primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTapCart(ProductDetails productDetails, bool isBuyNow) async {
    final AddToCartModel addToCartModel = AddToCartModel(
      productId: productDetails.product.id,
      quantity: selectedQuantity,
      size: productDetails.product.productSizeList.isNotEmpty
          ? productDetails
              .product.productSizeList[ref.read(selectedProductSizeIndex)].id
          : null,
      color: productDetails.product.colors.isNotEmpty
          ? productDetails
              .product.colors[ref.read(selectedProductColorIndex)!].id
          : null,
    );
    if (!ref.read(hiveServiceProvider).userIsLoggedIn()) {
      _showTheWarningDialog();
    } else {
      await ref
          .read(cartController.notifier)
          .addToCart(addToCartModel: addToCartModel);

      if (isBuyNow) {
        context.nav.pushNamed(
            Routes.getMyCartViewRouteName(
              AppConstants.appServiceName,
            ),
            arguments: [false, isBuyNow]);
      } else {
        // Reset quantity after adding to cart
        setState(() {
          selectedQuantity = 1;
        });
      }
    }
  }

  void _showTheWarningDialog() {
    GlobalFunction.navigatorKey.currentContext!.nav
        .pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  void _showQuantityInputDialog(int maxQuantity) {
    final TextEditingController quantityController = 
        TextEditingController(text: selectedQuantity.toString());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Enter Quantity',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available: $maxQuantity',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: colors(context).bodyTextColor!.withOpacity(0.6),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: colors(context).primaryColor!.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: colors(context).primaryColor!,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                onSubmitted: (value) {
                  _updateQuantityFromInput(quantityController.text, maxQuantity);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors(context).bodyTextColor!.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _updateQuantityFromInput(quantityController.text, maxQuantity);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateQuantityFromInput(String input, int maxQuantity) {
    final int? parsedQuantity = int.tryParse(input);
    
    if (parsedQuantity != null && parsedQuantity > 0) {
      setState(() {
        // Clamp the value between 1 and maxQuantity
        selectedQuantity = parsedQuantity.clamp(1, maxQuantity);
      });
      
      // Show feedback if quantity was adjusted
      if (parsedQuantity > maxQuantity) {
        GlobalFunction.showCustomSnackbar(
          message: 'Maximum available quantity is $maxQuantity',
          isSuccess: false,
        );
      }
    } else {
      // Invalid input - reset to 1
      setState(() {
        selectedQuantity = 1;
      });
      GlobalFunction.showCustomSnackbar(
        message: 'Please enter a valid quantity',
        isSuccess: false,
      );
    }
  }
}

class LoadingWrapperWidget extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  const LoadingWrapperWidget({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        if (isLoading)
          Center(
            child: CircularProgressIndicator(
              color: colors(context).primaryColor,
              strokeWidth: 3,
            ),
          ),
      ],
    );
  }
}
