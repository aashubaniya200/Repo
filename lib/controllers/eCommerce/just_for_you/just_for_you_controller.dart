import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webpal_commerce/models/eCommerce/common/product_filter_model.dart';
import 'package:webpal_commerce/models/eCommerce/product/product.dart';
import 'package:webpal_commerce/services/eCommerce/product_service/product_service.dart';
import 'package:webpal_commerce/utils/request_handler.dart';

class JustForYouState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final bool isInitialized;

  JustForYouState({
    required this.products,
    required this.isLoading,
    required this.hasMore,
    required this.currentPage,
    this.error,
    this.isInitialized = false,
  });

  JustForYouState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool? isInitialized,
  }) {
    return JustForYouState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final justForYouControllerProvider =
    StateNotifierProvider<JustForYouController, JustForYouState>((ref) {
  return JustForYouController(ref);
});

class JustForYouController extends StateNotifier<JustForYouState> {
  final Ref ref;
  static const int _perPage = 8; // Match dashboard default

  JustForYouController(this.ref)
      : super(JustForYouState(
          products: [],
          isLoading: false,
          hasMore: true,
          currentPage: 1,
        ));

  // Initialize with products from dashboard
  void initializeProducts(List<Product> initialProducts, int total) {
    debugPrint('Initializing Just For You with ${initialProducts.length} products, total: $total');
    // Calculate which page we're on based on products received
    // If we got 8 products and perPage is 10, we're still on page 1
    final currentPage = (initialProducts.length / _perPage).floor();
    final actualPage = currentPage == 0 ? 1 : currentPage;
    
    debugPrint('Setting currentPage to $actualPage (${initialProducts.length} products with $_perPage per page)');
    
    state = state.copyWith(
      products: initialProducts,
      hasMore: initialProducts.length < total,
      currentPage: actualPage,
      isInitialized: true,
    );
  }

  Future<void> loadMoreProducts() async {
    // Prevent multiple simultaneous loads
    if (state.isLoading || !state.hasMore) {
      debugPrint('loadMoreProducts blocked: isLoading=${state.isLoading}, hasMore=${state.hasMore}');
      return;
    }

    debugPrint('loadMoreProducts starting: currentPage=${state.currentPage}, products count=${state.products.length}');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final nextPage = state.currentPage + 1;
      final filterModel = ProductFilterModel(
        page: nextPage,
        perPage: _perPage,
      );

      debugPrint('Fetching page $nextPage with perPage=$_perPage');
      final response = await ref
          .read(productServiceProvider)
          .getCategoryWiseProducts(productFilterModel: filterModel);

      final data = response.data['data'];
      debugPrint('API Response data keys: ${data.keys}');
      
      final newProducts = (data['products'] as List)
          .map((json) => Product.fromMap(json as Map<String, dynamic>))
          .toList();

      final total = data['total'] as int;
      final allProducts = [...state.products, ...newProducts];

      debugPrint('Loaded ${newProducts.length} products. Total now: ${allProducts.length}/$total');
      debugPrint('hasMore will be: ${allProducts.length < total}');

      state = state.copyWith(
        products: allProducts,
        isLoading: false,
        hasMore: allProducts.length < total,
        currentPage: nextPage,
      );
      
      debugPrint('State updated: products=${state.products.length}, hasMore=${state.hasMore}, currentPage=${state.currentPage}');
    } catch (error, stackTrace) {
      debugPrint('Error loading more products: $error');
      debugPrint(stackTrace.toString());

      final errorMessage = error is DioException
          ? ApiInterceptors.handleError(error)
          : error.toString();

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  void reset() {
    state = JustForYouState(
      products: [],
      isLoading: false,
      hasMore: true,
      currentPage: 1,
    );
  }
}
