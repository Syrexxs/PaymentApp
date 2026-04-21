import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';


class StripeService {

  static const Map<String, String> _textTokens = {

    '2423423224243212': 'tok_visa',
    '5454233455646545': 'tok_visa_debit',
    '4234234324234268': 'tok_mastercard',
    '6546754654656443': 'tok_mastercard_debit',
    '4324328879784566': 'tok_chargeDeclined',
    '2345238797885553': 'tok_chargedDeclineInsufficientFunds',
  };


  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,

  }) async {
    final amountInCents = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll(' ', '');
    final token = _textTokens[cleanCard];


    if (token == null) {
      return <String, dynamic>{
        'success': false,
        'error': 'Invalid card number'
      };
    }

    try {
      final response = await http.post(
          Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
          headers: <String, String>{
            'Authorization': 'Bearer ${StripeConfig.secretKey}',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: <String, String>{
            'amount': amountInCents,
            'currency': 'php',
            'payment_method_types[]': 'card',
            'payment_method_data[type]': 'card',
            'payment_method_data[card][token]': token,
            'confirm': 'true',
          }
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'succeeded') {
        final paidAmount = (data['amount'] as num) / 100;
        return <String, dynamic>{
          'success': true,
          'id': data['id'].toString(),
          'amount': paidAmount,
          'status': data['status'].toString(),
        };
      } else {
        final errorMsg = data['error'] is Map ? (data['error'] as Map)
        ['message']?.toString() ?? 'payment failed' : 'payment failed';
        return <String, dynamic>{
          'success': false,
          'error': errorMsg,
        };
      }
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': e.toString()
      };
    }
  }
}