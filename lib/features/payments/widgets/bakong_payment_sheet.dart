import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/payment_model.dart';

Future<void> showBakongPaymentSheet({
  required BuildContext context,
  required PaymentModel initialPayment,
  VoidCallback? onPaymentSuccess,
  Future<PaymentModel?> Function()? onRegenerate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => BakongPaymentSheet(
      initialPayment: initialPayment,
      onPaymentSuccess: onPaymentSuccess,
      onRegenerate: onRegenerate,
    ),
  );
}

class BakongPaymentSheet extends ConsumerStatefulWidget {
  final PaymentModel initialPayment;
  final VoidCallback? onPaymentSuccess;
  final Future<PaymentModel?> Function()? onRegenerate;

  const BakongPaymentSheet({
    super.key,
    required this.initialPayment,
    this.onPaymentSuccess,
    this.onRegenerate,
  });

  @override
  ConsumerState<BakongPaymentSheet> createState() => _BakongPaymentSheetState();
}

class _BakongPaymentSheetState extends ConsumerState<BakongPaymentSheet>
    with WidgetsBindingObserver {
  late PaymentModel _payment;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int? _remainingSeconds;
  bool _isChecking = false;
  bool _isRegenerating = false;
  bool _notifiedPaid = false;
  bool _triggeredExpiryCheck = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _payment = widget.initialPayment;
    _recomputeRemaining();

    if (_payment.isPaid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyPaidOnce();
      });
    } else if (_payment.isPending) {
      _startTimers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _payment.isPending &&
        !_isChecking &&
        !_isRegenerating) {
      _checkStatus(manual: false);
    }
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _startTimers() {
    _stopTimers();
    _recomputeRemaining();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _payment.isPending && !_isChecking && !_isRegenerating) {
        _checkStatus(manual: false);
      }
    });
    if (_payment.expiresAtDate != null) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _recomputeRemaining();
        if (_remainingSeconds == 0 &&
            _payment.isPending &&
            !_triggeredExpiryCheck &&
            !_isChecking) {
          _triggeredExpiryCheck = true;
          _checkStatus(manual: false);
        }
      });
    }
  }

  void _recomputeRemaining() {
    final expiresAt = _payment.expiresAtDate;
    if (expiresAt == null) {
      if (mounted) {
        setState(() => _remainingSeconds = null);
      } else {
        _remainingSeconds = null;
      }
      return;
    }
    final diff = expiresAt.toUtc().difference(DateTime.now().toUtc()).inSeconds;
    final clamped = diff < 0 ? 0 : diff;
    if (mounted) {
      setState(() => _remainingSeconds = clamped);
    } else {
      _remainingSeconds = clamped;
    }
  }

  void _notifyPaidOnce() {
    if (_notifiedPaid || !mounted) return;
    _notifiedPaid = true;
    _stopTimers();
    ref.read(courseProgressRefreshProvider.notifier).state++;
    ToastService.showSuccess('Bakong payment confirmed! Your course access is now active.');
    widget.onPaymentSuccess?.call();
  }

  Future<void> _checkStatus({required bool manual}) async {
    if (_isChecking || _isRegenerating || !_payment.isPending) return;

    setState(() {
      _isChecking = true;
      if (manual) _error = null;
    });

    try {
      final updated = await ref
          .read(paymentRepositoryProvider)
          .checkPaymentStatus(_payment.paymentId);
      if (!mounted) return;

      setState(() {
        _payment = updated;
        _isChecking = false;
        _error = null;
      });
      _recomputeRemaining();

      if (updated.isPaid) {
        _notifyPaidOnce();
      } else if (!updated.isPending) {
        _stopTimers();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleRegenerate() async {
    if (_isRegenerating) return;

    setState(() {
      _isRegenerating = true;
      _error = null;
      _triggeredExpiryCheck = false;
    });

    try {
      PaymentModel? nextPayment;
      if (widget.onRegenerate != null) {
        nextPayment = await widget.onRegenerate!();
      } else if (_payment.courseId > 0) {
        final response = await ref
            .read(paymentRepositoryProvider)
            .checkout(_payment.courseId, provider: 'BAKONG_KHQR');
        nextPayment = response.toPaymentModel();
      }

      if (!mounted) return;
      if (nextPayment == null) {
        setState(() => _isRegenerating = false);
        return;
      }

      setState(() {
        _payment = nextPayment!;
        _isRegenerating = false;
        _notifiedPaid = false;
      });

      if (nextPayment.isPaid) {
        _notifyPaidOnce();
      } else if (nextPayment.isPending) {
        _startTimers();
      } else {
        _stopTimers();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRegenerating = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openDeepLink() async {
    final link = _payment.deepLink;
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) {
      ToastService.showError('Invalid Bakong payment link.');
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        ToastService.showError('Unable to open Bakong app. Please scan the KHQR code instead.');
      }
    } catch (_) {
      ToastService.showError('Unable to open Bakong app. Please scan the KHQR code instead.');
    }
  }

  String _formatCountdown(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = _payment.isPaid;
    final isExpired = _payment.isExpired;
    final isFailed = _payment.isFailed || _payment.status == 'REFUNDED';
    final hasQr = _payment.qrCode != null && _payment.qrCode!.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1232E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'KHQR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pay with Bakong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Scan this KHQR code using Bakong or any participating Cambodian mobile banking app.',
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
          ApiAlert(
            error: _error,
            onRetry: _payment.isPending ? () => _checkStatus(manual: true) : null,
          ),
          const SizedBox(height: 12),

          // Price Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _payment.courseTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount Due', style: TextStyle(fontSize: 13, color: theme.hintColor)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_payment.isReEnrollmentDiscount &&
                            _payment.originalAmount != null) ...[
                          Text(
                            Formatters.formatCurrency(_payment.originalAmount),
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '-50% OFF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${Formatters.formatCurrency(_payment.amount)} ${_payment.currency ?? "USD"}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_payment.providerReference != null &&
                    _payment.providerReference!.isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Invoice Ref', style: TextStyle(fontSize: 11, color: theme.hintColor)),
                      InkWell(
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _payment.providerReference!),
                          );
                          ToastService.showSuccess('Reference copied to clipboard');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _payment.providerReference!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy, size: 14, color: theme.hintColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (isPaid) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 52),
                  SizedBox(height: 10),
                  Text(
                    'Payment Confirmed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your transaction was verified via Bakong and course access is unlocked.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ] else if (isExpired || isFailed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer_off_outlined, color: Colors.amber, size: 44),
                  const SizedBox(height: 10),
                  Text(
                    isExpired ? 'KHQR Payment Expired' : 'Payment ${_payment.status}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isExpired
                        ? 'This dynamic KHQR code has expired. Generate a fresh code to pay.'
                        : 'This invoice can no longer be used. Generate a fresh Bakong KHQR code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _isRegenerating ? null : _handleRegenerate,
                    icon: _isRegenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(_isRegenerating ? 'Generating...' : 'Generate New KHQR'),
                  ),
                ],
              ),
            ),
          ] else if (hasQr) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _payment.qrCode!,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_remainingSeconds != null) ...[
                  const Icon(Icons.schedule, size: 15, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'Expires in ${_formatCountdown(_remainingSeconds!)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Checking every 3s',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_payment.deepLink != null && _payment.deepLink!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _openDeepLink,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Pay via Bakong App'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _isChecking ? null : () => _checkStatus(manual: true),
                icon: _isChecking
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(_isChecking ? 'Checking Status...' : "I've Paid • Check Status"),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2, size: 44, color: theme.hintColor),
                  const SizedBox(height: 8),
                  Text(
                    'No active KHQR payload on this invoice.',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isRegenerating ? null : _handleRegenerate,
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: Text(_isRegenerating ? 'Generating...' : 'Generate KHQR'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
