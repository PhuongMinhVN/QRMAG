import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlybaohanh_app/core/constants/app_constants.dart';
import 'package:quanlybaohanh_app/core/theme/app_theme.dart';
import 'package:quanlybaohanh_app/features/auth/presentation/pages/login_page.dart';
import 'package:quanlybaohanh_app/features/home/presentation/pages/home_page.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Mobile Ads only on Mobile platforms for now to avoid Web errors
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint("Failed to initialize MobileAds: $e");
    }
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'baohanhq',
      theme: AppTheme.theme,
      // home: const AuthGate(),
      home: const AuthGate(),
      // home: const HomePage(), // BYPASS AUTH FOR DEV
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // specific StreamBuilder for auth state change
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
