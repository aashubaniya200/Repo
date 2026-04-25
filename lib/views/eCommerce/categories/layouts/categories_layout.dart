import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webpal_commerce/config/app_color.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/eCommerce/category/category_controller.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';
import 'package:webpal_commerce/utils/responsive_helper.dart';
import 'package:webpal_commerce/views/eCommerce/categories/components/sub_categories_bottom_sheet.dart';
import 'package:webpal_commerce/views/eCommerce/products/layouts/product_details_layout.dart';

class EcommerceCategoriesLayout extends ConsumerWidget {
  const EcommerceCategoriesLayout({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isDark =
        Theme.of(context).scaffoldBackgroundColor == EcommerceAppColor.black;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force close any stuck loading dialogs
      try {
        GlobalFunction.hideLoading();
        final rootContext = GlobalFunction.navigatorKey.currentState?.context;
        if (rootContext != null && Navigator.of(rootContext, rootNavigator: true).canPop()) {
          Navigator.of(rootContext, rootNavigator: true).popUntil((route) => route is! DialogRoute);
        }
      } catch (e) {
        debugPrint('Cleanup dialogs error: $e');
      }
    });
    return LoadingWrapperWidget(
      isLoading: ref.watch(subCategoryControllerProvider),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Categories',
            style: AppTextStyle(context).title.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24.sp,
            ),
          ),
          centerTitle: false,
          toolbarHeight: 70.h,
          elevation: 0,
          backgroundColor: isDark ? EcommerceAppColor.black : colors(context).light,
        ),
        backgroundColor:
            isDark ? EcommerceAppColor.black : colors(context).accentColor,
        body: Consumer(
          builder: (context, ref, _) {
            final asyncValue = ref.watch(categoryControllerProvider);
            return asyncValue.when(
              data: (categoryList) => AnimationLimiter(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(categoryControllerProvider).value;
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 16.h,
                      crossAxisSpacing: 16.w,
                      childAspectRatio: 0.85,
                      // Responsive columns: 3 on mobile, 4 on tablet, 6 on desktop
                      crossAxisCount: ResponsiveHelper.getGridColumns(
                        context,
                        mobile: 3,
                        tablet: 4,
                        desktop: 6,
                      ),
                    ),
                    itemCount: categoryList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final category = categoryList[index];
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        columnCount: ResponsiveHelper.getGridColumns(
                          context,
                          mobile: 3,
                          tablet: 4,
                          desktop: 6,
                        ),
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: InkWell(
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
                                    builder: (context) =>
                                        SubCategoriesBottomSheet(
                                      category: category,
                                    ),
                                  );
                                } else {
                                  GlobalFunction.navigatorKey.currentContext!.nav
                                      .pushNamed(
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
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? colors(context).dark 
                                      : colors(context).light,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 8.h,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Image container
                                    Container(
                                      height: 56.w,
                                      width: 56.w,
                                      decoration: BoxDecoration(
                                        color: colors(context).primaryColor!.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12.r),
                                        child: CachedNetworkImage(
                                          imageUrl: category.thumbnail,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                colors(context).primaryColor!,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                            Icons.category_rounded,
                                            size: 35.sp,
                                            color: colors(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    // Category name
                                    Text(
                                      category.name,
                                      style: AppTextStyle(context).bodyText.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.sp,
                                      ),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Subcategory count badge
                                    if (category.subCategories.isNotEmpty) ...[
                                      SizedBox(height: 3.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors(context).primaryColor!.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Text(
                                          '${category.subCategories.length} items',
                                          style: AppTextStyle(context).bodyTextSmall.copyWith(
                                            fontSize: 9.sp,
                                            color: colors(context).primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.sp,
                      color: EcommerceAppColor.red,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Oops! Something went wrong',
                      style: AppTextStyle(context).bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Text(
                        error.toString(),
                        style: AppTextStyle(context).bodyTextSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors(context).primaryColor!,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
