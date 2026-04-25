import 'package:dio/src/response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/services/base/eCommerce/flash_sales_provider_base.dart';
import 'package:webpal_commerce/utils/api_client.dart';

final flashSalesServiceProvider = Provider((ref) => FlashSalesService(ref));

class FlashSalesService extends FlashSalesProviderBase {
  final Ref ref;
  FlashSalesService(this.ref);

  @override
  Future<Response> getFlashSalesDetail({required int id}) async {
    final response = await ref
        .read(apiClientProvider)
        .get("${AppConstants.flashSaleDetails}/$id/details");
    return response;
  }

  @override
  Future<Response> getFlashSalesList() async {
    final response =
        await ref.read(apiClientProvider).get(AppConstants.flashSales);
    debugPrint("responseall ${response.data["data"]}");
    return response;
  }
}
