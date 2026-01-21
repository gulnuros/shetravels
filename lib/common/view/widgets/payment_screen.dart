import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;

  Future<void> _makePayment() async {
    setState(() => _loading = true);

    try {
      final url = Uri.parse(
        '',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 1000, 
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

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'She Travels',
          style: ThemeMode.system, 
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful ')),
      );
    } on StripeException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment cancelled ')),
      );
    } catch (e) {
      debugPrint('Payment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed ')),
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
