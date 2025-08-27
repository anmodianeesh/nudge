import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Simulate login delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    
    // Simulate social login
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      // For existing users, go directly to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
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
                const SizedBox(height: 40),
                
                // Header
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue your journey',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Social Login Buttons
                CustomButton(
                  text: 'Continue with Apple',
                  onPressed: () => _handleSocialLogin('apple'),
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  prefixIcon: Icons.apple,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 12),
                
                CustomButton(
                  text: 'Continue with Google',
                  onPressed: () => _handleSocialLogin('google'),
                  backgroundColor: Colors.white,
                  textColor: AppTheme.textDark,
                  prefixIcon: Icons.g_mobiledata_rounded,
                  borderColor: AppTheme.borderGray,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 32),
                
                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.borderGray)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(color: AppTheme.textGray),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.borderGray)),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Email & Password Fields
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
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Login Button
                CustomButton(
                  text: 'Sign In',
                  onPressed: _handleEmailLogin,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 24),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppTheme.textGray),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign up',
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