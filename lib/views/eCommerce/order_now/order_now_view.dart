import 'package:flutter/material.dart';
import 'package:webpal_commerce/models/eCommerce/order/order_now_cart_model.dart';
import 'package:webpal_commerce/views/eCommerce/order_now/layouts/order_now_layout.dart';

class EcommerceOrderNowView extends StatelessWidget {
  final OrderNowCartModel orderNowCartModel;
  const EcommerceOrderNowView({
    super.key,
    required this.orderNowCartModel,
  });

  @override
  Widget build(BuildContext context) {
    return EcommerceOrderNowLayout(
      orderNowCartModel: orderNowCartModel,
    );
  }
}
