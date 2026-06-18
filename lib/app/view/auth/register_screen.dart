import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../viewmodel/register_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterViewModel _viewModel;
  final _dniController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onRegister() async {
    _viewModel.clearMessages();
    final success = await _viewModel.register();
    if (!mounted) return;

    if (!success && _viewModel.errorMessage != null) {
      _showError(_viewModel.errorMessage!);
      return;
    }

    if (success && _viewModel.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.successMessage!),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _AlfinLogoMark()),
                  const SizedBox(height: 16),
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
                    'Crear cuenta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Regístrate para acceder a tu banca móvil',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_viewModel.errorMessage != null) ...[
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextField(
                            controller: _dniController,
                            onChanged: _viewModel.setDni,
                            keyboardType: TextInputType.number,
                            maxLength: 8,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'DNI',
                              hintText: '8 dígitos',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _firstNameController,
                            onChanged: _viewModel.setFirstName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombres',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _lastNameController,
                            onChanged: _viewModel.setLastName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Apellidos',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            onChanged: _viewModel.setPhone,
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              hintText: '9 dígitos',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            onChanged: _viewModel.setEmail,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            onChanged: _viewModel.setPassword,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPasswordController,
                            onChanged: _viewModel.setConfirmPassword,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar contraseña',
                            ),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _viewModel.acceptedTerms,
                            onChanged: loading
                                ? null
                                : (v) =>
                                    _viewModel.toggleAcceptedTerms(v ?? false),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'Acepto los términos y condiciones',
                              style: TextStyle(fontSize: 14),
                            ),
                            activeColor: AppColors.secondary,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: loading ? null : _onRegister,
                              child: loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Text('Crear cuenta'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.login),
                    child: const Text('Ya tengo una cuenta'),
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
      width: 88,
      height: 88,
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
          width: 68,
          height: 68,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
