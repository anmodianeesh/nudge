import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../onboarding/user_info_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    // Simulate signup delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => UserInfoScreen(
            userName: _nameController.text,
          ),
        ),
      );
    }
  }

  Future<void> _handleSocialSignup(String provider) async {
    setState(() => _isLoading = true);
    // Simulate social signup
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => UserInfoScreen(
            userName: 'User', // In real implementation, get from social provider
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios),
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join thousands building better habits',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Social Signup Buttons
                CustomButton(
                  text: 'Continue with Apple',
                  onPressed: () => _handleSocialSignup('apple'),
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  prefixIcon: Icons.apple,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Continue with Google',
                  onPressed: () => _handleSocialSignup('google'),
                  backgroundColor: Colors.white,
                  textColor: AppTheme.textDark,
                  prefixIcon: Icons.g_mobiledata_rounded,
                  borderColor: AppTheme.borderGray,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                
                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.borderGray)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or sign up with email',
                        style: TextStyle(color: AppTheme.textGray),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.borderGray)),
                  ],
                ),
                const SizedBox(height: 24),

                // Form Fields
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Create Account Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _handleEmailSignup,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),

                // Terms Text
                const Text(
                  'By signing up, you agree to our Terms and Conditions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppTheme.textGray),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}