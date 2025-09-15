import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;

  Future<void> _makePayment() async {
    setState(() {
      _loading = true;
    });

    try {
      final url = Uri.parse(
        'https://us-central1-shetravels-ac34a.cloudfunctions.net/createPaymentIntent',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 1000, // 1000 cents = $10.00
          'currency': 'usd',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create PaymentIntent');
      }

      final jsonResponse = jsonDecode(response.body);
      final clientSecret = jsonResponse['clientSecret'];

      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Your App Name',
        ),
      );

      // 3. Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment successfully')));
    } on StripeException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment cancelled')));
    } catch (e) {
      print('Payment error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stripe Payment')),
      body: Center(
        child:
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _makePayment,
                  child: Text('Pay \$10'),
                ),
      ),
    );
  }
}
