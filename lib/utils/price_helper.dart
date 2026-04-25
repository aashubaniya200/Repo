import 'package:webpal_commerce/models/eCommerce/product/product_details.dart';

/// Helper class for calculating effective MRP based on variant selections
class PriceHelper {
  /// Calculate effective MRP based on priority: Size MRP > Color MRP > Base Product MRP
  /// Returns null if no MRP is available
  static double? getEffectiveMRP({
    required Product product,
    SizeModel? selectedSize,
    Color? selectedColor,
  }) {
    // Priority 1: Size MRP (if size is selected and has MRP)
    if (selectedSize?.mrp != null) {
      return selectedSize!.mrp;
    }
    
    // Priority 2: Color MRP (if color is selected and has MRP)
    if (selectedColor?.mrp != null) {
      return selectedColor!.mrp;
    }
    
    // Priority 3: Base Product MRP
    return product.mrp;
  }

  /// Calculate effective selling price based on variant selection
  /// Priority: Size price > Color price > Base product discountPrice
  static double getEffectiveSellingPrice({
    required Product product,
    SizeModel? selectedSize,
    Color? selectedColor,
  }) {
    // Priority 1: Size price (if size is selected)
    if (selectedSize != null) {
      return selectedSize.price;
    }
    
    // Priority 2: Color price (if color is selected)
    if (selectedColor != null) {
      return selectedColor.price;
    }
    
    // Priority 3: Base product discount price
    return product.discountPrice;
  }

  /// Check if MRP should be displayed (MRP must be greater than selling price)
  static bool shouldDisplayMRP({
    double? mrp,
    required double sellingPrice,
  }) {
    if (mrp == null) return false;
    return mrp > sellingPrice;
  }

  /// Calculate discount percentage from MRP
  static double calculateDiscountPercentage({
    double? mrp,
    required double sellingPrice,
  }) {
    if (mrp == null || mrp <= sellingPrice) return 0;
    return ((mrp - sellingPrice) / mrp) * 100;
  }

  /// Get variant image URL (Size image > Color image > Base product thumbnail)
  static String? getVariantImage({
    required Product product,
    SizeModel? selectedSize,
    Color? selectedColor,
  }) {
    // Priority 1: Size image
    if (selectedSize?.image != null && selectedSize!.image!.isNotEmpty) {
      return selectedSize.image;
    }
    
    // Priority 2: Color image
    if (selectedColor?.image != null && selectedColor!.image!.isNotEmpty) {
      return selectedColor.image;
    }
    
    // Priority 3: First thumbnail from product
    if (product.thumbnails.isNotEmpty) {
      return product.thumbnails.first.url ?? product.thumbnails.first.thumbnail;
    }
    
    return null;
  }

  /// Get all pricing info for display
  static PriceInfo getPriceInfo({
    required Product product,
    SizeModel? selectedSize,
    Color? selectedColor,
  }) {
    final sellingPrice = getEffectiveSellingPrice(
      product: product,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
    );
    
    final mrp = getEffectiveMRP(
      product: product,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
    );
    
    final showMRP = shouldDisplayMRP(
      mrp: mrp,
      sellingPrice: sellingPrice,
    );
    
    final discountPercentage = calculateDiscountPercentage(
      mrp: mrp,
      sellingPrice: sellingPrice,
    );
    
    return PriceInfo(
      sellingPrice: sellingPrice,
      mrp: mrp,
      showMRP: showMRP,
      discountPercentage: discountPercentage,
    );
  }
}

/// Data class to hold pricing information
class PriceInfo {
  final double sellingPrice;
  final double? mrp;
  final bool showMRP;
  final double discountPercentage;

  PriceInfo({
    required this.sellingPrice,
    this.mrp,
    required this.showMRP,
    required this.discountPercentage,
  });
}
