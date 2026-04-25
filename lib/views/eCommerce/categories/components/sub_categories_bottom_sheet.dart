import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/models/eCommerce/category/category.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';

class SubCategoriesBottomSheet extends ConsumerWidget {
  final Category category;
  final String? shopName;
  const SubCategoriesBottomSheet({
    super.key,
    required this.category,
    this.shopName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          
          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: colors(context).accentColor,
          ),
          
          // Subcategories Grid
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final SubCategory subCategory = category.subCategories[index];
                      return _buildSubCategoryCard(subCategory: subCategory);
                    },
                    itemCount: category.subCategories.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                  Gap(16.h),
                  _buildViewAllButton(context: context),
                  Gap(16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          // Category Icon
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: colors(context).primaryColor!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: category.thumbnail.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: CachedNetworkImage(
                      imageUrl: category.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Icon(
                        Icons.category_outlined,
                        color: colors(context).primaryColor,
                        size: 24.sp,
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.category_outlined,
                        color: colors(context).primaryColor,
                        size: 24.sp,
                      ),
                    ),
                  )
                : Icon(
                    Icons.category_outlined,
                    color: colors(context).primaryColor,
                    size: 24.sp,
                  ),
          ),
          Gap(12.w),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: AppTextStyle(context).subTitle.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gap(2.h),
                Text(
                  '${category.subCategories.length} subcategories',
                  style: AppTextStyle(context).bodyTextSmall.copyWith(
                    color: colors(context).bodyTextColor!.withOpacity(0.6),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          // Close Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryCard({required SubCategory subCategory}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            GlobalFunction.navigatorKey.currentContext!.nav.popAndPushNamed(
          Routes.getProductsViewRouteName(
            AppConstants.appServiceName,
          ),
          arguments: [
            category.id,
            category.name,
            null,
            subCategory.id,
            shopName,
            category.subCategories
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            color: colors(GlobalFunction.navigatorKey.currentContext!)
                .accentColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: colors(GlobalFunction.navigatorKey.currentContext!)
                  .primaryColor!
                  .withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors(GlobalFunction.navigatorKey.currentContext!)
                    .primaryColor!
                    .withOpacity(0.05),
                blurRadius: 8.r,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image Container
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: colors(GlobalFunction.navigatorKey.currentContext!)
                      .primaryColor!
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: subCategory.thumbnail,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Icon(
                        Icons.category,
                        size: 32.sp,
                        color: colors(context).primaryColor!.withOpacity(0.5),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.category,
                        size: 32.sp,
                        color: colors(GlobalFunction.navigatorKey.currentContext!)
                            .primaryColor!
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
              Gap(12.h),
              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  subCategory.name,
                  style: AppTextStyle(
                          GlobalFunction.navigatorKey.currentContext!)
                      .bodyText
                      .copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),              // Arrow indicator
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllButton({required BuildContext context}) {
    return Material(
      color: colors(context).primaryColor,
      borderRadius: BorderRadius.circular(14.r),
      elevation: 2,
      child: InkWell(
        onTap: () => context.nav.popAndPushNamed(
          Routes.getProductsViewRouteName(
            AppConstants.appServiceName,
          ),
          arguments: [
            category.id,
            category.name,
            null,
            null,
            shopName,
            category.subCategories
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              Gap(10.w),
              Text(
                'View All Products',
                style: AppTextStyle(context).bodyText.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
              Gap(8.w),
              Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
