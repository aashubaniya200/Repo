import 'dart:convert';

class ReturnOrder {
  int? id;
  String? orderId;
  String? reason;
  double? amount;
  String? status;
  String? paymentStatus;
  dynamic rejectNote;
  String? returnDate;
  String? returnAddress;

  ReturnOrder({
    this.id,
    this.orderId,
    this.reason,
    this.amount,
    this.status,
    this.paymentStatus,
    this.rejectNote,
    this.returnDate,
    this.returnAddress,
  });

  factory ReturnOrder.fromMap(Map<String, dynamic> data) => ReturnOrder(
        id: _parseInt(data['id']),
        orderId: data['order_id']?.toString(),
        reason: data['reason'] as String?,
        amount: _parseDouble(data['amount']),
        status: data['status'] as String?,
        paymentStatus: data['payment_status'] as String?,
        rejectNote: data['reject_note'] as dynamic,
        returnDate: data['return_date'] as String?,
        returnAddress: data['return_address'] as String?,
      );

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
        'id': id,
        'order_id': orderId,
        'reason': reason,
        'amount': amount,
        'status': status,
        'payment_status': paymentStatus,
        'reject_note': rejectNote,
        'return_date': returnDate,
        'return_address': returnAddress,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [ReturnOrder].
  factory ReturnOrder.fromJson(String data) {
    return ReturnOrder.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [ReturnOrder] to a JSON string.
  String toJson() => json.encode(toMap());
}
