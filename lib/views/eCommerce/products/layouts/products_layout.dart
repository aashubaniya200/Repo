import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:webpal_commerce/components/ecommerce/custom_cart.dart';
import 'package:webpal_commerce/components/ecommerce/custom_search_field.dart';
import 'package:webpal_commerce/components/ecommerce/product_not_found.dart';
import 'package:webpal_commerce/config/app_color.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/eCommerce/cart/cart_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/product/product_controller.dart';
import 'package:webpal_commerce/gen/assets.gen.dart';
import 'package:webpal_commerce/generated/l10n.dart';
import 'package:webpal_commerce/models/eCommerce/category/category.dart';
import 'package:webpal_commerce/models/eCommerce/common/product_filter_model.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';
import 'package:webpal_commerce/utils/responsive_helper.dart';
import 'package:webpal_commerce/views/eCommerce/products/components/filter_modal_bottom_sheet.dart';
import 'package:webpal_commerce/views/eCommerce/products/components/list_product_card_with_quantity.dart';

class EcommerceProductsLayout extends ConsumerStatefulWidget {
  final int? categoryId;
  final String? sortType;
  final String categoryName;
  final int? subCategoryId;
  final String? shopName;
  final List<SubCategory>? subCategories;

  const EcommerceProductsLayout({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.sortType,
    this.subCategoryId,
    this.shopName,
    this.subCategories,
  });

  @override
  ConsumerState<EcommerceProductsLayout> createState() =>
      _EcommerceProductsLayoutState();
}

