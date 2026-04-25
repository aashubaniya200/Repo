import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:webpal_commerce/components/ecommerce/app_logo.dart';
import 'package:webpal_commerce/config/app_color.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/eCommerce/address/address_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/category/category_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/flash_sales/flash_sales_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/just_for_you/just_for_you_controller.dart';
import 'package:webpal_commerce/controllers/misc/misc_controller.dart';
import 'package:webpal_commerce/gen/assets.gen.dart';
import 'package:webpal_commerce/generated/l10n.dart';
import 'package:webpal_commerce/models/eCommerce/address/add_address.dart';
import 'package:webpal_commerce/models/eCommerce/category/category.dart';
import 'package:webpal_commerce/models/eCommerce/product/product.dart'
    as product;
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/services/common/hive_service_provider.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';
import 'package:webpal_commerce/views/eCommerce/categories/components/sub_categories_bottom_sheet.dart';
import 'package:webpal_commerce/views/eCommerce/checkout/components/address_modal_bottom_sheet.dart';
import 'package:webpal_commerce/views/eCommerce/home/components/category_card.dart';
import 'package:webpal_commerce/views/eCommerce/home/components/popular_product_card.dart';
import 'package:webpal_commerce/views/eCommerce/home/components/product_card.dart';
import 'package:webpal_commerce/views/eCommerce/products/layouts/product_details_layout.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../../../../components/ecommerce/custom_search_field.dart';
import '../../../../controllers/eCommerce/dashboard/dashboard_controller.dart';
import '../components/banner_widget.dart';

class EcommerceHomeViewLayout extends ConsumerStatefulWidget {
  const EcommerceHomeViewLayout({super.key});

  @override
  ConsumerState<EcommerceHomeViewLayout> createState() =>
      _EcommerceHomeViewLayoutState();
}

