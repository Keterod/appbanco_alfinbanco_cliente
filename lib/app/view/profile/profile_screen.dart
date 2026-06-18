import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';
import '../../viewmodel/profile_viewmodel.dart';
import '../widgets/alfin_app_bar.dart';
import '../widgets/app_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    unawaited(SessionTimeoutManager.saveActivity());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _demoSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    await _viewModel.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AlfinAppBar(title: 'Perfil'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.profile == null) {
            return _buildEmpty(context);
          }

          return _buildContent(context, vm);
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _viewModel.loadError ?? 'No se pudo cargar tu perfil.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _viewModel.reload(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProfileViewModel vm) {
    final p = vm.profile!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      AppColors.secondary.withValues(alpha: 0.15),
                  child: Text(
                    p.fullName.isNotEmpty ? p.fullName[0] : '?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  p.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.clientType,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _ProfileTile(
                icon: Icons.badge_outlined,
                label: 'DNI',
                value: p.maskedDni,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.email_outlined,
                label: 'Correo',
                value: p.email,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: p.phone,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.location_on_outlined,
                label: 'Dirección',
                value: p.address,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.calendar_today_outlined,
                label: 'Vinculación',
                value: FormatUtils.formatDate(p.joinDate),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Seguridad',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Cambiar contraseña'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _demoSnack(
                  'Cambiar contraseña disponible en modo demostración',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Configurar notificaciones'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _demoSnack(
                  'Notificaciones disponibles en modo demostración',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.purpleSupport),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textDark.withValues(alpha: 0.55),
            ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
