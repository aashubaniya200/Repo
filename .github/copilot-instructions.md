# InstantMart Flutter E-commerce App - AI Agent Instructions

## Project Overview
Multi-service e-commerce Flutter app supporting eCommerce, food delivery, grocery, and pharmacy modules. Package name: `webpal_commerce`. Uses Flutter 3.5+ with Riverpod state management, Dio for networking, and Hive for local storage.

## Architecture & Patterns

### State Management (Riverpod)
- Controllers in `lib/controllers/{eCommerce,food,grocery,pharmacy,common,misc}/` use StateNotifierProvider pattern
- Example: `dashboardControllerProvider` auto-fetches data on initialization
- Misc controllers (`lib/controllers/misc/misc_controller.dart`) hold UI state (selected indexes, obscure toggles, form states)
- Always use `ref.watch()` in build methods, `ref.read()` for callbacks

### Service Layer Architecture
Services follow Provider-Base pattern:
- Implementation: `lib/services/{eCommerce,common}/*/service_name.dart`
- Interface: `lib/services/base/{eCommerce,common}/service_name_base.dart`
- Services use `apiClientProvider` for HTTP calls (centralized in `utils/api_client.dart`)
- All API endpoints defined in `lib/config/app_constants.dart`

Example pattern:
```dart
class DashboardService implements DashboardProviderBase {
  final Ref ref;
  DashboardService(this.ref);
  
  Future<Response> getDashboardData() async {
    return await ref.read(apiClientProvider).get(AppConstants.getDashboardData);
  }
}
final dashboardServiceProvider = Provider((ref) => DashboardService(ref));
```

### API Client & Error Handling
- Centralized Dio client in `utils/api_client.dart` with interceptors in `utils/request_handler.dart`
- 401 responses auto-redirect to login, clearing Hive storage
- Error responses show snackbars via `GlobalFunction.showCustomSnackbar()`
- Pretty logging enabled for all API calls in debug mode

### Data Models
- Models in `lib/models/{eCommerce,food,grocery,pharmacy,common}/`
- Cart uses custom Hive adapter: `HiveCartModel` with manual TypeAdapter implementation (no @HiveType annotations)
- Models have `fromMap()`, `toMap()`, `fromJson()`, `toJson()` methods

### Local Storage (Hive)
Three main boxes initialized in `main.dart`:
- `appSettingsBox`: Theme, language, primary color, first open status
- `userBox`: User data, auth token
- `cartModelBox`: Shopping cart (typed box with HiveCartModel)

Access pattern: `Hive.box(AppConstants.boxName).get(AppConstants.key)`

### Navigation & Routing
- Named routes defined in `lib/routes.dart` as static constants
- Uses `page_transition` package for transitions
- Global navigator key: `GlobalFunction.navigatorKey`
- Route generator: `generatedRoutes()` function handles all route mappings

### UI Structure
Views follow View → Layout pattern:
- Views: `lib/views/{eCommerce,food,grocery,pharmacy,common}/feature_name/feature_view.dart`
- Layouts: Same directory, `layouts/feature_layout.dart` (contains actual UI)
- Separates route handling from UI implementation

### Multi-Service Architecture
App supports 4 service types (eCommerce, food, grocery, pharmacy):
- Separate dashboards: `lib/views/{serviceName}/dashboard/dashboard_view.dart`
- Shared common components: `lib/views/common/` (auth, splash, onboarding, support)
- Service-specific controllers and models organized by service type

## Development Workflows

### Code Generation
Two main commands (defined in `makefile`):
- `make builds` or `dart run build_runner build --delete-conflicting-outputs` - Generates `assets.gen.dart` and `fonts.gen.dart` (run after adding assets)
- `make languages` or `flutter pub run intl_utils:generate` - Generates localization files from `.arb` files in `lib/l10n/`

### Asset Management
- Auto-generated: Use `Assets.svg.iconName`, `Assets.png.imageName` from `lib/gen/assets.gen.dart`
- Never hardcode asset paths - always use generated Assets class
- Run code generation after adding new assets to `assets/svg/` or `assets/png/`

### Internationalization
- ARB files in `lib/l10n/` (en, ar, bn supported)
- Access via `S.of(context).keyName` (generated class)
- Run `make languages` after updating ARB files

### Firebase Integration
- Firebase Core, Messaging, and local notifications configured
- Background message handler: `firebaseMessagingBackgroundHandler` in `utils/notification_handler.dart`
- Firebase options auto-configured in `lib/firebase_options.dart`

### Building
- `make clean` - Clean and reinstall dependencies
- `make apk_build` - Build single APK
- `make split_apk_build` - Build split APKs per ABI

## Key Conventions

### Theming
- Dynamic theming via Hive: Primary color stored as hex string in `appSettingsBox`
- Dark mode toggle: `AppConstants.isDarkTheme` in Hive
- Theme defined in `lib/config/theme.dart` with `getAppTheme()`
- Status bar theme changes with `GlobalFunction.changeStatusBarTheme(isDark: bool)`

### Screen Sizing
- Uses `flutter_screenutil` with design size 390x844 (XD design reference)
- Always use `.w`, `.h`, `.sp`, `.r` extensions for responsive sizing
- Example: `fontSize: 16.sp`, `width: 100.w`, `height: 50.h`

### Component Organization
- Reusable widgets in `lib/components/ecommerce/` (no common components directory exists)
- Form builders use `flutter_form_builder` package
- Animations use `flutter_staggered_animations`

### Connectivity Handling
- App wrapped with `ConnectivityAppWrapper` in `main.dart`
- Handles online/offline states automatically

### Linting
- Uses `flutter_lints` with custom analysis options
- `use_build_context_synchronously` warning disabled project-wide
- Defined in `analysis_options.yaml`

## Critical Patterns

### Controller Initialization
Controllers often auto-fetch data on creation:
```dart
final dashboardControllerProvider = StateNotifierProvider((ref) {
  final controller = DashboardController(ref);
  controller.getDashboardData(); // Auto-fetch
  return controller;
});
```

### Shop-based Cart System
Cart is shop-segmented:
- `shopIdsProvider` tracks unique shop IDs in cart
- `subTotalProvider` calculates per-shop subtotals
- Checkout processes one shop at a time

### Payment Flow
- Web payment view: `views/eCommerce/checkout/layouts/web_payment_page.dart`
- Payment service: `lib/services/eCommerce/payment/payment_service.dart`
- Multiple payment methods supported (cash, card, online)

### Order System
- Order placement: `AppConstants.placeOrder` or `placeOrderV1`
- Buy Now: Separate endpoint `buyNowOrderPlace` for direct purchase
- Order tracking with status updates and return policy support

### Messaging System
- Real-time chat using `pusher_channels_flutter`
- Shop-specific messaging: `lib/views/eCommerce/my_message/` and `my_chat_view.dart`
- Message services in `lib/services/eCommerce/message/`

## When Making Changes

- **Adding new assets**: Run `make builds` after adding to assets folder
- **Updating translations**: Run `make languages` after editing `.arb` files  
- **Adding API endpoint**: Define in `app_constants.dart`, create service method, add to service provider
- **New feature**: Follow service → controller → view/layout pattern
- **State changes**: Use Riverpod providers, avoid StatefulWidget for business logic
- **Navigation**: Add route constant to `Routes` class, add case to `generatedRoutes()`
- **Local storage**: Use appropriate Hive box from `AppConstants`, wrap in ValueListenableBuilder for reactivity
