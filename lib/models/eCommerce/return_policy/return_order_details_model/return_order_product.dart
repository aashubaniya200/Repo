import 'dart:convert';

class ReturnOrderProduct {
  int? productId;
  String? productName;
  double? productPrice;
  String? thumbnail;
  int? quantity;
  String? color;
  String? size;
  String? unit;
  double? price;

  ReturnOrderProduct({
    this.productId,
    this.productName,
    this.productPrice,
    this.thumbnail,
    this.quantity,
    this.color,
    this.size,
    this.unit,
    this.price,
  });

  factory ReturnOrderProduct.fromMap(Map<String, dynamic> data) {
    return ReturnOrderProduct(
      productId: _parseInt(data['product_id']),
      productName: data['product_name'] as String?,
      productPrice: _parseDouble(data['product_price']),
      thumbnail: data['thumbnail'] as String?,
      quantity: _parseInt(data['quantity']),
      color: data['color'] as String?,
      size: data['size'] as String?,
      unit: data['unit'] as String?,
      price: _parseDouble(data['price']),
    );
  }

  // Helper method to safely parse int from dynamic (handles both int and String)
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Helper method to safely parse double from dynamic (handles int, double, and String)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'product_price': productPrice,
        'thumbnail': thumbnail,
        'quantity': quantity,
        'color': color,
        'size': size,
        'unit': unit,
        'price': price,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [ReturnOrderProduct].
  factory ReturnOrderProduct.fromJson(String data) {
    return ReturnOrderProduct.fromMap(
        json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [ReturnOrderProduct] to a JSON string.
  String toJson() => json.encode(toMap());
}
