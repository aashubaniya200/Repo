import 'dart:io';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:webpal_commerce/config/app_color.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/firebase_options.dart';
import 'package:webpal_commerce/generated/l10n.dart';
import 'package:webpal_commerce/models/eCommerce/cart/hive_cart_model.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/utils/global_function.dart';
import 'package:webpal_commerce/utils/notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupFlutterNotifications();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  firebaseMessagingForgroundHandler();
  
  // FCM token only works on real devices, not simulators
  String? fcmToken;
  try {
    // Check if running on a physical device (not simulator/emulator)
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM Token: $fcmToken");
    } else {
      debugPrint("FCM Token: Skipped (running on simulator/emulator)");
    }
  } catch (e) {
    debugPrint("FCM Token Error (likely running on simulator): $e");
  }
  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: false,
  );

  await Hive.initFlutter();
  await Hive.openBox(AppConstants.appSettingsBox);
  await Hive.openBox(AppConstants.authBox);
  await Hive.openBox(AppConstants.userBox);
  Hive.registerAdapter(HiveCartModelAdapter());

  await Hive.openBox<HiveCartModel>(AppConstants.cartModelBox);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Locale resolveLocal({required String langCode}) {
    return Locale(langCode);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // XD Design Sizes (Mobile)
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      // Ensures proper scaling across different screen sizes including tablets
      ensureScreenSize: true,
      builder: (context, child) {
        return ValueListenableBuilder(
            valueListenable: Hive.box(AppConstants.appSettingsBox).listenable(),
            builder: (context, box, _) {
              final isDark = box.get(AppConstants.isDarkTheme,
                  defaultValue: false) as bool;
              final primaryColor = box.get(AppConstants.primaryColor);
              if (primaryColor != null) {
                EcommerceAppColor.primary = GlobalFunction.hexToColor(primaryColor);
              }
              GlobalFunction.changeStatusBarTheme(isDark: isDark);
              final appLocal = box.get(AppConstants.appLocal);
              return ConnectivityAppWrapper(
                app: MaterialApp(
                  showPerformanceOverlay: false,
                  debugShowCheckedModeBanner: false,
                  title: 'Instant Mart',
                  navigatorKey: GlobalFunction.navigatorKey,
                  locale: resolveLocal(langCode: appLocal ?? 'en'),
                  localizationsDelegates: const [
                    S.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: S.delegate.supportedLocales,
                  theme: getAppTheme(context: context, isDarkTheme: isDark),
                  onGenerateRoute: generatedRoutes,
                  initialRoute: Routes.initial,
                  // home: ConfirmOTPLayout(
                  //     arguments: ConfirmOTPScreenArguments(
                  //         phoneNumber: "01909121212",
                  //         isPasswordRecover: false)),
                ),
              );
            });
      },
    );
  }
}
