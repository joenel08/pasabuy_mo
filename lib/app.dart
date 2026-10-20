import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/language_controller.dart';

import 'controllers/auth_controller.dart';
import 'controllers/feed_controller.dart';
import 'controllers/kyc_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/conversations_controller.dart';
import 'controllers/notifications_controller.dart';

import 'services/auth_service.dart';
import 'services/kyc_service.dart';
import 'services/post_service.dart';
import 'services/profile_service.dart';
import 'services/conversation_service.dart';
import 'services/notification_service.dart';
import 'services/transaction_service.dart';
import 'services/review_service.dart';
import 'services/favorite_service.dart';
import 'services/report_service.dart';

class PasaBuyApp extends StatelessWidget {
  const PasaBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();

    return MultiProvider(
      providers: [
        // --- Core ---
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(
          create: (_) => LanguageController()..load(),
        ),

        // --- Services ---
        Provider<PostService>(create: (_) => PostService(api)),
        Provider<ConversationService>(create: (_) => ConversationService(api)),
        Provider<NotificationService>(create: (_) => NotificationService(api)),
        Provider<TransactionService>(create: (_) => TransactionService(api)),
        Provider<ProfileService>(create: (_) => ProfileService(api)),
        Provider<ReviewService>(create: (_) => ReviewService(api)),
        Provider<FavoriteService>(create: (_) => FavoriteService(api)),
        Provider<ReportService>(create: (_) => ReportService(api)),

        // --- Controllers ---
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService(api))..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(ProfileService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => KycController(KycService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedController(PostService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversationsController(ConversationService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationsController(NotificationService(api)),
        ),
      ],
      child: Builder(builder: (context) {
        final auth = context.read<AuthController>();
        final lang = context.watch<LanguageController>();
        final router = buildRouter(auth);

        return MaterialApp.router(
          title: 'PasaBuy Mo, Pasaya Mo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,

          // Localization — wires the app-wide locale
          locale: lang.locale,
          supportedLocales: const [
            Locale('en', 'PH'),
            Locale('fil', 'PH'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          routerConfig: router,
        );
      }),
    );
  }
}