import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shetravels/auth/data/controller/auth_controller.dart';
import 'package:shetravels/auth/views/screens/widgets/signup_methods.dart';
import 'package:shetravels/utils/route.gr.dart';

Widget buildErrorMessage(WidgetRef ref) {
  final authCont = ref.read(authControllerProvider);

  if (authCont.error == null) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${authCont.error ?? ''}',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

String getErrorMessage(dynamic error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return error.message ??
            'An unexpected error occurred. Please try again.';
    }
  }
  return 'An unexpected error occurred. Please try again.';
}

Future<dynamic> successAlert(BuildContext context, String email) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.mark_email_read, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Text(
              'Check Your Email',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A password reset link has been sent to:',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                email,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Next steps:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            buildStepItem('1. Check your email inbox'),
            buildStepItem('2. Click the reset password link'),
            buildStepItem('3. Create a new password'),
            buildStepItem('4. Return to sign in with your new password'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Don\'t see the email? Check your spam folder or try again.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.router.push(LoginRoute());
            },
            child: Text(
              'Got It',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<dynamic> errorAlert(BuildContext context, Object e) {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'Reset Failed',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getResetPasswordErrorMessage(e),
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please try:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Check your internet connection\n• Verify the email address is correct\n• Wait a few minutes before trying again',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      );
    },
  );
}

String getResetPasswordErrorMessage(dynamic error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check the email or create a new account.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes before trying again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      default:
        return error.message ??
            'Reset password failed. Please try again later.';
    }
  }
  return 'Reset password failed. Please try again later.';
}

SnackBar resetPasswordSuccess(BuildContext context) {
  return SnackBar(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mark_email_read, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Password Reset Sent!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Check your email and follow the instructions to reset your password.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        ),
      ],
    ),
    backgroundColor: Colors.green,
    duration: const Duration(seconds: 5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
    action: SnackBarAction(
      label: 'OK',
      textColor: Colors.white,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.of(context).pop(); 
      },
    ),
  );
}

SnackBar resetPasswordError(Object e, BuildContext context) {
  return SnackBar(
    content: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            getResetPasswordErrorMessage(e),
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    ),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
    action: SnackBarAction(
      label: 'RETRY',
      textColor: Colors.white,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  );
}




  AlertDialog signupSuccess(BuildContext dialogContext) {
    return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Success!',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            content: Text(
              'Your account has been created successfully! Please check your email for verification.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); 
                },
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          );
  }
