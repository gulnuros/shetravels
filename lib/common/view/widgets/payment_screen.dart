import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;

  Future<void> _makePayment() async {
    setState(() => _loading = true);

    try {
      // 1. Create PaymentIntent on your backend
      final url = Uri.parse(
        'https://us-central1-shetravels-ac34a.cloudfunctions.net/createPaymentIntent',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 1000, // 1000 cents = 10.00 CAD
          'currency': 'cad',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create PaymentIntent: ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final clientSecret = jsonResponse['clientSecret'];

      if (clientSecret == null) {
        throw Exception('Missing clientSecret from backend response');
      }

      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'She Travels',
          style: ThemeMode.system, // Matches system theme
        ),
      );

      // 3. Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful ✅')),
      );
    } on StripeException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment cancelled ❌')),
      );
    } catch (e) {
      debugPrint('Payment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed ⚠️')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stripe Payment (CAD)')),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _makePayment,
                child: Text('Pay \$10 CAD'),
              ),
      ),
    );
  }
}