class _EcommerceHomeViewLayoutState
    extends ConsumerState<EcommerceHomeViewLayout> {
  final TextEditingController productSearchController = TextEditingController();
  PageController pageController = PageController();
  final ScrollController scrollController = ScrollController();

  final List<SubCategory> subCategories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(currentPageController.notifier).state;
      ref.read(flashSalesListControllerProvider.notifier).getFlashSalesList();
      
      // Check if user is logged in and fetch addresses
      ref.read(hiveServiceProvider).getAuthToken().then((token) {
        if (token != null) {
          // Check if default address exists
          ref.read(hiveServiceProvider).getDefaultAddress().then((address) {
            if (address == null) {
              // Fetch addresses if not available
              ref.read(addressControllerProvider.notifier).getAddress();
            }
          });
        }
      });
    });
    pageController.addListener(_pageListener);
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    pageController.removeListener(_pageListener);
    if (mounted) scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Check if we're past 80% of the scroll extent
    if (!scrollController.hasClients || 
        scrollController.position.maxScrollExtent == 0) {
      return; // Not ready yet
    }
    
    final scrollPercentage = scrollController.position.pixels / 
                             scrollController.position.maxScrollExtent;
    
    if (scrollPercentage > 0.8) {
      // Load more when 80% scrolled
      final justForYouState = ref.read(justForYouControllerProvider);
      
      if (!justForYouState.isLoading && justForYouState.hasMore) {
        ref.read(justForYouControllerProvider.notifier).loadMoreProducts();
      }
    }
  }

  void _pageListener() {
    int? newPage = pageController.page?.round();
    if (newPage != null && newPage != ref.read(currentPageController)) {
      setState(() {
        ref.read(currentPageController.notifier).state = newPage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWrapperWidget(
      isLoading: ref.watch(subCategoryControllerProvider),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: AppBar(
            surfaceTintColor: GlobalFunction.getContainerColor(),
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
        ),
        body: NestedScrollView(
          controller: scrollController,
          headerSliverBuilder: (context, value) {
            return [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildAppBarWidget(context),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                floating: true,
                delegate: _SliverAppBarDelegate(
                  child: GestureDetector(
                    onTap: () => context.nav.pushNamed(
                      Routes.getProductsViewRouteName(
                          AppConstants.appServiceName),
                      arguments: [
                        null,
                        'All Product',
                        null,
                        null,
                        null,
                        subCategories,
                      ],
                    ),
                    child: Container(
                      decoration: _buildContainerDecoration(context),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: AbsorbPointer(
                        absorbing: true,
                        child: CustomSearchField(
                          name: 'product_search',
                          hintText: S.of(context).searchProduct,
                          textInputType: TextInputType.text,
                          controller: productSearchController,
                          widget: Container(
                            margin: EdgeInsets.all(10.sp),
                            child: SvgPicture.asset(Assets.svg.searchHome),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ];
          },
          body: ref.watch(dashboardControllerProvider).when(
                data: (dashboardData) => RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(dashboardControllerProvider).value;
                    ref
                        .refresh(flashSalesListControllerProvider.notifier)
                        .stream;
                  },
                  child: AnimationLimiter(
                    child: SingleChildScrollView(
                      child: Column(
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.h,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            Gap(20.h),
                            BannerWidget(dashboardData: dashboardData),
                            Gap(20.h),
                            _buildCategoriesWidget(
                                context, dashboardData.categories),
                            Gap(10.h),
                            DealOfTheDayWidget(),
                            _buildScrollingContainers(),
                            _buildPopularProductWidget(
                                context, dashboardData.popularProducts),
                            Gap(10.h),
                            _buildBeautyProductWidget(
                                dashboardData: dashboardData),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Text(error.toString(),
                      style: AppTextStyle(context).subTitle),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
        ),
      ),
    );
  }

  Widget _buildBeautyProductWidget(
      {required dashboardData}) {
    final justForYouState = ref.watch(justForYouControllerProvider);
    
    // Initialize products if not already initialized
    if (!justForYouState.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(justForYouControllerProvider.notifier).initializeProducts(
          dashboardData.justForYou.products,
          dashboardData.justForYou.total,
        );
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.w, top: 20.h),
          child: Text(
            S.of(context).justForYou,
            style: AppTextStyle(context).subTitle,
          ),
        ),
        GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h)
              .copyWith(top: 10.h, bottom: justForYouState.isLoading ? 60.h : 20.h),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _calculateCrossAxisCount(context),
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 0.66,
          ),
          itemCount: justForYouState.products.length,
          itemBuilder: (context, index) => ProductCard(
            product: justForYouState.products[index],
            onTap: () => context.nav.pushNamed(
              Routes.getProductDetailsRouteName(AppConstants.appServiceName),
              arguments: justForYouState.products[index].id,
            ),
          ),
        ),
        // Loading indicator for pagination
        if (justForYouState.isLoading)
          Padding(
            padding: EdgeInsets.only(bottom: 20.h),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        // End of list indicator
        if (!justForYouState.hasMore && justForYouState.products.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Center(
              child: Text(
                'No more products',
                style: AppTextStyle(context).bodyTextSmall.copyWith(
                      color: colors(context).bodyTextSmallColor?.withOpacity(0.6),
                    ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoriesWidget(
      BuildContext context, List<Category> categories) {
    final displayCategories = categories.take(8).toList();
    
    return Column(
      children: [
        _buildSectionHeader(context, S.of(context).categories,
            Routes.getCategoriesViewRouteName(AppConstants.appServiceName)),
        Gap(10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              return CategoryCard(
                category: category,
                onTap: () {
                  if (category.subCategories.isNotEmpty) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          topRight: Radius.circular(24.r),
                        ),
                      ),
                      builder: (context) => SubCategoriesBottomSheet(
                        category: category,
                      ),
                    );
                  } else {
                    GlobalFunction.navigatorKey.currentContext!.nav.pushNamed(
                      Routes.getProductsViewRouteName(
                        AppConstants.appServiceName,
                      ),
                      arguments: [
                        category.id,
                        category.name,
                        null,
                        null,
                        null,
                        category.subCategories,
                      ],
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularProductWidget(
      BuildContext context, List<product.Product> products) {
    return Container(
      decoration: BoxDecoration(color: colors(context).accentColor),
      child: Column(
        children: [
          _buildSectionHeader(context, S.of(context).popularProducts,
              Routes.getProductsViewRouteName(AppConstants.appServiceName),
              arguments: [
                null,
                'Popular',
                'popular',
                null,
                null,
                subCategories
              ]),
          SizedBox(
            height: MediaQuery.of(context).size.height / 2.8,
            child: ListView.builder(
              padding: EdgeInsets.only(left: 16.w),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) => PopularProductCard(
                product: products[index],
                onTap: () => context.nav.pushNamed(
                  Routes.getProductDetailsRouteName(
                      AppConstants.appServiceName),
                  arguments: products[index].id,
                ),
              ),
            ),
          ),
          Gap(20.h),
        ],
      ),
    );
  }

  Widget _buildAppBarWidget(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box(AppConstants.userBox).listenable(),
      builder: (context, userBox, _) {
        return Container(
          color: GlobalFunction.getContainerColor(),
          padding:
              EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ref.read(hiveServiceProvider).userIsLoggedIn()
                  ? GestureDetector(
                      onTap: () => showModalBottomSheet(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            topRight: Radius.circular(16.r),
                          ),
                        ),
                        barrierColor:
                            colors(context).accentColor!.withOpacity(0.8),
                        context: context,
                        builder: (_) => const AddressModalBottomSheet(),
                      ),
                      child: _buildHeaderRow(context),
                    )
                  : const AppLogo(isAnimation: true, centerAlign: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String route,
      {List<dynamic>? arguments}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h).copyWith(right: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyle(context).buttonText),
          TextButton(
            onPressed: () => context.nav.pushNamed(route, arguments: arguments),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context).viewMore,
                    style: AppTextStyle(context)
                        .bodyText
                        .copyWith(color: colors(context).primaryColor)),
                Gap(3.w),
                SvgPicture.asset(
                  Assets.svg.arrowRight,
                  colorFilter: ColorFilter.mode(
                      colors(context).primaryColor!, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Decoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      boxShadow: [
        BoxShadow(
          color: colors(context).accentColor ?? EcommerceAppColor.offWhite,
          blurRadius: 20,
          spreadRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLeftRow(context),
        Icon(Icons.expand_more, color: colors(context).hintTextColor),
      ],
    );
  }

  Widget _buildLeftRow(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          const AppLogo(withAppName: false, isAnimation: true),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12.sp,
                      color: colors(context).primaryColor,
                    ),
                    Gap(4.w),
                    Text(
                      'Delivering in 20 min',
                      style: AppTextStyle(context).bodyTextSmall.copyWith(
                        color: colors(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                Gap(4.h),
                // Default address
                ValueListenableBuilder(
                  valueListenable: Hive.box(AppConstants.userBox).listenable(),
                  builder: (context, box, _) {
                    final addressData =
                        box.get(AppConstants.defaultAddress);
                    debugPrint(
                        "📍 Retrieved addressData: $addressData, Type: ${addressData.runtimeType}");

                    final formattedAddress = _defaultAddress(context, addressData);
                    
                    return Text(
                      formattedAddress.isNotEmpty
                          ? formattedAddress
                          : "No address selected",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: AppTextStyle(context)
                          .bodyText
                          .copyWith(fontSize: 11.sp, fontWeight: FontWeight.w600),
                    );
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _defaultAddress(BuildContext context, dynamic data) {
    if (data == null) {
      return '';
    }
    
    if (data is String && data.isEmpty) {
      return '';
    }

    try {
      List<String> parts = [];
      
      // Handle Map (both DefaultAddressModel and AddAddress store as Map in Hive)
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        
        // Extract fields from map (works for both models)
        final flatNo = mapData['flat_no'] as String?;
        final addressLine = mapData['address_line'] as String?;
        final addressLine2 = mapData['address_line2'] as String?;
        final area = mapData['area'] as String?;
        final postCode = mapData['post_code'] as String?;
        
        if (flatNo?.isNotEmpty == true) {
          parts.add(flatNo!);
        }
        
        if (addressLine?.isNotEmpty == true) {
          parts.add(addressLine!);
        }
        
        if (addressLine2?.isNotEmpty == true) {
          parts.add(addressLine2!);
        }
        
        if (area?.isNotEmpty == true) {
          parts.add(area!);
        }
        
        if (postCode?.isNotEmpty == true) {
          parts.add(postCode!);
        }
        
      } else if (data is AddAddress) {
        if (data.flatNo?.isNotEmpty == true) {
          parts.add(data.flatNo!);
        }
        if (data.addressLine.isNotEmpty) {
          parts.add(data.addressLine);
        }
        if (data.addressLine2?.isNotEmpty == true) {
          parts.add(data.addressLine2!);
        }
        if (data.area?.isNotEmpty == true) {
          parts.add(data.area!);
        }
        if (data.postCode?.isNotEmpty == true) {
          parts.add(data.postCode!);
        }
        
      } else if (data is DefaultAddressModel) {
        if (data.flatNo?.isNotEmpty == true) {
          parts.add(data.flatNo!);
        }
        if (data.addressLine.isNotEmpty) {
          parts.add(data.addressLine);
        }
        if (data.addressLine2.isNotEmpty) {
          parts.add(data.addressLine2);
        }
        if (data.area?.isNotEmpty == true) {
          parts.add(data.area!);
        }
        if (data.postCode?.isNotEmpty == true) {
          parts.add(data.postCode!);
        }
        
      } else {
        return '';
      }

      String formattedAddress = parts.join(", ");
      return formattedAddress;
      
    } catch (e) {
      return '';
    }
  }
}

int _calculateCrossAxisCount(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  return screenWidth > 600 ? 3 : 2;
}

class DealOfTheDayWidget extends ConsumerWidget {
  final bool showViewMore;
  const DealOfTheDayWidget({
    super.key,
    this.showViewMore = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime? endDate;
    final runningSaleData =
        ref.watch(flashSalesListControllerProvider.notifier).runningFlashSale;
    if (runningSaleData != null) {
      endDate = DateTime.parse(runningSaleData.endDate ?? "");
    }

    return runningSaleData != null
        ? Container(
            margin: EdgeInsets.all(showViewMore ? 10.w : 0.w),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                gradient: LinearGradient(colors: [
                  const Color(0xFFB822FF),
                  EcommerceAppColor.primary,
                ])),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        runningSaleData.name ?? "",
                        style: AppTextStyle(context)
                            .subTitle
                            .copyWith(color: EcommerceAppColor.white),
                      ),
                      Gap(10.h),
                      Row(
                        children: [
                          Text(
                            S.of(context).endingIn,
                            style: AppTextStyle(context).bodyText.copyWith(
                                fontSize: 16.sp,
                                color: EcommerceAppColor.white),
                          ),
                          Gap(10.w),
                          if (endDate != null)
                            SlideCountdownSeparated(
                              separatorStyle: AppTextStyle(context)
                                  .bodyText
                                  .copyWith(color: FoodAppColor.white),
                              style: AppTextStyle(context).title.copyWith(
                                  color: FoodAppColor.carrotOrange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4.r),
                                  color: EcommerceAppColor.white),
                              duration: endDate.isAfter(DateTime.now())
                                  ? endDate.difference(DateTime.now())
                                  : Duration.zero,
                            ),
                        ],
                      )
                    ],
                  ),
                  if (showViewMore)
                    _buildViewMoreButton(
                      context,
                      ref,
                      runningSaleData.id,
                      runningSaleData.name ?? "",
                    ),
                ],
              ),
            ),
          )
        : SizedBox.shrink();
  }

  Widget _buildViewMoreButton(
      BuildContext context, WidgetRef ref, id, String title) {
    return OutlinedButton(
      onPressed: () {
        ref
            .read(flashSaleDetailsControllerProvider.notifier)
            .getFlashSalesDetails(id: id);
        context.nav.pushNamed(Routes.flashSaleDetails, arguments: title);
      },
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        side: const BorderSide(color: EcommerceAppColor.white, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context).viewMore,
            style: AppTextStyle(context)
                .bodyTextSmall
                .copyWith(color: colors(context).light),
          ),
          Gap(3.w),
          SvgPicture.asset(
            Assets.svg.arrowRight,
            colorFilter:
                ColorFilter.mode(colors(context).light!, BlendMode.srcIn),
          )
        ],
      ),
    );
  }
}

Widget _buildScrollingContainers() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    child: Row(
      children: List.generate(
        60,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 2.h,
          width: 5.w,
          color: EcommerceAppColor.lightGray.withOpacity(0.5),
        ),
      ),
    ),
  );
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => 60.h;

  @override
  double get minExtent => 60.h;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
