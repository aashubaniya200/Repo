import 'dart:convert';

import 'return_order.dart';

class Data {
  int? total;
  List<ReturnOrder>? returnOrders;

  Data({this.total, this.returnOrders});

  factory Data.fromMap(Map<String, dynamic> data) => Data(
        total: _parseInt(data['total']),
        returnOrders: (data['returnOrders'] as List<dynamic>?)
            ?.map((e) => ReturnOrder.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  // Helper method to safely parse int from dynamic (handles both int and String)
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() => {
        'total': total,
        'returnOrders': returnOrders?.map((e) => e.toMap()).toList(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Data].
  factory Data.fromJson(String data) {
    return Data.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Data] to a JSON string.
  String toJson() => json.encode(toMap());
}
