import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';
import '../model/client_loan_request_model.dart';
import 'auth_repository.dart';

class ClientLoanRequestDraft {
  final String applicantName;
  final String documentNumber;
  final String phone;

  const ClientLoanRequestDraft({
    required this.applicantName,
    required this.documentNumber,
    required this.phone,
  });
}

({String nombres, String apellidos}) _splitNombreCompleto(String nombreCompleto) {
  final parts = nombreCompleto.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return (nombres: 'Sin Nombre', apellidos: 'Sin Apellidos');
  }
  if (parts.length == 1) {
    return (nombres: parts.first, apellidos: 'Sin Apellidos');
  }
  return (
    nombres: parts.first,
    apellidos: parts.skip(1).join(' '),
  );
}

class ClientLoanRequestRepository {
  ClientLoanRequestRepository({
    AuthRepository? authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository ?? AuthRepository(),
        _client = client;

  final AuthRepository _auth;
  final SupabaseClient? _client;

  bool _parseSeguroDesgravamen(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;

    final text = value.toString().trim().toLowerCase();

    return text == 'sí' ||
        text == 'si' ||
        text == 'true' ||
        text == '1' ||
        text == 'con seguro' ||
        text == 'con seguro de desgravamen';
  }

/// Busca un cliente por numero_documento o lo crea si no existe.
  ///
  /// Nota sobre el modelo de datos:
  /// - `clientes.id` identifica al cliente/solicitante del caso (ej. "Miguel Huamán").
  /// - `solicitudes_credito.created_by_auth_id` identifica al usuario logueado
  ///   que registró la solicitud (puede ser distinto del solicitante).
  /// - Esto permite que un asesor (Miguel) registre casos con DNI de otros
  ///   solicitantes y luego los vea en Mis Solicitudes.
  Future<String?> findOrCreateClientByDni({
    required String documento,
    required String nombres,
    required String telefono,
    String tipoNegocio = '',
    String nombreNegocio = '',
    int antiguedadNegocioMeses = 0,
    double ingresosEstimados = 0,
  }) async {
    debugPrint('[CLIENT_LOAN] findOrCreateClientByDni documento=$documento');

    if (!_auth.isConfigured) return null;
    final client = _client ?? supabase;

    final existingRow = await client
        .from('clientes')
        .select('id')
        .eq('numero_documento', documento)
        .maybeSingle();

    if (existingRow != null) {
      final clienteId = (existingRow as Map)['id']?.toString();
      debugPrint('[CLIENT_LOAN] found existing cliente_id=$clienteId');
      return clienteId;
    }

    debugPrint('[CLIENT_LOAN] creating new client for documento=$documento');
    try {
      final nombreSeparado = _splitNombreCompleto(nombres);

      final newCliente = await client
          .from('clientes')
          .insert({
            'numero_documento': documento,
            'tipo_documento': 'DNI',
            'nombres': nombreSeparado.nombres,
            'apellidos': nombreSeparado.apellidos,
            'telefono': telefono.trim().isNotEmpty ? telefono.trim() : null,
            if (tipoNegocio.isNotEmpty) 'tipo_negocio': tipoNegocio,
            if (nombreNegocio.isNotEmpty) 'nombre_negocio': nombreNegocio,
            if (antiguedadNegocioMeses > 0) 'antiguedad_negocio_meses': antiguedadNegocioMeses,
            if (ingresosEstimados > 0) 'ingresos_estimados': ingresosEstimados,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      final clienteId = (newCliente as Map)['id']?.toString();
      debugPrint('[CLIENT_LOAN] created cliente_id=$clienteId');
      return clienteId;
    } catch (e) {
      debugPrint('[CLIENT_LOAN] failed to create client: $e');
      return null;
    }
  }

  /// Obtiene los datos del solicitante logueado desde `clientes_perfil`.
  ///
  /// Usa `auth.uid()` para buscar en `clientes_perfil` y retorna
  /// el nombre completo, DNI y teléfono del usuario autenticado.
  /// Retorna `null` si no hay sesión o perfil.
  Future<ClientLoanRequestDraft?> getCurrentLoggedApplicant() async {
    if (!_auth.isConfigured) return null;
    final client = _client ?? supabase;
    final userId = _auth.currentUser?.id;
    if (userId == null) return null;

    debugPrint('[CLIENT_LOAN] getCurrentLoggedApplicant userId=$userId');

    try {
      final perfilRow = await client
          .from('clientes_perfil')
          .select('dni, nombres, apellidos, telefono')
          .eq('id', userId)
          .maybeSingle();

      if (perfilRow == null) {
        debugPrint('[CLIENT_LOAN] no perfil found for userId=$userId');
        return null;
      }

      final perfil = Map<String, dynamic>.from(perfilRow as Map);
      final dni = perfil['dni']?.toString() ?? '';
      final nombres = perfil['nombres']?.toString() ?? '';
      final apellidos = perfil['apellidos']?.toString() ?? '';
      final telefono = perfil['telefono']?.toString() ?? '';

      final nombreCompleto = [nombres, apellidos]
          .where((s) => s.isNotEmpty)
          .join(' ');

      if (dni.isEmpty) return null;

      debugPrint('[CLIENT_LOAN] found applicant: $nombreCompleto dni=$dni');
      return ClientLoanRequestDraft(
        applicantName: nombreCompleto.isNotEmpty ? nombreCompleto : nombres,
        documentNumber: dni,
        phone: telefono,
      );
    } catch (e) {
      debugPrint('[CLIENT_LOAN] error loading applicant: $e');
      return null;
    }
  }

  /// Inserta una solicitud de crédito en `solicitudes_credito`.
  ///
  /// Usa un solo insert con todos los campos del formulario.
  /// Si falla, lanza una excepción con el error — no hay fallback silencioso.
  /// Esto asegura que la solicitud se guarde completa o falle visiblemente.
  Future<Map<String, dynamic>> submitRequest({
    required String clienteId,
    required ClientLoanRequestModel model,
  }) async {
    final client = _client ?? supabase;
    final authUserId = _auth.currentUser?.id;
    final now = DateTime.now();
    final expediente =
        'EXP-ALF-2026-${now.millisecondsSinceEpoch}';
    final monto =
        double.tryParse(model.loanAmountText.replaceAll(',', '.')) ?? 0;
    final ingreso = model.monthlyIncome;
    final gasto = model.monthlyExpenses;
    final antiguedad =
        int.tryParse(model.businessAgeText) ?? 0;
    final entidadesDeuda =
        int.tryParse(model.entidadesDeudaText.replaceAll(',', '.')) ?? 0;
    final deudaTotal =
        double.tryParse(model.deudaTotalText.replaceAll(',', '.')) ?? 0;
    final diasMora =
        int.tryParse(model.diasMayorMoraText.replaceAll(',', '.')) ?? 0;

    final data = <String, dynamic>{
      'numero_expediente': expediente,
      'cliente_id': clienteId,
      'monto_solicitado': monto,
      'plazo_meses': model.loanTerm,
      'cuota_estimada': model.estimatedInstallment,
      'cronograma_json': jsonEncode(model.schedule),
      'score_pre_evaluacion': model.score,
      'elegibilidad': model.eligibility,
      'ratio_capacidad_pago': model.capacityRatio,
      'riesgo_asignado': model.risk,
      'motivo_pre_evaluacion': model.motivoPreEvaluacion,
      'estado': 'enviado',
      'tipo_negocio': model.businessType,
      'nombre_negocio': model.businessName,
      'antiguedad_negocio_meses': antiguedad,
      'ingresos_estimados': ingreso,
      'gastos_mensuales': gasto,
      'destino_credito': model.loanPurpose,
      'garantia': model.guarantee,
      'tea_referencial': model.tea,
      'seguro_desgravamen': _parseSeguroDesgravamen(model.hasInsurance),
      'canal': 'cliente',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'estado_buro': model.estadoBuro,
      'entidades_deuda': entidadesDeuda,
      'deuda_total': deudaTotal,
      'dias_mayor_mora': diasMora,
      'en_lista_inhabilitados': model.enListaInhabilitados,
      'created_by_auth_id': authUserId,
      'solicitante_documento': model.solicitanteDocumento.trim(),
      'solicitante_nombre': model.solicitanteNombres.trim(),
      'solicitante_telefono': model.solicitanteTelefono.trim(),
    };

    debugPrint('[LOAN_REQUEST] seguro_desgravamen type=${data['seguro_desgravamen'].runtimeType} value=${data['seguro_desgravamen']}');
    debugPrint('[LOAN_REQUEST] insert request payload=${jsonEncode(data)}');

    try {
      final row = await client
          .from('solicitudes_credito')
          .insert(data)
          .select()
          .single();
      debugPrint('[LOAN_REQUEST] request created expediente=$expediente');
      return Map<String, dynamic>.from(row as Map);
    } catch (e) {
      debugPrint('[LOAN_REQUEST] insert failed=$e');
      debugPrint('[LOAN_REQUEST] request not created');
      rethrow;
    }
  }
}
