class AccountModel {
  const AccountModel({
    required this.accountNumber,
    required this.accountType,
    required this.balance,
  });

  final String accountNumber;
  final String accountType;
  final double balance;
}
