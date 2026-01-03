import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlybaohanh_app/core/constants/app_constants.dart';
import 'package:quanlybaohanh_app/features/home/presentation/pages/home_page.dart';
import 'package:quanlybaohanh_app/features/auth/presentation/pages/sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;


  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }

    // Fake Admin login removed as per request 

    // 2. Try Real Supabase Login
    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (res.session != null) {
        // AuthGate will handle navigation automatically since it listens to auth state changes
        // But since we are in a pushed route (maybe), let's ensure we are clean.
        // Actually AuthGate is at root. If we just pop or do nothing, AuthGate rebuilds.
        // But if this page is displayed by AuthGate, nothing happens visually until AuthGate rebuilds.
        // In main.dart, AuthGate returns HomePage if session != null.
        // So we don't strictly need to Navigate manually.
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _googleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Web Client ID is required for Android and Web
      // Web Client ID is required for Android and Web
      // iOS requires explicit clientId
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleWebClientId,
        clientId: (kIsWeb || Theme.of(context).platform == TargetPlatform.iOS) 
            ? (kIsWeb ? AppConstants.googleWebClientId : AppConstants.googleIosClientId)
            : null,
        scopes: ['email'],
      );
      
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;

      if (googleAuth == null) {
        throw 'Google Sign-In failed.';
      }

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (error) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Keep content centered vertically
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 80,
                color: Color(0xFF8B0000),
              ),
              const SizedBox(height: 24),
              Text(
                'Quản Lý Bảo Hành',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF8B0000),
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Quản lý bảo hành sản phẩm hiệu quả',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  child: ElevatedButton.icon(
                    onPressed: _googleSignIn,
                    icon: const Icon(Icons.login), // Use a generic login icon since we don't have font_awesome
                    label: const Text('Đăng nhập với Google'),
                  ),
                ),
                
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Đăng nhập Email / Admin', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _handleLogin,
                    child: const Text('Đăng nhập'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
                  },
                  child: const Text('Chưa có tài khoản? Đăng ký'),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Powered by PMVN',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey, 
            fontSize: 12, 
            fontWeight: FontWeight.w500
          ),
        ),
      ),
    );
  }
}
