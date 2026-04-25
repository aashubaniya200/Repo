import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive helper for handling different screen sizes (mobile, tablet, desktop)
class ResponsiveHelper {
  // Breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  
  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }
  
  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }
  
  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }
  
  /// Get responsive width for mobile/tablet/desktop
  static double getResponsiveWidth(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return (desktop ?? tablet ?? mobile).w;
    } else if (isTablet(context)) {
      return (tablet ?? mobile).w;
    }
    return mobile.w;
  }
  
  /// Get responsive height for mobile/tablet/desktop
  static double getResponsiveHeight(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return (desktop ?? tablet ?? mobile).h;
    } else if (isTablet(context)) {
      return (tablet ?? mobile).h;
    }
    return mobile.h;
  }
  
  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return (desktop ?? tablet ?? (mobile * 0.8)).sp;
    } else if (isTablet(context)) {
      return (tablet ?? (mobile * 0.85)).sp;
    }
    return mobile.sp;
  }
  
  /// Get optimized font size for any screen (automatically scales down on larger screens)
  static double getOptimizedFontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) {
      return (baseSize * 0.8).sp; // 20% smaller on desktop
    } else if (isTablet(context)) {
      return (baseSize * 0.85).sp; // 15% smaller on tablet
    }
    return baseSize.sp;
  }
  
  /// Get max content width for centering content on larger screens
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200;
    } else if (isTablet(context)) {
      return 800;
    }
    return MediaQuery.of(context).size.width;
  }
  
  /// Get number of columns for grid based on screen size
  static int getGridColumns(BuildContext context, {
    int mobile = 2,
    int? tablet,
    int? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
  
  /// Get cross axis spacing for grid based on screen size
  static double getGridSpacing(BuildContext context) {
    if (isDesktop(context)) {
      return 20.w;
    } else if (isTablet(context)) {
      return 16.w;
    }
    return 12.w;
  }
  
  /// Get padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h);
    }
    return EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h);
  }
  
  /// Wrap content with max width constraint for larger screens
  static Widget centerContent(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
  
  /// Get device type as string
  static String getDeviceType(BuildContext context) {
    if (isDesktop(context)) return 'desktop';
    if (isTablet(context)) return 'tablet';
    return 'mobile';
  }
  
  /// Get responsive value based on device type
  static T getResponsiveValue<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}
