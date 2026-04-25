import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/utils/responsive_helper.dart';

class AppTextStyle {
  final BuildContext context;
  AppTextStyle(this.context);

  // Helper method to get responsive font size
  double _getResponsiveFontSize(double mobileSize) {
    // On tablets/desktop, use slightly smaller scale factor
    if (ResponsiveHelper.isTablet(context)) {
      return (mobileSize * 0.85).sp; // 15% smaller on tablets
    } else if (ResponsiveHelper.isDesktop(context)) {
      return (mobileSize * 0.8).sp; // 20% smaller on desktop
    }
    return mobileSize.sp;
  }

  TextStyle get title => TextStyle(
        color: colors(context).headingColor,
        fontSize: _getResponsiveFontSize(24),
        fontWeight: FontWeight.w500,
      );
  TextStyle get subTitle => TextStyle(
        color: colors(context).headingColor,
        fontSize: _getResponsiveFontSize(18),
        fontWeight: FontWeight.w700,
      );
  TextStyle get bodyText => TextStyle(
        color: colors(context).bodyTextColor,
        fontSize: _getResponsiveFontSize(14),
        fontWeight: FontWeight.w400,
      );
  TextStyle get bodyTextSmall => TextStyle(
        color: colors(context).bodyTextSmallColor,
        fontSize: _getResponsiveFontSize(12),
        fontWeight: FontWeight.w500,
      );
  TextStyle get buttonText => TextStyle(
        fontSize: _getResponsiveFontSize(16),
        fontWeight: FontWeight.w700,
      );
  TextStyle get hintText => TextStyle(
        color: colors(context).hintTextColor,
        fontSize: _getResponsiveFontSize(21),
        fontWeight: FontWeight.w300,
      );
  TextStyle get appBarText => TextStyle(
        color: colors(context).headingColor,
        fontSize: _getResponsiveFontSize(18),
        fontWeight: FontWeight.w700,
      );
}
