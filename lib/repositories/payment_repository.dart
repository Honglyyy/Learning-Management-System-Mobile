import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final ApiClient _api;

  PaymentRepository(this._api);

  Future<CheckoutQuoteModel> getCheckoutQuote(int courseId) async {
    final response = await _api.get(
      ApiEndpoints.paymentsCheckoutQuote,
      queryParameters: {'courseId': courseId},
    );
    return CheckoutQuoteModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CheckoutResponse> checkout(
    int courseId, {
    String provider = 'ABA_PAYWAY',
  }) async {
    final response = await _api.post(
      ApiEndpoints.paymentsCheckout,
      data: {
        'courseId': courseId,
        'provider': provider,
      },
    );
    return CheckoutResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<void> confirmPayment(int paymentId) async {
    await _api.post(ApiEndpoints.paymentConfirm(paymentId));
  }

  Future<List<PaymentModel>> getMyPayments() async {
    final response = await _api.get(ApiEndpoints.paymentsMe);
    if (response is List) {
      return response
          .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final response = await _api.get(ApiEndpoints.payments);
    if (response is List) {
      return response
          .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> updatePaymentStatus(int paymentId, String status) async {
    await _api.patch(
      ApiEndpoints.paymentStatus(paymentId),
      data: {'status': status},
    );
  }

  Future<void> deletePayment(int paymentId) async {
    await _api.delete(ApiEndpoints.paymentById(paymentId));
  }
}
