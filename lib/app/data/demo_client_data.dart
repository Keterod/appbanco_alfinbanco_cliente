import '../model/account_model.dart';
import '../model/credit_model.dart';
import '../model/movement_model.dart';
import '../model/payment_schedule_model.dart';
import '../model/user_profile_model.dart';

/// Datos locales de respaldo cuando Supabase no está disponible.
abstract final class DemoClientData {
  static const clientName = 'Diego';

  static UserProfileModel get profile => UserProfileModel(
        fullName: 'Diego Mendoza López',
        dni: '74859612',
        email: 'diego.mendoza@correo.demo',
        phone: '+51 987 654 321',
        address: 'Av. Javier Prado Este 4200, San Borja, Lima',
        clientType: 'Cliente Premium',
        joinDate: DateTime(2021, 3, 15),
      );

  static const savingsAccount = AccountModel(
    accountNumber: '0011-0456-7890123456',
    accountType: 'Cuenta de ahorros',
    balance: 2450.80,
  );

  static const cci = '002-011-045678901234-56';

  static CreditModel get activeCredit => CreditModel(
        productName: 'Préstamo personal',
        pendingAmount: 5800.00,
        nextPaymentDate: DateTime(2026, 5, 28),
      );

  static const double monthlyInstallment = 485.50;
  static const double teaPercent = 18.9;
  static const double paymentProgress = 0.42;

  static const homeMovements = [
    MovementModel(
      id: 'M-001',
      description: 'Transferencia recibida',
      dateLabel: '12 may 2026',
      amount: 350.00,
      isCredit: true,
      category: 'Transferencia',
      reference: 'TRX-45821',
    ),
    MovementModel(
      id: 'M-002',
      description: 'Pago con tarjeta — Supermercado',
      dateLabel: '10 may 2026',
      amount: -128.40,
      isCredit: false,
      category: 'Consumo',
      reference: 'POS-99210',
    ),
    MovementModel(
      id: 'M-003',
      description: 'Cargo automático — servicios',
      dateLabel: '08 may 2026',
      amount: -89.90,
      isCredit: false,
      category: 'Servicios',
      reference: 'DEB-33001',
    ),
  ];

  static const accountMovements = [
    MovementModel(
      id: 'A-101',
      description: 'Depósito en ventanilla',
      dateLabel: '11 may 2026',
      amount: 500.00,
      isCredit: true,
      category: 'Depósito',
      reference: 'DEP-11021',
    ),
    MovementModel(
      id: 'A-102',
      description: 'Retiro ATM',
      dateLabel: '09 may 2026',
      amount: -200.00,
      isCredit: false,
      category: 'Retiro',
      reference: 'ATM-77812',
    ),
    MovementModel(
      id: 'A-103',
      description: 'Transferencia enviada',
      dateLabel: '07 may 2026',
      amount: -150.00,
      isCredit: false,
      category: 'Transferencia',
      reference: 'TRX-55102',
    ),
    MovementModel(
      id: 'A-104',
      description: 'Intereses ganados',
      dateLabel: '01 may 2026',
      amount: 12.35,
      isCredit: true,
      category: 'Intereses',
      reference: 'INT-00045',
    ),
  ];

  static List<PaymentScheduleModel> get creditSchedule => [
        PaymentScheduleModel(
          installmentNumber: 1,
          dueDate: DateTime(2026, 1, 28),
          amount: 485.50,
          status: PaymentInstallmentStatus.paid,
          paidDate: DateTime(2026, 1, 27),
        ),
        PaymentScheduleModel(
          installmentNumber: 2,
          dueDate: DateTime(2026, 2, 28),
          amount: 485.50,
          status: PaymentInstallmentStatus.paid,
          paidDate: DateTime(2026, 2, 26),
        ),
        PaymentScheduleModel(
          installmentNumber: 3,
          dueDate: DateTime(2026, 3, 28),
          amount: 485.50,
          status: PaymentInstallmentStatus.paid,
          paidDate: DateTime(2026, 3, 28),
        ),
        PaymentScheduleModel(
          installmentNumber: 4,
          dueDate: DateTime(2026, 4, 28),
          amount: 485.50,
          status: PaymentInstallmentStatus.overdue,
        ),
        PaymentScheduleModel(
          installmentNumber: 5,
          dueDate: DateTime(2026, 5, 28),
          amount: 485.50,
          status: PaymentInstallmentStatus.pending,
        ),
        PaymentScheduleModel(
          installmentNumber: 6,
          dueDate: DateTime(2026, 6, 28),
          amount: 485.50,
          status: PaymentInstallmentStatus.pending,
        ),
      ];
}
