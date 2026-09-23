import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../theme/theme_mode_notifier.dart';

final unreadNotificationCountProvider =
    StateNotifierProvider<UnreadNotificationNotifier, int>((ref) {
  final notifRepo = ref.watch(notificationRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return UnreadNotificationNotifier(notifRepo, authRepo);
});

class UnreadNotificationNotifier extends StateNotifier<int> {
  final dynamic _notifRepo;
  final dynamic _authRepo;
  Timer? _timer;

  UnreadNotificationNotifier(this._notifRepo, this._authRepo) : super(0) {
    if (_authRepo.isAuthenticated) {
      pollCount();
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => pollCount());
    }
  }

  Future<void> pollCount() async {
    if (!_authRepo.isAuthenticated) {
      state = 0;
      return;
    }
    try {
      final count = await _notifRepo.getUnreadCount();
      state = count;
    } catch (_) {}
  }

  void refresh() => pollCount();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class AppScaffold extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  int _calculateSelectedIndex(String path, String role, bool isAuth) {
    if (!isAuth) {
      if (path.startsWith('/catalog') || path.startsWith('/search')) return 1;
      if (path.startsWith('/instructors')) return 2;
      if (path.startsWith('/verify-certificate')) return 3;
      if (path.startsWith('/login') || path.startsWith('/register')) return 4;
      return 0;
    }

    if (role == 'ADMIN') {
      if (path.startsWith('/admin')) return 1;
      if (path.startsWith('/my/enrollments')) return 2;
      if (path.startsWith('/profile')) return 3;
      return 0;
    }

    if (role == 'INSTRUCTOR') {
      if (path.startsWith('/instructor')) return 1;
      if (path.startsWith('/profile')) return 2;
      return 0;
    }

    // STUDENT / USER: 0: Home, 1: Search, 2: My Courses, 3: Notifications, 4: Profile
    if (path.startsWith('/catalog') || path.startsWith('/search')) return 1;
    if (path.startsWith('/my/enrollments')) return 2;
    if (path.startsWith('/notifications')) return 3;
    if (path.startsWith('/profile') || path.startsWith('/my/payments')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, String role, bool isAuth) {
    if (!isAuth) {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/catalog');
          break;
        case 2:
          context.go('/instructors');
          break;
        case 3:
          context.go('/verify-certificate');
          break;
        case 4:
          context.go('/login');
          break;
      }
      return;
    }

    if (role == 'ADMIN') {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/admin');
          break;
        case 2:
          context.go('/my/enrollments');
          break;
        case 3:
          context.go('/profile');
          break;
      }
      return;
    }

    if (role == 'INSTRUCTOR') {
      switch (index) {
        case 0:
          context.go('/catalog');
          break;
        case 1:
          context.go('/instructor');
          break;
        case 2:
          context.go('/profile');
          break;
      }
      return;
    }

    // STUDENT
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/catalog');
        break;
      case 2:
        context.go('/my/enrollments');
        break;
      case 3:
        context.go('/notifications');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authRepo = ref.watch(authRepositoryProvider);
    final isAuth = authRepo.isAuthenticated;
    final role = authRepo.getUserRole() ?? 'STUDENT';
    final unreadCount = isAuth ? ref.watch(unreadNotificationCountProvider) : 0;

    // Listen for session expiry
    ref.listen<String?>(sessionExpiredEventProvider, (prev, reason) {
      if (reason != null) {
        context.go('/login?reason=$reason');
        ref.read(sessionExpiredEventProvider.notifier).state = null;
      }
    });

    final selectedIndex = _calculateSelectedIndex(currentPath, role, isAuth);

    List<BottomNavigationBarItem> navItems = [];
    if (!isAuth) {
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), activeIcon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Instructors'),
        BottomNavigationBarItem(icon: Icon(Icons.verified_outlined), activeIcon: Icon(Icons.verified), label: 'Verify'),
        BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Sign In'),
      ];
    } else if (role == 'ADMIN') {
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Catalog'),
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Learning'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (role == 'INSTRUCTOR') {
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Catalog'),
        BottomNavigationBarItem(icon: Icon(Icons.video_library_outlined), activeIcon: Icon(Icons.video_library), label: 'Studio'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      navItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'My Courses',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications),
          ),
          label: 'Notification',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    return Listener(
      onPointerDown: (_) {
        ref.read(sessionManagerProvider).recordActivity();
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: InkWell(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_stories, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lumen LMS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (isAuth && role != 'STUDENT' && role != 'USER') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: role == 'ADMIN' ? Colors.purple.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: role == 'ADMIN' ? Colors.purple.withValues(alpha: 0.4) : Colors.blue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: role == 'ADMIN' ? Colors.purple : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            // Theme toggle
            IconButton(
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            ),
            // Wishlist (if authenticated)
            if (isAuth)
              IconButton(
                icon: const Icon(Icons.favorite_border),
                tooltip: 'Wishlist',
                onPressed: () => context.push('/wishlist'),
              ),

            // Notification Bell (if authenticated)
            if (isAuth)
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

            // Profile or Login
            if (isAuth)
              IconButton(
                icon: const CircleAvatar(
                  radius: 14,
                  child: Icon(Icons.person, size: 18),
                ),
                onPressed: () => context.go('/profile'),
              )
            else
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign In'),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex.clamp(0, navItems.length - 1),
          onTap: (idx) => _onItemTapped(idx, context, role, isAuth),
          items: navItems,
        ),
      ),
    );
  }
}
