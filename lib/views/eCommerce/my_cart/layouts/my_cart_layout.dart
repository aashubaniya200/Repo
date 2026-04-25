import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:webpal_commerce/config/app_color.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/common/master_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/cart/cart_controller.dart';
import 'package:webpal_commerce/controllers/misc/misc_controller.dart';
import 'package:webpal_commerce/gen/assets.gen.dart';
import 'package:webpal_commerce/generated/l10n.dart';
import 'package:webpal_commerce/models/eCommerce/cart/cart_product.dart';
import 'package:webpal_commerce/models/eCommerce/cart/hive_cart_model.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';
import 'package:webpal_commerce/views/eCommerce/my_cart/components/cart_product_card.dart';
import 'package:webpal_commerce/views/eCommerce/my_cart/components/voucher_bottom_sheet.dart';
import 'package:webpal_commerce/views/eCommerce/products/layouts/product_details_layout.dart';

class EcommerceMyCartLayout extends ConsumerStatefulWidget {
  final bool isRoot;
  final bool isBuynow;
  const EcommerceMyCartLayout({
    super.key,
    required this.isRoot,
    this.isBuynow = false,
  });

  @override
  ConsumerState<EcommerceMyCartLayout> createState() =>
      _EcommerceMyCartLayoutState();
}

class _EcommerceMyCartLayoutState extends ConsumerState<EcommerceMyCartLayout> {
  final TextEditingController promoCodeController = TextEditingController();

