import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/payment_model.dart';

class AbaPayWayDialog extends ConsumerStatefulWidget {
  final int courseId;
  final String courseTitle;
  final num price;

  const AbaPayWayDialog({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.price,
  });

  static Future<void> show(
    BuildContext context, {
    required int courseId,
    required String courseTitle,
    required num price,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AbaPayWayDialog(
        courseId: courseId,
        courseTitle: courseTitle,
        price: price,
      ),
    );
  }

  @override
  ConsumerState<AbaPayWayDialog> createState() => _AbaPayWayDialogState();
}

class _AbaPayWayDialogState extends ConsumerState<AbaPayWayDialog> {
  bool _isLoading = false;
  String? _error;
  CheckoutResponse? _checkoutResult;

  Future<void> _handlePayWithAba() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final res = await paymentRepo.checkout(widget.courseId, provider: 'ABA_PAYWAY');

      setState(() {
        _checkoutResult = res;
        _isLoading = false;
      });

      if (res.paymentUrl != null && res.paymentUrl!.isNotEmpty) {
        final uri = Uri.tryParse(res.paymentUrl!);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        ToastService.showSuccess('Checkout initiated! Ref: ${res.providerReference ?? res.paymentId}');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF003865), // ABA brand navy
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.payment, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('ABA PayWay Checkout', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApiAlert(error: _error),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.courseTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Due (USD):', style: TextStyle(fontSize: 13)),
                        Text(
                          Formatters.formatCurrency(widget.price),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              const Text('1. Tap "Pay with ABA" to start checkout.\n2. You will be redirected to the secure ABA PayWay portal.\n3. Scan the KHQR or confirm via ABA Mobile app.\n4. Once paid, your course enrollment activates instantly.',
                  style: TextStyle(fontSize: 12, height: 1.4)),
              if (_checkoutResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Created Successfully!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                      ),
                      if (_checkoutResult?.providerReference != null)
                        Text(
                          'Reference: ${_checkoutResult!.providerReference}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/my/payments');
          },
          child: const Text('View My Payments'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003865),
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _handlePayWithAba,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Pay with ABA'),
        ),
      ],
    );
  }
}
