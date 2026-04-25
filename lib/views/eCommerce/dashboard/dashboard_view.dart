import 'package:flutter/material.dart';
import 'package:webpal_commerce/views/eCommerce/dashboard/layouts/dashboard_layout.dart';

class EcommerceDashboardView extends StatelessWidget {
  const EcommerceDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: EcommerceDashboardLayout(),
    );
  }
}
