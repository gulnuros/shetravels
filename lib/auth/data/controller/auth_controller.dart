import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shetravels/auth/data/repository/auth_repository.dart';
import 'package:shetravels/auth/views/screens/widgets/error_message_widget.dart';
import 'package:shetravels/utils/route.gr.dart';
import 'package:shetravels/utils/string.dart';

// final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
//   return FirebaseAuth.instance;
// });

// final authRepositoryProvider = Provider<AuthRepository>((ref) {
//   return AuthRepository(ref.watch(firebaseAuthProvider));
// });

// final authControllerProvider =
//     StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
//       return AuthController(ref.watch(authRepositoryProvider));
//     });

// class AuthController extends StateNotifier<AsyncValue<User?>> {
//   final AuthRepository _repository;

//   AuthController(this._repository) : super(const AsyncLoading()) {
//     _init();
//   }

//   void _init() {
//     _repository.authStateChanges.listen((user) {
//       state = AsyncData(user);
//     });
//   }

//       String? error;
//       bool? acceptTerms;

//         final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();
//   final fullNameController = TextEditingController();

//   bool obscurePassword = true;
//   bool obscureConfirmPassword = true;

//   Future<void> signUp(
//     String email,
//     String password, {
//     required BuildContext context,
//   }) async {
//     state = const AsyncLoading();
//     try {
//       final user = await _repository.signUp(email, password);
//       state = AsyncData(user);

//       // Show success alert
//       if (context.mounted) {
//         await showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (BuildContext dialogContext) {
//             return signupSuccess(dialogContext);
//           },
//         );

//         context.router.push(const LoginRoute());

//         // Small delay to let user see the success message
//         await Future.delayed(const Duration(milliseconds: 1500));

//         // Optionally, navigate to a welcome screen or home page
//         // context.router.push(HomeRoute());
//       }
//     } catch (e, st) {
//       state = AsyncError(e, st);

//       // Show error alert
//       if (context.mounted) {
//         await showDialog(
//           context: context,
//           builder: (BuildContext dialogContext) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               title: Row(
//                 children: [
//                   Icon(Icons.error, color: Colors.red, size: 28),
//                   const SizedBox(width: 12),
//                   Text(
//                     'Sign Up Failed',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ],
//               ),
//               content: Text(
//                 getErrorMessage(e),
//                 style: GoogleFonts.poppins(fontSize: 16),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(dialogContext).pop();
//                   },
//                   child: Text(
//                     'Try Again',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.w600,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       }
//     }
//   }

//   void signUpMethod(BuildContext context) async {

//     if (_formKey.currentState?.validate() ?? false) {
//       if (!acceptTerms) {
//         setState(() => error = pleaseAcceptTermsAndCondition);
//         HapticFeedback.mediumImpact();
//         return;
//       }

//       setState(() => error = null);
//       HapticFeedback.lightImpact();

//       try {
//         await signUp(
//               context: context,
//               emailController.text.trim(),
//               passwordController.text.trim(),
//             );
//       } catch (e) {
//         if (mounted) {
//           setState(() => authCont.error = e.toString());
//           HapticFeedback.mediumImpact();
//         }
//       }
//     } else {
//       HapticFeedback.mediumImpact();
//     }
//   }

// Future<void> signIn(
//     String email,
//     String password,
//     BuildContext context,
//   ) async {
//     state = const AsyncLoading();
//     try {
//       final user = await _repository.signIn(email, password);
//       state = AsyncData(user);
//       context.router.push(HomeRoute());
//     } catch (e, st) {
//       state = AsyncError(e, st);
//     }
//   }

//   Future<void> signOut() async {
//     await _repository.signOut();
//     state = const AsyncData(null);
//   }

//   Future<void> resetPassword(
//     String email, {
//     required BuildContext context,
//   }) async {
//     try {
//       await _repository.resetPassword(email);

//       // Show success alert
//       if (context.mounted) {
//         await successAlert(context, email);
//       }
//     } catch (e) {
//       // Show error alert
//       if (context.mounted) {
//         await errorAlert(context, e);
//       }
//     }
//   }

//   // Helper widget to build step items

//   // Helper method to get user-friendly reset password error messages

//   // Alternative SnackBar version (simpler approach)
//   Future<void> resetPasswordWithSnackBar(
//     String email, {
//     required BuildContext context,
//   }) async {
//     try {
//       await _repository.resetPassword(email);

//       // Show success snackbar
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           resetPasswordSuccess(context),
//         );
//       }
//     } catch (e) {
//       // Show error snackbar
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           resetPasswordError(e, context),
//         );
//       }
//     }
//   }

// }

// Providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

// Controller
class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  // Controllers (dispose in dispose())
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final fullNameController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? error;
  bool acceptTerms = false;

  AuthController(this._repository) : super(const AsyncLoading()) {
    _init();
  }

  void _init() {
    _repository.authStateChanges.listen((user) {
      state = AsyncData(user);
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    super.dispose();
  }

  void toggleAcceptTerms(bool value) {
    acceptTerms = value;
  }

  // ----------------- AUTH METHODS -----------------

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    // Trigger a rebuild by setting state to current value
    state = AsyncData(state.value);
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    state = AsyncData(state.value);
  }

  Future<void> signUp(
    String email,
    String password, {
    required BuildContext context,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signUp(email, password);
      state = AsyncData(user);

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => signupSuccess(dialogContext),
        );

        // Delay so user can see success dialog
        await Future.delayed(const Duration(milliseconds: 1500));

        context.router.replace(const LoginRoute());
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      if (context.mounted) {
        await _showErrorDialog(context, getErrorMessage(e));
      }
    }
  }

  Future<void> signIn(
    String email,
    String password,
    BuildContext context,
  ) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signIn(email, password);
      state = AsyncData(user);

      if (context.mounted) {
        context.router.replace(HomeRoute());
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      if (context.mounted) {
        await _showErrorDialog(context, getErrorMessage(e));
      }
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(null);
  }

  Future<void> resetPassword(
    String email, {
    required BuildContext context,
  }) async {
    try {
      await _repository.resetPassword(email);
      if (context.mounted) {
        await successAlert(context, email);
      }
    } catch (e) {
      if (context.mounted) {
        await errorAlert(context, e);
      }
    }
  }

  Future<void> resetPasswordWithSnackBar(
    String email, {
    required BuildContext context,
  }) async {
    try {
      await _repository.resetPassword(email);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(resetPasswordSuccess(context));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(resetPasswordError(e, context));
      }
    }
  }

  // ----------------- VALIDATION HELPERS -----------------

  Future<void> signUpWithValidation(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      error = "Please fill all fields";
      HapticFeedback.mediumImpact();
      return;
    }

    if (password != confirmPassword) {
      error = "Passwords do not match";
      HapticFeedback.mediumImpact();
      return;
    }

    if (!acceptTerms) {
      error = "Please accept terms and conditions";
      HapticFeedback.mediumImpact();
      return;
    }

    error = null;
    HapticFeedback.lightImpact();

    await signUp(email, password, context: context);
  }

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(message, style: GoogleFonts.poppins(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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

  Future<void> signUpWithSnackBar(
    String email,
    String password, {
    required BuildContext context,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signUp(email, password);
      state = AsyncData(user);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account created successfully! Please check your email.',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        context.router.replace(const LoginRoute());
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getErrorMessage(e),
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a password';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }
}
