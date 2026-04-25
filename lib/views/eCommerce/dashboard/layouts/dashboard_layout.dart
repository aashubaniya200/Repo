import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webpal_commerce/controllers/eCommerce/address/address_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/cart/cart_controller.dart';
import 'package:webpal_commerce/controllers/misc/misc_controller.dart';
import 'package:webpal_commerce/generated/l10n.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/services/common/hive_service_provider.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';
import 'package:webpal_commerce/views/eCommerce/dashboard/components/app_bottom_navbar.dart';
import 'package:webpal_commerce/views/eCommerce/favourites/favourites_products_view.dart';
import 'package:webpal_commerce/views/eCommerce/home/home_view.dart';
import 'package:webpal_commerce/views/eCommerce/more/more_view.dart';
import 'package:webpal_commerce/views/eCommerce/my_cart/my_cart_view.dart';

class EcommerceDashboardLayout extends ConsumerStatefulWidget {
  const EcommerceDashboardLayout({super.key});

  @override
  ConsumerState<EcommerceDashboardLayout> createState() =>
      _EcommerceDashboardLayoutState();
}

class _EcommerceDashboardLayoutState
    extends ConsumerState<EcommerceDashboardLayout> {
  @override
  void initState() {
    _init();
    super.initState();
  }

  void _init() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final token = await ref.read(hiveServiceProvider).getAuthToken();
      
      if (token != null) {
        // Fetch cart
        ref.read(cartController.notifier).getAllCarts();
        
        // Fetch addresses to ensure default address is available
        try {
          final result = await ref.read(addressControllerProvider.notifier).getAddress();
          
          if (result.isSuccess) {
            // Get the address list
            final addresses = ref.read(addressControllerProvider.notifier).addressList;
            
            // Verify default address was saved to Hive
            final savedAddress = await ref.read(hiveServiceProvider).getDefaultAddress();
            if (savedAddress == null) {
              // If we have addresses but none is default, save the first one as default
              if (addresses.isNotEmpty) {
                await ref.read(hiveServiceProvider).saveDefaultDeliveryAddress(address: addresses.first);
              }
            }
          }
        } catch (e) {
          // Silent error handling in production
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageController = ref.watch(bottomTabControllerProvider);

    return PopScope(
      canPop: true,
      onPopInvoked: (onPop) {
        if (ref.read(selectedTabIndexProvider) != 0) {
          ref.read(selectedTabIndexProvider.notifier).state = 0;
          pageController.jumpToPage(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        bottomNavigationBar: AppBottomNavbar(
            bottomItem: getBottomItems(context: context),
            onSelect: (index) {
              if (index != null) {
                if (index == 2 &&
                    !ref.read(hiveServiceProvider).userIsLoggedIn()) {
                  _warningDialog(ref: ref);
                } else {
                  pageController.jumpToPage(index);
                }
              }
            }),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: pageController,
          onPageChanged: (index) {
            ref.read(selectedTabIndexProvider.notifier).state = index;
          },
          children: const [
            EcommerceHomeView(),
            EcommerceMyCartView(
              isRoot: true,
              isBuyNow: false,
            ),
            FavouritesProductsView(),
            EcommerceMoreView()
          ],
        ),
      ),
    );
  }
}

void _warningDialog({required WidgetRef ref}) {
  ref.refresh(selectedTabIndexProvider.notifier).state;
  GlobalFunction.navigatorKey.currentContext!.nav
      .pushNamedAndRemoveUntil(Routes.login, (route) => false);
}

List<BottomItem> getBottomItems({required BuildContext context}) {
  return [
    BottomItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      name: S.of(context).home,
    ),
    BottomItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      name: S.of(context).myCart,
    ),
    BottomItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      name: S.of(context).favorites,
    ),
    BottomItem(
      icon: Icons.menu_outlined,
      activeIcon: Icons.menu,
      name: S.of(context).more,
    ),
  ];
}

class BottomItem {
  final IconData icon;
  final IconData activeIcon;
  final String name;
  BottomItem({
    required this.icon,
    required this.activeIcon,
    required this.name,
  });
}
