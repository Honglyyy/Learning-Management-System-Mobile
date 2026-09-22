import 'package:flutter/material.dart';

class ToastService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: const Color(0xFF16A34A),
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: const Color(0xFFDC2626),
      icon: Icons.error_outline,
    );
  }

  static void showInfo(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: const Color(0xFF2563EB),
      icon: Icons.info_outline,
    );
  }

  static void showWarning(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: const Color(0xFFD97706),
      icon: Icons.warning_amber_outlined,
    );
  }

  static void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    messengerKey.currentState?.removeCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
