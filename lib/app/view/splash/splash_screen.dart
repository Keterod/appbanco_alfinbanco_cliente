import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/supabase/supabase_config.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    debugPrint('[AUTH] checking session');

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    if (!SupabaseConfig.isConfigured || !SupabaseBootstrap.initialized) {
      debugPrint('[AUTH] Supabase not configured, showing login');
      _goToLogin();
      return;
    }

    final client = supabase;
    final session = client.auth.currentSession;
    final user = client.auth.currentUser;

    if (session == null || user == null) {
      debugPrint('[AUTH] no current session, showing login');
      _goToLogin();
      return;
    }

    debugPrint('[AUTH] currentSession found userId=${user.id}');

    final timeoutValid = await SessionTimeoutManager.isSessionStillValid();

    if (!timeoutValid) {
      debugPrint('[AUTH] session expired after inactivity');
      await client.auth.signOut();
      await SessionTimeoutManager.clearActivity();
      if (!mounted) return;
      _goToLogin();
      return;
    }

    final hasInternet = await _checkInternet(client);

    if (!hasInternet) {
      debugPrint('[AUTH] no internet, login required');
      if (!mounted) return;
      _goToLogin(internetRequired: true);
      return;
    }

    debugPrint('[AUTH] showing dashboard');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  Future<bool> _checkInternet(dynamic client) async {
    try {
      await (client as SupabaseClient)
          .from('clientes_perfil')
          .select('id')
          .limit(1);
      return true;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('connection') ||
          msg.contains('timeout') ||
          msg.contains('failed host lookup')) {
        return false;
      }
      return true;
    }
  }

  void _goToLogin({bool internetRequired = false}) {
    if (internetRequired) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.login,
        arguments: {'internetRequired': true},
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.purpleSupport,
                    AppColors.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/alfin_logo.png',
                  width: 76,
                  height: 76,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Alfin Banco',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.purpleSupport,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Verificando sesión...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
