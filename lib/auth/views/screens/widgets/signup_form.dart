import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/auth/data/controller/auth_controller.dart';
import 'package:shetravels/auth/views/screens/widgets/error_message_widget.dart';
import 'package:shetravels/auth/views/screens/widgets/signup_methods.dart';
import 'package:shetravels/auth/views/screens/widgets/signup_textfield.dart';
import 'package:shetravels/utils/colors.dart';
import 'package:shetravels/utils/route.gr.dart';
import 'package:flutter/services.dart';

Form signupForm(
  bool isMobile,
  AsyncValue<User?> authState,
  BuildContext context,
  GlobalKey<FormState> formKey,
  WidgetRef ref,
) {
  final authCont = ref.watch(authControllerProvider.notifier);
  final auth = ref.watch(authControllerProvider);

  return Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Text(
              "Create Account",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Join us and start your journey to explore the world safely",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 24 : 32),
        buildErrorMessage(ref),
        buildTextField(
          label: "Full Name",
          controller: authCont.fullNameController,
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        buildTextField(
          label: "Email Address",
          controller: authCont.emailController,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        buildTextField(
          label: "Password",
          controller: authCont.passwordController,
          icon: Icons.lock_outline_rounded,
          obscureText: authCont.obscurePassword,
          validator: authCont.validatePassword,
          suffixIcon: IconButton(
            icon: Icon(
              authCont.obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              authCont.togglePasswordVisibility();
              HapticFeedback.selectionClick();
            },
          ),
        ),
        buildTextField(
          label: "Confirm Password",
          controller: authCont.confirmPasswordController,
          icon: Icons.lock_outline_rounded,
          obscureText: authCont.obscureConfirmPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != authCont.passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          suffixIcon: IconButton(
            icon: Icon(
              authCont.obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              authCont.toggleConfirmPasswordVisibility();
              HapticFeedback.selectionClick();
            },
          ),
        ),
        buildTermsAndConditions(ref),
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient:
                authState.isLoading
                    ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                    )
                    : const LinearGradient(
                      colors: [Color(0xFFf093fb), Color(0xFFe88d99)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                authState.isLoading
                    ? null
                    : [
                      BoxShadow(
                        color: const Color(0xFFf093fb).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
          ),
          child: ElevatedButton(
            onPressed:
                authState.isLoading
                    ? null
                    : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        if (!authCont.acceptTerms) {
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please accept the Terms and Conditions",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        await authCont.signUpWithSnackBar(
                          authCont.emailController.text.trim(),
                          authCont.passwordController.text.trim(),
                          context: context,
                        );
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child:
                authState.isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.defaultWhiteColor,
                      ),
                    )
                    : const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.defaultWhiteColor,
                      ),
                    ),
          ),
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account? ",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            TextButton(
              onPressed: () => context.router.push(LoginRoute()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text(
                "Sign In",
                style: TextStyle(
                  color: Color(0xFFf093fb),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),

        if (auth.hasError) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              auth.error.toString(),
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    ),
  );
}
