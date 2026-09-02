import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/wallet.dart';
import '../../services/supabase_service.dart';

class WalletScreen extends StatefulWidget {
  final UserProfile? profile;

  const WalletScreen({super.key, this.profile});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final currencyFormatter = NumberFormat('#,##0', 'en_US');
  late Future<Map<String, dynamic>> _walletDataFuture;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  void _loadWalletData() {
    final userId = widget.profile?.id ?? SupabaseService.currentUser?.id;
    if (userId != null) {
      _walletDataFuture = _fetchEverything(userId);
    } else {
      _walletDataFuture = Future.value({
        'wallet': Wallet(id: '', userId: '', availableBalance: 0.0, pendingBalance: 0.0, currency: 'NGN'),
        'bankAccounts': <BankAccount>[],
        'transactions': <WalletTransaction>[],
      });
    }
  }

  Future<Map<String, dynamic>> _fetchEverything(String userId) async {
    final wallet = await SupabaseService.fetchWallet(userId);
    final bankAccounts = await SupabaseService.fetchBankAccounts(userId);
    final transactions = await SupabaseService.fetchTransactions(wallet.id);

    return {
      'wallet': wallet,
      'bankAccounts': bankAccounts,
      'transactions': transactions,
    };
  }

  void _openCashoutModal(Wallet wallet, List<BankAccount> bankAccounts) {
    final amountController = TextEditingController();
    String selectedBank = 'OPay';
    final accountNumberController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ViralyTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Withdraw Earnings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(LucideIcons.x, color: ViralyTheme.textMuted, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Available: ₦${currencyFormatter.format(wallet.availableBalance)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ViralyTheme.emerald),
              ),
              const SizedBox(height: 16),

              // Amount Field
              Container(
                decoration: BoxDecoration(
                  color: ViralyTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ViralyTheme.border),
                ),
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Amount (e.g. 10000)',
                    hintStyle: TextStyle(color: ViralyTheme.textMuted, fontSize: 14),
                    prefixText: '₦ ',
                    prefixStyle: TextStyle(color: ViralyTheme.emerald, fontSize: 16, fontWeight: FontWeight.w700),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Bank Name Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ViralyTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ViralyTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBank,
                    dropdownColor: ViralyTheme.surfaceElevated,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'OPay', child: Text('OPay Digital Services')),
                      DropdownMenuItem(value: 'PalmPay', child: Text('PalmPay')),
                      DropdownMenuItem(value: 'Kuda', child: Text('Kuda Microfinance Bank')),
                      DropdownMenuItem(value: 'Moniepoint', child: Text('Moniepoint MFB')),
                      DropdownMenuItem(value: 'GTBank', child: Text('Guaranty Trust Bank (GTB)')),
                      DropdownMenuItem(value: 'Zenith', child: Text('Zenith Bank')),
                      DropdownMenuItem(value: 'Access', child: Text('Access Bank')),
                    ],
                    onChanged: (val) {
                      if (val != null) selectedBank = val;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Account Number Field
              Container(
                decoration: BoxDecoration(
                  color: ViralyTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ViralyTheme.border),
                ),
                child: TextField(
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '10-Digit NUBAN Account Number',
                    hintStyle: TextStyle(color: ViralyTheme.textMuted, fontSize: 13),
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final enteredAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    final accNum = accountNumberController.text.trim();

                    if (enteredAmount <= 0 || enteredAmount > wallet.availableBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid amount or insufficient balance.')),
                      );
                      return;
                    }

                    if (accNum.length != 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid 10-digit account number.')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);

                    try {
                      final userId = widget.profile?.id ?? SupabaseService.currentUser!.id;
                      await SupabaseService.requestWithdrawal(
                        walletId: wallet.id,
                        userId: userId,
                        amount: enteredAmount,
                        bankDetailsDescription: '$selectedBank ($accNum)',
                      );

                      setState(() {
                        _loadWalletData();
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 Cashout request of ₦${currencyFormatter.format(enteredAmount)} sent for instant Paystack disbursal!'),
                            backgroundColor: ViralyTheme.emerald,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ViralyTheme.emerald,
                    foregroundColor: const Color(0xFF07090E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Confirm Cashout via Paystack', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      appBar: AppBar(
        title: const Text('Naira Wallet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadWalletData();
          });
        },
        color: ViralyTheme.emerald,
        backgroundColor: ViralyTheme.surface,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _walletDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(ViralyTheme.emerald),
                ),
              );
            }

            final wallet = snapshot.data?['wallet'] as Wallet? ?? Wallet(id: '', userId: '', availableBalance: 0.0, pendingBalance: 0.0, currency: 'NGN');
            final bankAccounts = snapshot.data?['bankAccounts'] as List<BankAccount>? ?? [];
            final transactions = snapshot.data?['transactions'] as List<WalletTransaction>? ?? [];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HERO WALLET BALANCE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ViralyTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: ViralyTheme.emerald.withAlpha(90), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: ViralyTheme.emerald.withAlpha(30),
                          blurRadius: 28,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AVAILABLE BALANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: ViralyTheme.textMuted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: ViralyTheme.emerald.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'INSTANT CASHOUT',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ViralyTheme.emerald),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₦${currencyFormatter.format(wallet.availableBalance)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _openCashoutModal(wallet, bankAccounts),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ViralyTheme.emerald,
                              foregroundColor: const Color(0xFF07090E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.arrowUpRight, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Withdraw to Nigerian Bank / OPay',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // TRANSACTIONS LEDGER
                  const Text(
                    'RECENT TRANSACTIONS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: ViralyTheme.textMuted),
                  ),
                  const SizedBox(height: 12),

                  if (transactions.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: ViralyTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ViralyTheme.border),
                      ),
                      child: Center(
                        child: Text(
                          'No transactions yet. Complete gigs to receive payouts.',
                          style: TextStyle(fontSize: 12, color: ViralyTheme.textMuted),
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final isWithdrawal = tx.type == 'withdrawal';
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ViralyTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: ViralyTheme.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isWithdrawal ? ViralyTheme.indigo.withAlpha(20) : ViralyTheme.emerald.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isWithdrawal ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                                      size: 16,
                                      color: isWithdrawal ? ViralyTheme.indigo : ViralyTheme.emerald,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.description.isNotEmpty ? tx.description : (isWithdrawal ? 'Withdrawal Cashout' : 'Earnings Payout'),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt),
                                        style: TextStyle(fontSize: 10, color: ViralyTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                '${isWithdrawal ? '-' : '+'}₦${currencyFormatter.format(tx.amount)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isWithdrawal ? Colors.white : ViralyTheme.emerald,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
