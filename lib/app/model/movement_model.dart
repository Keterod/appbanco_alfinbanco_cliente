import '../repository/supabase_parse_utils.dart';
import '../util/format_utils.dart';

class MovementModel {
  const MovementModel({
    required this.id,
    required this.description,
    required this.dateLabel,
    required this.amount,
    required this.isCredit,
    required this.category,
    required this.reference,
  });

  final String id;
  final String description;
  final String dateLabel;
  final double amount;
  final bool isCredit;
  final String category;
  final String reference;

  factory MovementModel.fromSupabase(Map<String, dynamic> json) {
    final fecha = parseSupabaseDate(json['fecha']) ?? DateTime.now();
    final montoRaw = parseSupabaseDouble(json['monto']);
    final esAbono = json['es_abono'] == true ||
        json['tipo_movimiento']?.toString().toLowerCase() == 'abono' ||
        json['tipo_movimiento']?.toString().toLowerCase() == 'credito';
    final monto = esAbono && montoRaw < 0
        ? montoRaw.abs()
        : (!esAbono && montoRaw > 0 ? -montoRaw : montoRaw);

    return MovementModel(
      id: parseSupabaseString(json['id'], 'MOV'),
      description: parseSupabaseString(
        json['descripcion'],
        'Movimiento',
      ),
      dateLabel: FormatUtils.formatDate(fecha),
      amount: monto,
      isCredit: monto >= 0,
      category: parseSupabaseString(json['categoria'], 'General'),
      reference: parseSupabaseString(
        json['referencia'],
        'REF',
      ),
    );
  }
}
