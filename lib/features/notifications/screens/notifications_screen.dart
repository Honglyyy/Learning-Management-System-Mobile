import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/api_alert.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_service.dart';
import '../../../models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifs = await ref.read(notificationRepositoryProvider).getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
      ref.read(unreadNotificationCountProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) {
      return;
    }

    try {
      await ref.read(notificationRepositoryProvider).markRead(item.id);
      _loadNotifications();
    } catch (e) {
      ToastService.showError(e.toString());
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ToastService.showSuccess('All notifications marked as read');
      _loadNotifications();
    } catch (e) {
      ToastService.showError(e.toString());
    }
  }

  void _handleAction(String? actionUrl) {
    if (actionUrl == null || actionUrl.isEmpty) return;
    if (actionUrl.startsWith('/')) {
      context.push(actionUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark All Read'),
              onPressed: _markAllRead,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ApiAlert(error: _error, onRetry: _loadNotifications),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                        ? const EmptyState(
                            icon: Icons.notifications_none_outlined,
                            title: 'No notifications',
                            description: 'You are all caught up! New course, lesson, and assignment notifications will appear here.',
                          )
                        : ListView.separated(
                            itemCount: _notifications.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];

                              return Card(
                                color: item.isRead
                                    ? null
                                    : theme.colorScheme.primary.withValues(alpha: 0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: item.isRead
                                        ? theme.dividerColor
                                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: item.isRead ? null : () => _markRead(item),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.secondary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            item.type == 'CERTIFICATE'
                                                ? Icons.workspace_premium
                                                : item.type == 'ASSIGNMENT'
                                                    ? Icons.assignment
                                                    : item.type == 'QUIZ'
                                                        ? Icons.quiz
                                                        : Icons.notifications,
                                            size: 20,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.title,
                                                      style: TextStyle(
                                                        fontWeight: item.isRead
                                                            ? FontWeight.w600
                                                            : FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!item.isRead)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.message,
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                Formatters.timeAgo(item.createdAt),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme.hintColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
