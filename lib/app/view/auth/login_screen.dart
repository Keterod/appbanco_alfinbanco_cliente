import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../viewmodel/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthViewModel _viewModel;
  bool _internetRequired = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['internetRequired'] == true) {
        setState(() => _internetRequired = true);
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    await _viewModel.login(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (_viewModel.isSuccess) {
      await SessionTimeoutManager.saveActivity();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final loading = _viewModel.isLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(child: _AlfinLogoMark()),
                  const SizedBox(height: 20),
                  Text(
                    'Alfin Banco',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.purpleSupport,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Banca por internet — clientes',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 36),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Ingreso',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Modo Supabase: usa correo y contraseña registrados.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textDark.withValues(alpha: 0.55),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Modo demostración disponible si Supabase no responde.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textDark.withValues(alpha: 0.55),
                                ),
                          ),
                          if (_viewModel.usedDemoMode) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Ingresaste en modo demostración.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                          if (_internetRequired) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.wifi_off_rounded,
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Necesitas conexión a internet para iniciar sesión.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.primary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_viewModel.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _viewModel.errorMessage!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                    ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              hintText: 'tu@correo.com',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!loading) _onSubmit();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              hintText: 'Ingrese su contraseña',
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: loading ? null : _onSubmit,
                              child: loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Text('Ingresar'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => Navigator.of(context)
                                    .pushNamed(AppRoutes.register),
                            child: const Text('¿No tienes cuenta? Regístrate'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AlfinLogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
      alignment: Alignment.center,
      child: ClipOval(
        child: Image.asset(
          'assets/images/alfin_logo.png',
          width: 76,
          height: 76,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
