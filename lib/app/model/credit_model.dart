class CreditModel {
  const CreditModel({
    required this.productName,
    required this.pendingAmount,
    required this.nextPaymentDate,
  });

  final String productName;
  final double pendingAmount;
  final DateTime nextPaymentDate;
}
