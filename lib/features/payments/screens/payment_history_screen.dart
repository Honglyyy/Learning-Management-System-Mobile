import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/payment_model.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  List<PaymentModel> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payments = await ref.read(paymentRepositoryProvider).getMyPayments();
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'PAID':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green;
        break;
      case 'PENDING':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange;
        break;
      case 'FAILED':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _payments.any((p) => p.isPending);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: RefreshIndicator(
        onRefresh: _loadPayments,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPending)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have pending payment transactions awaiting bank verification.',
                          style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ApiAlert(error: _error, onRetry: _loadPayments),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _payments.isEmpty
                        ? const EmptyState(
                            title: 'No payment transactions',
                            description: 'When you purchase paid courses, your transaction receipts will appear here.',
                          )
                        : ListView.builder(
                            itemCount: _payments.length,
                            itemBuilder: (context, index) {
                              final p = _payments[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p.courseTitle,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          _buildStatusBadge(p.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            Formatters.formatCurrency(p.amount),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          if (p.provider.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text('• ${p.provider}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                          const Spacer(),
                                          if (p.createdAt != null)
                                            Text(
                                              Formatters.formatDate(p.createdAt),
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                      if (p.providerReference != null && p.providerReference!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('Ref: ${p.providerReference}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (p.isPending)
                                            const Text(
                                              'Awaiting bank verification',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            )
                                          else
                                            const SizedBox.shrink(),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            ),
                                            onPressed: () => context.push('/courses/${p.courseId}'),
                                            child: const Text('Go to Course', style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
