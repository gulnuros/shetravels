
import 'dart:html' as html;

void openCheckoutUrl(String url) {
  html.window.location.href = url;
}
void handleSuccessRedirect() {
  final currentUrl = html.window.location.href;
  final uri = Uri.parse(currentUrl);
  
  if (uri.path.contains('/success')) {
    final bookingId = uri.queryParameters['booking_id'];
    final sessionId = uri.queryParameters['session_id'];
    if (bookingId != null) {
      html.window.localStorage['success_booking_id'] = bookingId;
    }
    if (sessionId != null) {
      html.window.localStorage['success_session_id'] = sessionId;
    }
    
    html.window.localStorage['payment_success'] = 'true';
    
    final cleanUrl = '${uri.origin}${uri.path}';
    html.window.history.replaceState(null, '', cleanUrl);
  }
}
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

void clearSuccessParameters() {
  html.window.localStorage.remove('success_booking_id');
  html.window.localStorage.remove('success_session_id');
  html.window.localStorage.remove('payment_success');
  html.window.localStorage.remove('checkout_event_name');
  html.window.localStorage.remove('checkout_booking_id');
}

bool isPaymentCancelled() {
  final currentUrl = html.window.location.href;
  return currentUrl.contains('/cancel');
}