  bool isCouponApply = false;
  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    promoCodeController.dispose();
    super.dispose();
  }

  void init() {
    // Listen to cart changes and re-add shop IDs immediately
    ref.listenManual(cartController, (previous, next) {
      if (next.cartItems.isNotEmpty) {
        // Re-add all shop IDs whenever cart changes
        ref.read(shopIdsProvider.notifier).addAllShopIds();
      } else {
        ref.read(shopIdsProvider.notifier).clearShopIds();
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final cartItems = ref.read(cartController).cartItems;
      if (cartItems.isNotEmpty) {
        calculateCartSummery();
      }
    });
  }

  void calculateCartSummery() {
    ref.read(shopIdsProvider.notifier).addAllShopIds();
    ref.read(cartSummeryController.notifier).calculateCartSummery(
          couponCode: promoCodeController.text,
          shopIds: ref.read(shopIdsProvider).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWrapperWidget(
      isLoading: ref.watch(cartController).isLoading,
      child: Scaffold(
        appBar: ref.watch(cartController).cartItems.isEmpty
            ? null
            : _buildAppBar(context: context, cartItems: [], isRoot: true),
        backgroundColor: colors(context).accentColor,
        body: ref.watch(cartController).cartItems.isEmpty
            ? Center(child: _buildEmptyCartWidget())
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: AnimationLimiter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.h,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            Gap(12.h),
                            Column(
                              children: List.generate(
                                ref.watch(cartController).cartItems.length,
                                (index) => Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: _buildCartProductList(
                                    cartItem: ref
                                        .watch(cartController)
                                        .cartItems[index],
                                  ),
                                ),
                              ),
                            ),
                            _buildPromoCodeApplyWidget(context: context),
                            Gap(12.h),
                            _buildSummaryWidget(context: context),
                            Gap(MediaQuery.of(context).size.height / 6.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4.h,
                    left: 0,
                    right: 0,
                    child: _buildBottomNavigationBar(context: context),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyCartWidget() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated Container with Icon
          Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EcommerceAppColor.primary.withOpacity(0.1),
                  EcommerceAppColor.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: EcommerceAppColor.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 60.sp,
                  color: EcommerceAppColor.primary.withOpacity(0.6),
                ),
              ),
            ),
          ),
          Gap(32.h),
          
          // Main Title
          Text(
            S.of(context).yourCartIsEmpty,
            textAlign: TextAlign.center,
            style: AppTextStyle(context).title.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: colors(context).bodyTextColor,
            ),
          ),
          Gap(12.h),
          
          // Subtitle
          Text(
            'Looks like you haven\'t added anything to cart',
            textAlign: TextAlign.center,
            style: AppTextStyle(context).bodyText.copyWith(
              fontSize: 14.sp,
              color: colors(context).bodyTextSmallColor?.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          Gap(40.h),
          
          // Primary CTA Button - Start Shopping
          _buildModernShoppingButton(),
          Gap(16.h),
          
          // Secondary suggestion cards
          _buildSuggestionCards(),
        ],
      ),
    );
  }

  Widget _buildModernShoppingButton() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          if (widget.isRoot) {
            ref.read(bottomTabControllerProvider).jumpToPage(0);
            ref.read(selectedTabIndexProvider.notifier).state = 0;
          } else {
            context.nav.pushNamedAndRemoveUntil(
                Routes.getCoreRouteName(AppConstants.appServiceName),
                (route) => false);
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [
                EcommerceAppColor.primary,
                EcommerceAppColor.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Container(
            width: double.infinity,
            height: 56.h,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 22.sp,
                ),
                Gap(12.w),
                Text(
                  S.of(context).continueShopping,
                  style: AppTextStyle(context).buttonText.copyWith(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSuggestionCard(
            icon: Icons.favorite_outline,
            title: 'View Wishlist',
            onTap: () {
              ref.read(bottomTabControllerProvider).jumpToPage(3);
              ref.read(selectedTabIndexProvider.notifier).state = 3;
            },
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildSuggestionCard(
            icon: Icons.local_offer_outlined,
            title: 'View Offers',
            onTap: () {
              ref.read(bottomTabControllerProvider).jumpToPage(0);
              ref.read(selectedTabIndexProvider.notifier).state = 0;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: colors(context).accentColor?.withOpacity(0.2) ??
                  Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28.sp,
                color: EcommerceAppColor.primary.withOpacity(0.8),
              ),
              Gap(8.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyle(context).bodyTextSmall.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: colors(context).bodyTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartProductList({
    required CartItem cartItem,
  }) {
    return Container(
      color: GlobalFunction.getContainerColor(),
      padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: checkMultivendor(),
            child: Row(
              children: [
                Checkbox(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: colors(context).primaryColor,
                  value: ref.watch(shopIdsProvider).contains(cartItem.shopId),
                  onChanged: (v) {
                    ref
                        .read(shopIdsProvider.notifier)
                        .toggleShopId(cartItem.shopId);
                    ref
                        .read(cartSummeryController.notifier)
                        .calculateCartSummery(
                          couponCode: promoCodeController.text,
                          shopIds: ref.read(shopIdsProvider).toList(),
                        );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                Expanded(
                  child: Text(
                    cartItem.shopName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(context)
                        .bodyText
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                )
              ],
            ),
          ),
          Visibility(
            visible: checkMultivendor(),
            child: Gap(8.h),
          ),
          Visibility(
            visible: checkMultivendor(),
            child: Divider(
              height: 5.h,
              thickness: 2,
              color: colors(context).accentColor,
            ),
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: cartItem.cartProduct.length,
            itemBuilder: (context, index) => CartProductCard(
              product: cartItem.cartProduct[index],
              hasGift: cartItem.hasGift,
              increment: () async {
                if (!checkMultivendor()) {
                  await ref
                      .read(cartController.notifier)
                      .increment(productId: cartItem.cartProduct[index].id);
                  calculateCartSummery();
                } else {
                  await ref
                      .read(cartController.notifier)
                      .increment(productId: cartItem.cartProduct[index].id);
                  calculateCartSummery();
                }
              },
              decrement: () async {
                if (!checkMultivendor()) {
                  await ref
                      .read(cartController.notifier)
                      .decrement(productId: cartItem.cartProduct[index].id);
                  calculateCartSummery();
                } else {
                  await ref
                      .read(cartController.notifier)
                      .decrement(productId: cartItem.cartProduct[index].id);
                  calculateCartSummery();
                }
              },
            ),
          ),
          Gap(8.h),
          Visibility(
            visible: checkMultivendor(),
            child: _buildVoucherWidget(
              context: context,
              shopId: cartItem.shopId,
              shopName: cartItem.shopName,
            ),
          ),
          Visibility(visible: checkMultivendor(), child: Gap(8.h)),
          Visibility(
            visible: checkMultivendor(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                40,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  width: 3.w,
                  height: 2.h,
                  color: EcommerceAppColor.lightGray,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVoucherWidget({
    required BuildContext context,
    required int shopId,
    required String shopName,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          isScrollControlled: false,
          backgroundColor: GlobalFunction.getContainerColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
          ),
          context: context,
          builder: (context) {
            return VoucherBottomSheet(
              shopId: shopId,
              shopName: shopName,
            );
          },
        );
      },
      child: Row(
        children: [
          SvgPicture.asset(
            Assets.svg.ticket,
            height: 30.h,
            width: 30.w,
          ),
          Gap(10.w),
          Text(
            S.of(context).storeVoucher,
            style: AppTextStyle(context).bodyTextSmall,
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            size: 18.sp,
            color: colors(context).bodyTextSmallColor,
          )
        ],
      ),
    );
  }

  AppBar _buildAppBar(
      {required BuildContext context,
      required List<HiveCartModel> cartItems,
      required bool isRoot}) {
    return AppBar(
      elevation: 0,
      leading: !isRoot
          ? IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
            )
          : null,
      title: Text(
        S.of(context).myCart,
        style: AppTextStyle(context).appBarText,
      ),
      actions: [
        Visibility(
          visible: checkMultivendor(),
          child: Row(
            children: [
              Text(
                S.of(context).all,
                style: AppTextStyle(context).bodyText.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Checkbox(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
                activeColor: colors(context).primaryColor,
                value: ref.watch(shopIdsProvider).length ==
                    ref.watch(cartController).cartItems.length,
                onChanged: (v) {
                  ref.read(shopIdsProvider.notifier).toogleAllShopId();
                  ref.read(cartSummeryController.notifier).calculateCartSummery(
                        couponCode: promoCodeController.text,
                        shopIds: ref.read(shopIdsProvider).toList(),
                      );
                },
              ),
              Gap(8.w)
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCodeApplyWidget({required BuildContext context}) {
    return Container(
      color: GlobalFunction.getContainerColor(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 3,
            child: _buildPromoTextField(context: context),
          ),
          Gap(10.w),
          Material(
            color: EcommerceAppColor.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: promoCodeController.text.isEmpty
                  ? null
                  : () {
                      ref
                          .read(cartSummeryController.notifier)
                          .calculateCartSummery(
                            couponCode: promoCodeController.text.trim(),
                            shopIds: ref.read(shopIdsProvider).toList(),
                            showSnackbar: true,
                          );
                    },
              child: Container(
                height: 58.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      ref.watch(cartSummeryController)['applyCoupon']
                          ? S.of(context).applied
                          : S.of(context).apply,
                      style: AppTextStyle(context)
                          .subTitle
                          .copyWith(color: colors(context).primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoTextField({required BuildContext context}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: EcommerceAppColor.primary, // Color of the solid border
          width: 1.5,
        ),
        color: colors(context).accentColor, // Fill color
      ),
      child: FormBuilderTextField(
        // readOnly: ref.watch(cartSummeryController)['applyCoupon'],
        textAlign: TextAlign.start,
        name: 'promoCode',
        controller: promoCodeController,
        style: AppTextStyle(context).bodyText.copyWith(
              fontWeight: FontWeight.w600,
            ),
        cursorColor: colors(context).primaryColor,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16),
          alignLabelWithHint: true,
          hintText: S.of(context).promoCode,
          hintStyle: AppTextStyle(context).bodyText.copyWith(
                fontWeight: FontWeight.w700,
                color: colors(context).hintTextColor,
              ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(8.sp),
            child: SvgPicture.asset(
              colorFilter: ColorFilter.mode(
                  colors(context).primaryColor!, BlendMode.srcIn),
              Assets.svg.cuppon,
            ),
          ),
          floatingLabelStyle: AppTextStyle(context).bodyText.copyWith(
                fontWeight: FontWeight.w400,
                color: colors(context).primaryColor,
              ),
          filled: true,
          fillColor: colors(context).accentColor,
          errorStyle: AppTextStyle(context).bodyTextSmall.copyWith(
                fontWeight: FontWeight.w400,
                color: colors(context).errorColor,
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
      ),
    );
  }

  Widget _buildSummaryWidget({required BuildContext context}) {
    final allVatTaxes = ref.watch(cartSummeryController)['allVatTaxes'] as List;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: ShapeDecoration(
        color: GlobalFunction.getContainerColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).orderSummary,
            style: AppTextStyle(context).bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Gap(8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: ShapeDecoration(
              color: colors(context).accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(
                  context: context,
                  title: S.of(context).subTotal,
                  value: ref.watch(cartSummeryController)['totalAmount'],
                ),
                Gap(10.h),
                _buildSummaryRow(
                  context: context,
                  title: S.of(context).discount,
                  value: ref.watch(cartSummeryController)['discount'],
                  isDiscount: true,
                ),
                Gap(10.h),
                _buildSummaryRow(
                  context: context,
                  title: S.of(context).deliveryCharge,
                  value: ref.watch(cartSummeryController)['deliveryCharge'],
                ),
                Gap(10.h),
                Text(
                  S
                      .of(context)
                      .orderSummary
                      .replaceAll("Order", S.of(context).vatTax),
                  style: AppTextStyle(context).bodyText.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Gap(6.h),
                Column(
                    children: List.generate(allVatTaxes.length, (index) {
                  final tax = allVatTaxes[index];
                  return _buildSummaryRow(
                    context: context,
                    title: "${tax['name'] ?? ''} (${tax['percentage']}%)",
                    value: double.parse(tax['amount'].toString()),
                  );
                })),
                Gap(10.h),
                _buildSummaryRow(
                  isPayable: true,
                  context: context,
                  title: S.of(context).totalVatTaxAmount,
                  value: ref.watch(cartSummeryController)['orderTaxAmount'],
                ),
                Gap(10.h),
                const Divider(
                  thickness: 1,
                ),
                Gap(5.h),
                _buildSummaryRow(
                  context: context,
                  title: S.of(context).payableAmount,
                  value: ref.watch(cartSummeryController)['payableAmount'],
                  isPayable: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String title,
    required double value,
    required BuildContext context,
    bool isDiscount = false,
    bool isPayable = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyle(context).bodyText.copyWith(
              fontWeight: isPayable ? FontWeight.bold : FontWeight.w500),
        ),
        Text(
          "${isDiscount ? '-' : ''}${GlobalFunction.price(
            ref: ref,
            price: value.toString(),
          )}",
          style: AppTextStyle(context).bodyText.copyWith(
              fontWeight: isPayable ? FontWeight.bold : FontWeight.w500,
              color: isDiscount ? EcommerceAppColor.primary : null),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar({required BuildContext context}) {
    return ValueListenableBuilder(
        valueListenable: Hive.box(AppConstants.appSettingsBox).listenable(),
        builder: (context, box, _) {
          final isEmpty = ref.watch(cartController).cartItems.isEmpty;
          final totalAmount = GlobalFunction.price(
            ref: ref,
            price: ref
                .watch(cartSummeryController)['payableAmount']
                .toString(),
          );
          
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    // Price Section
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            S.of(context).totalAmount,
                            style: AppTextStyle(context).bodyTextSmall.copyWith(
                              fontSize: 12.sp,
                              color: colors(context).bodyTextColor!.withOpacity(0.7),
                            ),
                          ),
                          Gap(4.h),
                          Text(
                            totalAmount,
                            style: AppTextStyle(context).bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                              color: colors(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(12.w),
                    // Checkout Button
                    Expanded(
                      flex: 2,
                      child: AbsorbPointer(
                        absorbing: isEmpty,
                        child: InkWell(
                          onTap: () {
                            context.nav.pushNamed(
                              Routes.getCheckoutViewRouteName(
                                AppConstants.appServiceName,
                              ),
                              arguments: [
                                double.parse(
                                  _getPayableAmount(),
                                ),
                                promoCodeController.text.isNotEmpty
                                    ? promoCodeController.text.trim()
                                    : null,
                                null,
                              ],
                            );
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: isEmpty
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        colors(context).primaryColor!,
                                        colors(context).primaryColor!.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: isEmpty
                                  ? colors(context).bodyTextColor!.withOpacity(0.3)
                                  : null,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                                Gap(8.w),
                                Text(
                                  S.of(context).checkout,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget radioWidget({required bool isActive, void Function()? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 18.h,
        width: 18.w,
        padding: EdgeInsets.all(2.sp),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: EcommerceAppColor.primary,
            width: 2.2,
          ),
        ),
        child: isActive
            ? Container(
                height: 8.h,
                width: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EcommerceAppColor.primary,
                ),
              )
            : null,
      ),
    );
  }

  Widget get fullWidthPath {
    return DottedBorder(
      customPath: (size) {
        return Path()
          ..moveTo(0, 20)
          ..lineTo(size.width, 20);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(),
      ),
    );
  }

  String _getPayableAmount() {
    double payableAmount = 0.0;
    payableAmount = ref.watch(subTotalProvider.notifier).getSubTotal() != 0.0
        ? ref.watch(subTotalProvider.notifier).getSubTotal()! +
            ref.watch(subTotalProvider.notifier).getDeliveryCharge()!
        : 0.0;
    return payableAmount.toStringAsFixed(2);
  }

  bool checkMultivendor() {
    return ref
        .read(masterControllerProvider.notifier)
        .materModel
        .data
        .isMultiVendor;
  }
}
