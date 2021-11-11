import 'package:dio/dio.dart';
import 'package:stripe_payment/stripe_payment.dart';

import 'package:stripe_app/models/payment_intent_response.dart';
import 'package:stripe_app/models/stripe_custom_response.dart';

class StripeService {
  //Singleton
  StripeService._privateConstructor();
  static final StripeService _instance = StripeService._privateConstructor();
  factory StripeService() => _instance;

  final String _paymentApiUrl = 'https://api.stripe.com/v1/payment_intents';
  static const String _secretKey =
      'sk_test_51JugxnAkPtsWm2LqaYU6ZI0uYX16w6Q9hbtDTSPnLJCVFAPMz86QkSihUCUWueHFxYbJnan87wBqf2TYyCNOc9K300udk5XS5F';
  final String _apiKey =
      'pk_test_51JugxnAkPtsWm2LqRt8N2dZbBjC4gbOUFDQT3fDIbebyve7LJM6KZxOdh7Urc9mBPlPEn1GHTYW0sJ1SgMR1bWQn00RZqF21vo';
  final headerOptions = Options(
      contentType: Headers.formUrlEncodedContentType,
      headers: {'Authorization': 'Bearer ${StripeService._secretKey}'});

  void init() {
    StripePayment.setOptions(StripeOptions(
        publishableKey: _apiKey, androidPayMode: 'test', merchantId: 'test'));
  }

  Future<StripeCustomResponse> pagarTarjetaExistente({
    required String amount,
    required String currency,
    required CreditCard card,
  }) async {
    try {
      final paymentMethod = await StripePayment.createPaymentMethod(
          PaymentMethodRequest(card: card));
      final resp = await _realizarPago(
          amount: amount, currency: currency, paymentMethod: paymentMethod);
      return resp;
    } catch (e) {
      return StripeCustomResponse(ok: false, msg: e.toString());
    }
  }

  Future<StripeCustomResponse> pagarNuevaTarjeta({
    required String amount,
    required String currency,
  }) async {
    try {
      final paymentMethod = await StripePayment.paymentRequestWithCardForm(
          CardFormPaymentRequest());
      final resp = await _realizarPago(
          amount: amount, currency: currency, paymentMethod: paymentMethod);
      return resp;
    } catch (e) {
      return StripeCustomResponse(ok: false, msg: e.toString());
    }
  }

  Future<StripeCustomResponse> pagarGoogleApple({
    required String amount,
    required String currency,
  }) async {
    try {
      final newAmount = double.parse(amount) / 100;
      final token = await StripePayment.paymentRequestWithNativePay(
          androidPayOptions: AndroidPayPaymentRequest(
              currencyCode: currency, totalPrice: amount),
          applePayOptions: ApplePayPaymentOptions(
              countryCode: 'US',
              currencyCode: currency,
              items: [
                ApplePayItem(label: 'Producto-name', amount: '$newAmount')
              ]));
      final paymentMethod = await StripePayment.createPaymentMethod(
          PaymentMethodRequest(card: CreditCard(token: token.tokenId)));
      final resp = await _realizarPago(
          amount: amount, currency: currency, paymentMethod: paymentMethod);
      StripePayment.completeNativePayRequest();
      return resp;
    } catch (e) {
      return StripeCustomResponse(ok: false, msg: e.toString());
    }
  }

  Future<PaymentIntentResponse> _crearPaymentIntent({
    required String amount,
    required String currency,
  }) async {
    try {
      final dio = Dio();
      final data = {'amount': amount, 'currency': currency};
      final resp =
          await dio.post(_paymentApiUrl, data: data, options: headerOptions);
      return PaymentIntentResponse.fromJson(resp.data);
    } catch (e) {
      return PaymentIntentResponse(status: '400');
    }
  }

  Future<StripeCustomResponse> _realizarPago({
    required String amount,
    required String currency,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final paymentIntent =
          await _crearPaymentIntent(amount: amount, currency: currency);
      final paymentResult = await StripePayment.confirmPaymentIntent(
          PaymentIntent(
              clientSecret: paymentIntent.clientSecret,
              paymentMethodId: paymentMethod.id));
      if (paymentResult.status == 'succeeded') {
        return StripeCustomResponse(ok: true);
      } else {
        return StripeCustomResponse(
            ok: false, msg: 'Fallo: ${paymentResult.status}');
      }
    } catch (e) {
      return StripeCustomResponse(ok: false, msg: e.toString());
    }
  }
}
