class Wallet {
  final String id;
  final String userId;
  final double availableBalance;
  final double pendingBalance;
  final String currency;

  Wallet({
    required this.id,
    required this.userId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.currency,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'NGN',
    );
  }
}

class BankAccount {
  final String id;
  final String creatorId;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final bool isPrimary;

  BankAccount({
    required this.id,
    required this.creatorId,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.isPrimary,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      bankCode: json['bank_code'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class WalletTransaction {
  final String id;
  final String walletId;
  final String type;
  final double amount;
  final String status;
  final String reference;
  final String description;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.status,
    required this.reference,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      type: json['type'] as String? ?? 'general',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'completed',
      reference: json['reference'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
