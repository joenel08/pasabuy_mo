import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pasabuy_mo/views/profile/public_profile_screen.dart';
import '../controllers/auth_controller.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/auth/verify_email_screen.dart';
import '../views/onboarding/profile_step1_screen.dart';
import '../views/onboarding/kyc_step2_screen.dart';
import '../views/onboarding/pending_review_screen.dart';
import '../views/onboarding/declined_screen.dart';
import '../views/main_shell.dart';
import '../views/splash_screen.dart';
import '../views/post/post_form_screen.dart';
import '../views/messages/conversation_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/feed/find_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/deals/my_deals_screen.dart';
import '../views/analytics/analytics_screen.dart';
import '../views/settings/settings_screen.dart';
import '../views/settings/static_page_screen.dart';
import '../views/settings/static_content.dart';
import '../views/post/edit_post_screen.dart';
import '../views/favorites/favorites_screen.dart';
import '../models/post.dart';
import '../views/report/report_target_screen.dart';

class AppRouter {
  static late GoRouter router;
}

GoRouter buildRouter(AuthController auth) {
  final r = GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (auth.status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }

      final loggedIn = auth.loggedIn;
      final atAuth =
          loc == '/login' || loc == '/register' || loc == '/verify-email';

      if (!loggedIn) return atAuth ? null : '/login';
      if (!auth.emailVerified) return loc == '/verify-email' ? null : '/login';
      if (!auth.profileCompleted) {
        return loc == '/onboarding/profile' ? null : '/onboarding/profile';
      }
      if (auth.kycStatus == 'none') {
        return loc == '/onboarding/kyc' ? null : '/onboarding/kyc';
      }
      if (auth.kycStatus == 'pending') {
        return loc == '/onboarding/pending' ? null : '/onboarding/pending';
      }
      if (auth.kycStatus == 'declined') {
        return loc == '/onboarding/declined' ? null : '/onboarding/declined';
      }
      if (atAuth || loc.startsWith('/onboarding') || loc == '/splash') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, s) => VerifyEmailScreen(email: (s.extra as String?) ?? ''),
      ),
      GoRoute(
          path: '/onboarding/profile',
          builder: (_, __) => const ProfileStep1Screen()),
      GoRoute(
          path: '/onboarding/kyc', builder: (_, __) => const KycStep2Screen()),
      GoRoute(
          path: '/onboarding/pending',
          builder: (_, __) => const PendingReviewScreen()),
      GoRoute(
          path: '/onboarding/declined',
          builder: (_, __) => const DeclinedScreen()),
      GoRoute(path: '/', builder: (_, __) => const MainShell()),
      GoRoute(
        path: '/post/new',
        builder: (_, s) {
          final t = s.uri.queryParameters['type'] ?? 'offer';
          return PostFormScreen(initialType: t);
        },
      ),
      GoRoute(
        path: '/find',
        builder: (_, __) => const FindScreen(),
      ),
      GoRoute(
        path: '/deals',
        builder: (_, __) => const MyDealsScreen(),
      ),
      GoRoute(
        path: '/messages/:id',
        builder: (_, s) => ConversationScreen(
          conversationId: int.parse(s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (_, s) => PublicProfileScreen(
          userId: int.parse(s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/analytics',
        builder: (_, __) => const AnalyticsScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/help',
          builder: (_, __) =>
              const StaticPageScreen(title: 'Help centre', body: kHelpContent)),
      GoRoute(
          path: '/terms',
          builder: (_, __) => const StaticPageScreen(
              title: 'Terms & conditions', body: kTermsContent)),
      GoRoute(
          path: '/about',
          builder: (_, __) =>
              const StaticPageScreen(title: 'About', body: kAboutContent)),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(
        path: '/post/edit',
        builder: (_, s) => EditPostScreen(post: s.extra as Post),
      ),
      GoRoute(
        path: '/report',
        builder: (_, s) {
          final args = s.extra as (String, int);
          return ReportTargetScreen(targetType: args.$1, targetId: args.$2);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const ProfileStep1Screen(editMode: true),
      ),
    ],
  );
  AppRouter.router = r;
  return r;
}
