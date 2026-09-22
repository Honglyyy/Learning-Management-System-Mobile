import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/certificate_model.dart';

class VerifyCertificateScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const VerifyCertificateScreen({super.key, this.initialCode});

  @override
  ConsumerState<VerifyCertificateScreen> createState() => _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState extends ConsumerState<VerifyCertificateScreen> {
  late final TextEditingController _codeController;
  CertificateVerification? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.trim().isNotEmpty) {
      _verify(widget.initialCode!.trim());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (code.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await ref.read(certificateRepositoryProvider).verifyCertificate(code.trim());
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Certificate code "$code" could not be verified. Please check the code and try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Certificate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_user_outlined, size: 48, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Official Certificate Verification',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter a valid Lumen LMS certificate code (e.g. DA-2026-03-XXXX) to authenticate the credential.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: 'Enter certificate code...',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        onSubmitted: _verify,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                      onPressed: _isLoading ? null : () => _verify(_codeController.text),
                      child: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Verify'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ApiAlert(error: _error),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.green, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.green, size: 28),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'AUTHENTIC CREDENTIAL VERIFIED',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('Certificate Code', _result!.certificateCode),
                          _buildDetailRow('Recipient Name', _result!.recipientName),
                          _buildDetailRow('Course Program', _result!.courseTitle),
                          if (_result!.instructorName != null)
                            _buildDetailRow('Instructor', _result!.instructorName!),
                          if (_result!.programDuration != null)
                            _buildDetailRow('Program Duration', _result!.programDuration!),
                          if (_result!.issuedAt != null)
                            _buildDetailRow('Issued Date', Formatters.formatDate(_result!.issuedAt)),
                          if (_result!.finalScore != null)
                            _buildDetailRow('Final Score', '${_result!.finalScore}%'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy Link'),
                                  onPressed: () {
                                    final link = '${AppConstants.apiBaseUrl}/verify-certificate?code=${_result!.certificateCode}';
                                    Clipboard.setData(ClipboardData(text: link));
                                    ToastService.showSuccess('Verification link copied');
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('View Template'),
                                  onPressed: () async {
                                    final url = '${AppConstants.apiBaseUrl}/api/certificates/${_result!.certificateCode}/view';
                                    final uri = Uri.tryParse(url);
                                    if (uri != null && await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
