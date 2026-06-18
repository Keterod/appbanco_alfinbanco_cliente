import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:banco_alfinbanco/app/core/supabase/supabase_bootstrap.dart';
import 'package:banco_alfinbanco/app/core/supabase/supabase_config.dart';
import 'package:banco_alfinbanco/app/navigation/app_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
      SupabaseBootstrap.initialized = true;
      debugPrint('[Supabase] Inicializado correctamente.');
    } catch (e, stack) {
      SupabaseBootstrap.initialized = false;
      debugPrint('[Supabase] Error de inicialización: $e');
      debugPrint('[Supabase] La app continuará en modo demostración.');
      debugPrint('$stack');
    }
  } else {
    debugPrint('[Supabase] No configurado — modo demostración.');
  }

  runApp(const AppNavigation());
}
