import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/core/bundeswehr_theme.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/core/routes.dart';
import 'package:mobile_app/providers/absence_provider.dart';
import 'package:mobile_app/providers/admin_provider.dart';
import 'package:mobile_app/providers/approval_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/screens/admin_create_user_screen.dart';
import 'package:mobile_app/screens/admin_home_screen.dart';
import 'package:mobile_app/screens/admin_screen.dart';
import 'package:mobile_app/screens/create_absence_screen.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/my_absences_screen.dart';
import 'package:mobile_app/screens/nfc_verification_screen.dart';
import 'package:mobile_app/screens/pending_approvals_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/splash_screen.dart';
import 'package:mobile_app/services/mock_or_manual_nfc_service.dart';
import 'package:mobile_app/services/nfc_service.dart';
import 'package:mobile_app/services/real_nfc_service.dart';

void main() {
  runApp(const HrApp());
}

NfcService createNfcService() {
  // Use real NFC on Android devices so scan works during normal debug runs.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return RealNfcService();
  }

  // On non-Android debug targets we keep the manual fallback.
  if (kDebugMode) {
    return MockOrManualNfcService();
  }

  return RealNfcService();
}

class HrApp extends StatelessWidget {
  const HrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NfcService>(create: (_) => createNfcService()),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) =>
              AuthProvider(nfcService: context.read<NfcService>()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AbsenceProvider>(
          create: (context) =>
              AbsenceProvider(authProvider: context.read<AuthProvider>()),
          update: (context, auth, previous) {
            previous ??= AbsenceProvider(authProvider: auth);
            previous.updateAuthProvider(auth);
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ApprovalProvider>(
          create: (context) =>
              ApprovalProvider(authProvider: context.read<AuthProvider>()),
          update: (context, auth, previous) {
            previous ??= ApprovalProvider(authProvider: auth);
            previous.updateAuthProvider(auth);
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (context) =>
              AdminProvider(authProvider: context.read<AuthProvider>()),
          update: (context, auth, previous) {
            previous ??= AdminProvider(authProvider: auth);
            previous.updateAuthProvider(auth);
            return previous;
          },
        ),
      ],
      child: _SessionLifecycleHandler(
        child: MaterialApp(
          title: 'HR Abwesenheits-App',
          theme: BundeswehrTheme.light(),
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            final routeBuilders = <String, WidgetBuilder>{
              Routes.splash: (context) => const SplashScreen(),
              Routes.login: (context) => const LoginScreen(),
              Routes.nfcVerification: (context) =>
                  const NfcVerificationScreen(),
              Routes.dashboard: (context) => const DashboardScreen(),
              Routes.profile: (context) => const ProfileScreen(),
              Routes.myAbsences: (context) => const MyAbsencesScreen(),
              Routes.createAbsence: (context) => const CreateAbsenceScreen(),
              Routes.pendingApprovals: (context) =>
                  const PendingApprovalsScreen(),
              Routes.admin: (context) => const AdminHomeScreen(),
              Routes.adminCreateUser: (context) =>
                  const AdminCreateUserScreen(),
              Routes.adminManageUsers: (context) => const AdminScreen(),
            };

            final routeName = settings.name ?? Routes.login;
            final builder =
                routeBuilders[routeName] ?? routeBuilders[Routes.login]!;

            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                final auth = context.watch<AuthProvider>();

                if (routeName == Routes.splash) {
                  return builder(context);
                }

                if (routeName == Routes.login) {
                  return builder(context);
                }

                if (routeName == Routes.nfcVerification) {
                  if (auth.loginChallengeId == null) {
                    return const LoginScreen();
                  }
                  return builder(context);
                }

                if (!auth.isAuthenticated) {
                  return const LoginScreen();
                }

                if ((routeName == Routes.myAbsences ||
                        routeName == Routes.createAbsence) &&
                    !auth.isSoldier) {
                  return const DashboardScreen();
                }

                if (routeName == Routes.pendingApprovals && !auth.isApprover) {
                  return const DashboardScreen();
                }

                if ((routeName == Routes.admin ||
                        routeName == Routes.adminCreateUser ||
                        routeName == Routes.adminManageUsers) &&
                    !auth.isAdmin) {
                  return const DashboardScreen();
                }

                return builder(context);
              },
            );
          },
        ),
      ),
    );
  }
}

class _SessionLifecycleHandler extends StatefulWidget {
  final Widget child;

  const _SessionLifecycleHandler({required this.child});

  @override
  State<_SessionLifecycleHandler> createState() =>
      _SessionLifecycleHandlerState();
}

class _SessionLifecycleHandlerState extends State<_SessionLifecycleHandler>
    with WidgetsBindingObserver {
  static const Duration _backgroundLogoutDelay = Duration(seconds: 20);

  Timer? _backgroundLogoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _backgroundLogoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _backgroundLogoutTimer?.cancel();
      _backgroundLogoutTimer = null;
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _backgroundLogoutTimer?.cancel();
      _backgroundLogoutTimer = Timer(_backgroundLogoutDelay, () {
        if (!mounted) return;
        context.read<AuthProvider>().logoutForAppBackground();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
