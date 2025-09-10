// Web environment only
import 'dart:html' as html;

void openCheckoutUrl(String url) {
  html.window.location.href = url; // Redirect to Stripe Checkout
}
