// web_redirect_web.dart
import 'dart:html' as html;

/// Opens the Stripe Checkout URL for web payments
void openCheckoutUrl(String url) {
  // Open in same window to maintain the session
  html.window.location.href = url;
}

/// Handle success redirect from Stripe Checkout
/// This should be called when the app loads and detects a success URL
void handleSuccessRedirect() {
  final currentUrl = html.window.location.href;
  final uri = Uri.parse(currentUrl);
  
  // Check if this is a success page
  if (uri.path.contains('/success')) {
    // Extract parameters
    final bookingId = uri.queryParameters['booking_id'];
    final sessionId = uri.queryParameters['session_id'];
    
    // Store these parameters for the success screen to use
    if (bookingId != null) {
      html.window.localStorage['success_booking_id'] = bookingId;
    }
    if (sessionId != null) {
      html.window.localStorage['success_session_id'] = sessionId;
    }
    
    // Set a flag indicating successful payment
    html.window.localStorage['payment_success'] = 'true';
    
    // Clear the URL parameters by redirecting to clean URL
    final cleanUrl = '${uri.origin}${uri.path}';
    html.window.history.replaceState(null, '', cleanUrl);
  }
}

/// Get success parameters from localStorage including event name
Map<String, String?> getSuccessParameters() {
  final bookingId = html.window.localStorage['success_booking_id'];
  final sessionId = html.window.localStorage['success_session_id'];
  final eventName = html.window.localStorage['checkout_event_name'];
  final isSuccess = html.window.localStorage['payment_success'] == 'true';
  
  return {
    'bookingId': bookingId,
    'sessionId': sessionId,
    'eventName': eventName,
    'isSuccess': isSuccess.toString(),
  };
}

/// Clear success parameters from localStorage
void clearSuccessParameters() {
  html.window.localStorage.remove('success_booking_id');
  html.window.localStorage.remove('success_session_id');
  html.window.localStorage.remove('payment_success');
  html.window.localStorage.remove('checkout_event_name');
  html.window.localStorage.remove('checkout_booking_id');
}

/// Check if current URL indicates a payment cancellation
bool isPaymentCancelled() {
  final currentUrl = html.window.location.href;
  return currentUrl.contains('/cancel');
}