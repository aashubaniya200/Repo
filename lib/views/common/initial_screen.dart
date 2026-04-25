import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webpal_commerce/components/ecommerce/offline.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/controllers/common/master_controller.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/services/common/hive_service_provider.dart';
import 'package:webpal_commerce/utils/api_client.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen> {
  @override
  void initState() {
    super.initState();

    ConnectivityWrapper.instance.onStatusChange.listen((event) {
      if (event == ConnectivityStatus.CONNECTED) {
        // Load master data
        ref
            .read(masterControllerProvider.notifier)
            .getMasterData()
            .then((response) => {
                  if (response?.data.themeColors.primaryColor != null)
                    {
                      ref.read(hiveServiceProvider).setPrimaryColor(
                          color: response!.data.themeColors.primaryColor),
                    },
                  if (response?.data.appLogo != null)
                    {
                      ref
                          .read(hiveServiceProvider)
                          .setAppLogo(logo: response!.data.appLogo)
                    },
                  if (response?.data.appName != null)
                    {
                      ref
                          .read(hiveServiceProvider)
                          .setAppName(name: response!.data.appName)
                    },
                  if (response?.data.splashLogo != null)
                    {
                      ref
                          .read(hiveServiceProvider)
                          .setSplashLogo(splashLogo: response!.data.splashLogo),
                    }
                });
        
        // Check auth status and navigate
        Future.wait([
          ref.read(hiveServiceProvider).loadTokenAndUser(),
        ]).then((data) {
          if (data.first![0] == true &&
              (data.first![1] == null || data.first![2] == null)) {
            // First open is done, navigate to dashboard
            if (mounted) {
              context.nav.pushNamedAndRemoveUntil(
                Routes.getCoreRouteName(AppConstants.appServiceName),
                (route) => false,
              );
            }
          } else if ((data.first![1] != null) && (data.first![2] != null)) {
            // User is logged in
            ref.read(apiClientProvider).updateToken(token: data.first![1]);
            if (mounted) {
              context.nav.pushNamedAndRemoveUntil(
                Routes.getCoreRouteName(AppConstants.appServiceName),
                (route) => false,
              );
            }
          } else {
            // Skip onboarding, go directly to dashboard
            ref
                .read(hiveServiceProvider)
                .setFirstOpenValue(value: true);
            if (mounted) {
              context.nav.pushNamedAndRemoveUntil(
                Routes.getCoreRouteName(AppConstants.appServiceName),
                (route) => false,
              );
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWidgetWrapper(
      offlineWidget: const OfflineScreen(),
      child: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