class _EcommerceProductsLayoutState
    extends ConsumerState<EcommerceProductsLayout> with TickerProviderStateMixin {
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  bool isHeaderVisible = true;
  int page = 1;
  int perPage = 20;
  List<FilterCategory> filterCategoryList = [
    FilterCategory(id: 0, name: 'All')
  ];
  double scrollPossition = 0.0;
  bool isLastPosition = false;
  
  // Animation controllers for cart button
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  int _previousCartItemCount = 0;
  
  // Scroll tracking for cart button visibility
  bool _isCartButtonVisible = true;
  double _lastScrollOffset = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force close any stuck loading dialogs from previous screens
      try {
        GlobalFunction.hideLoading();
        // Also try to close any dialog routes on root navigator
        final rootContext = GlobalFunction.navigatorKey.currentState?.context;
        if (rootContext != null && Navigator.of(rootContext, rootNavigator: true).canPop()) {
          Navigator.of(rootContext, rootNavigator: true).popUntil((route) => route is! DialogRoute);
        }
      } catch (e) {
        // Silent error handling
      }
      
      ref.watch(productControllerProvider.notifier).products.clear();
      _setselectedSubCategory(id: widget.subCategoryId ?? 0).then((_) {
        _fetchProducts(isPagination: false);
      });
    });
    _setSubCotegory(subCategories: widget.subCategories ?? []);

    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final currentScrollOffset = scrollController.offset;
    
    // Show/hide cart button based on scroll direction
    if (currentScrollOffset > _lastScrollOffset && currentScrollOffset > 100) {
      // Scrolling down - hide button
      if (_isCartButtonVisible) {
        setState(() {
          _isCartButtonVisible = false;
        });
      }
    } else if (currentScrollOffset < _lastScrollOffset) {
      // Scrolling up - show button
      if (!_isCartButtonVisible) {
        setState(() {
          _isCartButtonVisible = true;
        });
      }
    }
    
    _lastScrollOffset = currentScrollOffset;
    
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      setState(() {
        isLastPosition = true;
        scrollPossition = scrollController.position.pixels;
      });
      _fetchMoreProducts();
    }
  }

  void _fetchProducts({required bool isPagination}) {
    ref.read(productControllerProvider.notifier).getCategoryWiseProducts(
          productFilterModel: ProductFilterModel(
            categoryId: widget.categoryId,
            page: page,
            perPage: perPage,
            search: searchController.text,
            sortType: widget.sortType,
            subCategoryId: ref.watch(selectedSubCategory) != 0
                ? ref.watch(selectedSubCategory)
                : null,
          ),
          isPagination: isPagination,
        );
  }

  void _fetchMoreProducts() {
    final productNotifier = ref.read(productControllerProvider.notifier);
    if (productNotifier.products.length < productNotifier.total! &&
        !ref.watch(productControllerProvider)) {
      page++;
      _fetchProducts(isPagination: true);
    }
  }

  void _setSubCotegory({required List<SubCategory> subCategories}) {
    for (SubCategory category in subCategories) {
      filterCategoryList.add(
        FilterCategory(id: category.id, name: category.name),
      );
    }
  }

  Future<void> _setselectedSubCategory({required int id}) {
    ref.read(selectedSubCategory.notifier).state = id;
    return Future.value();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Track cart count changes and trigger animation
    final cartState = ref.watch(cartController);
    int currentCartItemCount = 0;
    for (var shopCart in cartState.cartItems) {
      for (var product in shopCart.cartProduct) {
        currentCartItemCount += product.quantity;
      }
    }
    
    // Trigger animation when cart count increases
    if (currentCartItemCount > _previousCartItemCount) {
      Future.microtask(() {
        _scaleController.forward().then((_) => _scaleController.reverse());
        _bounceController.forward().then((_) => _bounceController.reverse());
      });
    }
    _previousCartItemCount = currentCartItemCount;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: GlobalFunction.getContainerColor()));
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor ==
              const Color.fromARGB(255, 1, 1, 2)
          ? colors(context).dark
          : colors(context).accentColor,
      body: SafeArea(
        child: Stack(
          children: [
            NestedScrollView(
              floatHeaderSlivers: false,
              physics: NeverScrollableScrollPhysics(),
              headerSliverBuilder: (context, value) {
                return [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _customHeaderAppBarWidget(),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      maxExtentS: (widget.subCategories?.isNotEmpty ?? false) ? 110.h : 60.h,
                      child: _buildFilterRow(context),
                    ),
                  )
                ];
              },
              body: Row(
                children: [
                  // Left Sidebar with categories - responsive width
                  if (widget.subCategories != null && widget.subCategories!.isNotEmpty)
                    _buildCategorySidebar(context),
                  // Main content - Product list
                  Expanded(
                    child: _buildProductsWidget(context),
                  ),
                ],
              ),
            ),
            // Sticky cart button
            _buildStickyCartButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _customHeaderAppBarWidget() {
    return _buildHeaderRow(context);
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 16.w, bottom: 20.h),
      color: GlobalFunction.getContainerColor(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLeftRow(context),
          _buildRightRow(context),
        ],
      ),
    );
  }

  Widget _buildLeftRow(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => context.nav.pop(context),
            icon: Icon(Icons.arrow_back, size: 26.sp),
          ),
          Gap(16.w),
          Expanded(
            child: Text(
              widget.shopName ?? widget.categoryName,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(context).subTitle,
            ),
          ),
          Gap(4.w),
        ],
      ),
    );
  }

  Widget _buildRightRow(BuildContext context) {
    return Row(
      children: [
        CustomCartWidget(context: context),
        Gap(16.w),
        GestureDetector(
          onTap: () => _showFilterModal(context),
          child: SvgPicture.asset(Assets.svg.filter, width: 46.sp),
        ),
      ],
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: GlobalFunction.getContainerColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      context: context,
      builder: (_) => FilterModalBottomSheet(
        productFilterModel: ProductFilterModel(
          page: 1,
          perPage: 20,
          categoryId: widget.categoryId,
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      color: GlobalFunction.getContainerColor(),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                flex: 5,
                fit: FlexFit.tight,
                child: CustomSearchField(
                  name: 'searchProduct',
                  hintText: S.of(context).searchProduct,
                  textInputType: TextInputType.text,
                  controller: searchController,
                  onChanged: (value) {
                    page = 1;
                    _fetchProducts(isPagination: false);
                  },
                  widget: Container(
                    margin: EdgeInsets.all(10.sp),
                    child: SvgPicture.asset(Assets.svg.searchHome),
                  ),
                ),
              ),
            ],
          ),
          Gap(8.h),
          Visibility(
              visible: widget.sortType != null,
              child: Divider(
                  color: colors(context).accentColor, height: 2, thickness: 2)),
          Visibility(
            visible:
                widget.sortType == null && (widget.subCategories?.isNotEmpty ?? false),
            child: _buildFilterListWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterListWidget() {
    return Consumer(builder: (context, ref, _) {
      return Container(
        margin: EdgeInsets.only(top: 8.h),
        height: 35.h,
        color: GlobalFunction.getContainerColor(),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filterCategoryList.length,
          itemBuilder: (context, index) {
            final isSelected =
                ref.watch(selectedSubCategory) == filterCategoryList[index].id;

            return GestureDetector(
              onTap: () {
                if (searchController.text.isNotEmpty) {
                  searchController.clear();
                }
                page = 1;
                if (ref.watch(selectedSubCategory.notifier).state !=
                    filterCategoryList[index].id) {
                  _setselectedSubCategory(id: filterCategoryList[index].id!)
                      .then((_) {
                    _fetchProducts(isPagination: false);
                  });
                }
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 5.w),
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                      color: isSelected
                          ? colors(context).primaryColor!
                          : colors(context).accentColor!),
                ),
                child: Center(
                  child: Text(filterCategoryList[index].name,
                      style: AppTextStyle(context).bodyTextSmall),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildCategorySidebar(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        // Simple responsive sidebar width with direct screen size check
        double sidebarWidth = 80.w;
        try {
          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth >= 1024) {
            sidebarWidth = 150.w; // Desktop
          } else if (screenWidth >= 600) {
            sidebarWidth = 120.w; // Tablet
          } else {
            sidebarWidth = 80.w; // Mobile
          }
        } catch (e) {
          sidebarWidth = 80.w; // Fallback to mobile width
        }
        
        return Container(
          width: sidebarWidth,
          color: GlobalFunction.getContainerColor(),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: (widget.subCategories?.length ?? 0) + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final subCategory = isAll
                        ? null
                        : widget.subCategories?[index - 1];
                    final categoryId = isAll ? 0 : (subCategory?.id ?? 0);
                    final isSelected =
                        ref.watch(selectedSubCategory) == categoryId;

                    return GestureDetector(
                      onTap: () {
                        if (searchController.text.isNotEmpty) {
                          searchController.clear();
                        }
                        page = 1;
                        _setselectedSubCategory(id: categoryId).then((_) {
                          _fetchProducts(isPagination: false);
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 8.w),
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors(context).primaryColor!.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isSelected
                                ? colors(context).primaryColor!
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAll)
                              Container(
                                width: 50.w,
                                height: 50.w,
                                decoration: BoxDecoration(
                                  color: colors(context)
                                      .primaryColor!
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.apps,
                                  size: 30.sp,
                                  color: colors(context).primaryColor,
                                ),
                              )
                            else
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: CachedNetworkImage(
                                  imageUrl: subCategory?.thumbnail ?? '',
                                  width: 50.w,
                                  height: 50.w,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: colors(context).accentColor,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: colors(context).accentColor,
                                    child: Icon(
                                      Icons.category,
                                      size: 24.sp,
                                    ),
                                  ),
                                ),
                              ),
                            Gap(6.h),
                            Text(
                              isAll ? 'All' : (subCategory?.name ?? 'Unknown'),
                              style: AppTextStyle(context)
                                  .bodyTextSmall
                                  .copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: ResponsiveHelper.getOptimizedFontSize(context, 11),
                                  ),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsWidget(BuildContext context) {
    final productController = ref.watch(productControllerProvider.notifier);
    final products = productController.products;

    if (ref.watch(productControllerProvider)) {
      return Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return const ProductNotFoundWidget();
    }

    return _buildListProductsWidget(context);
  }

  Widget _buildListProductsWidget(BuildContext context) {
    final products = ref.watch(productControllerProvider.notifier).products;
    
    // Safety check
    if (products.isEmpty) {
      return const ProductNotFoundWidget();
    }
    
    // Always use list view on all devices as requested
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      child: AnimationLimiter(
        child: _buildMobileListWidget(context, products),
      ),
    );
  }

  // Mobile list view (original layout)
  Widget _buildMobileListWidget(BuildContext context, List products) {
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: false,
        padding: EdgeInsets.only(top: 10.h, bottom: 100.h),
        itemCount: products.length,
        itemBuilder: (context, index) {
        if (isLastPosition && scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollController.jumpTo(scrollPossition);
            setState(() {
              isLastPosition = false;
            });
          });
        }
        final product = products[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: ListProductCardWithQuantity(
                product: product,
                onTap: () => context.nav.pushNamed(
                  Routes.getProductDetailsRouteName(
                      AppConstants.appServiceName),
                  arguments: product.id,
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }
  Widget _buildStickyCartButton(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartController);
    final cartItems = cartState.cartItems;
    
    if (cartItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate total items and price
    int totalItems = 0;
    double totalPrice = 0.0;
    
    for (var shopCart in cartItems) {
      for (var product in shopCart.cartProduct) {
        totalItems += product.quantity;
        totalPrice += product.discountPrice * product.quantity;
      }
    }

    // Get first 3 products for display across all shops
    final List<String> displayImageUrls = [];
    for (var shopCart in cartItems) {
      for (var product in shopCart.cartProduct) {
        if (displayImageUrls.length < 3) {
          displayImageUrls.add(product.thumbnail);
        }
      }
    }
    
    final hasMoreItems = totalItems > 3;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _isCartButtonVisible ? 20.h : -100.h,
      left: 20.w,
      right: 20.w,
      child: IgnorePointer(
        ignoring: !_isCartButtonVisible,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _bounceAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.translate(
                offset: Offset(0, -_bounceAnimation.value * 10),
                child: child,
              ),
            );
          },
          child: Align(
            alignment: Alignment.bottomCenter,
            child: IntrinsicWidth(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 200.w,
                  maxWidth: MediaQuery.of(context).size.width - 40.w,
                ),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(30.r),
                  shadowColor: colors(context).primaryColor!.withOpacity(0.4),
                  child: InkWell(
                    onTap: () {
                      context.nav.pushNamed(
                        Routes.getMyCartViewRouteName(AppConstants.appServiceName),
                        arguments: [false, false],
                      );
                    },
                    borderRadius: BorderRadius.circular(30.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors(context).primaryColor!,
                      colors(context).primaryColor!.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: colors(context).primaryColor!.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cart icon with badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.sp),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shopping_cart_rounded,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: EdgeInsets.all(4.sp),
                            decoration: const BoxDecoration(
                              color: EcommerceAppColor.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 20.sp,
                              minHeight: 20.sp,
                            ),
                            child: Center(
                              child: Text(
                                totalItems.toString(),
                                style: AppTextStyle(context)
                                    .bodyTextSmall
                                    .copyWith(
                                      color: Colors.white,
                                      fontSize: ResponsiveHelper.getOptimizedFontSize(context, 10),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(12.w),
                    // Product images stack
                    SizedBox(
                      width: (displayImageUrls.length * 30.0.w) + (hasMoreItems ? 40.w : 10.w),
                      height: 40.h,
                      child: Stack(
                        children: [
                            for (int i = 0; i < displayImageUrls.length; i++)
                              Positioned(
                                left: i * 30.0.w,
                                child: Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: displayImageUrls[i],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: colors(context).accentColor,
                                        child: Icon(
                                          Icons.shopping_bag,
                                          size: 20.sp,
                                          color: colors(context).primaryColor,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: colors(context).accentColor,
                                        child: Icon(
                                          Icons.shopping_bag,
                                          size: 20.sp,
                                          color: colors(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (hasMoreItems)
                              Positioned(
                                left: displayImageUrls.length * 30.0.w,
                                child: Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.3),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${totalItems - 3}',
                                      style: AppTextStyle(context)
                                          .bodyTextSmall
                                          .copyWith(
                                            color: Colors.white,
                                            fontSize: ResponsiveHelper.getOptimizedFontSize(context, 12),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ),
                    Gap(12.w),
                    // Price and checkout
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            return Text(
                              GlobalFunction.price(
                                ref: ref,
                                price: totalPrice.toStringAsFixed(2),
                              ),
                              style: AppTextStyle(context).bodyText.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveHelper.getOptimizedFontSize(context, 16),
                                  ),
                            );
                          },
                        ),
                        Text(
                          'View Cart',
                          style: AppTextStyle(context).bodyTextSmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: ResponsiveHelper.getOptimizedFontSize(context, 11),
                              ),
                        ),
                      ],
                    ),
                    Gap(8.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ],
                ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final selectedSubCategory = StateProvider<int>((value) => 0);
}

class FilterCategory {
  final int? id;
  final String name;

  FilterCategory({this.id, required this.name});
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.child,
    this.maxExtentS = 80.0,
  });

  final Widget child;
  final double maxExtentS;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxExtentS;

  @override
  double get minExtent => maxExtentS;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
