import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/task_model.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/task_list_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/quote_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TaskManagerApp());
}

class TaskFilterNotifier extends ChangeNotifier {
  String _filter = 'all';
  String get filter => _filter;

  void setFilter(String f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }
}

class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void setDark(bool value) {
    final next = value ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == next) return;
    _themeMode = next;
    notifyListeners();
  }
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<QuoteService>(create: (_) => QuoteService()),
        ChangeNotifierProvider<TaskFilterNotifier>(
          create: (_) => TaskFilterNotifier(),
        ),
        ChangeNotifierProvider<ThemeModeNotifier>(
          create: (_) => ThemeModeNotifier(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: FirebaseAuth.instance.currentUser,
        ),
      ],
      child: Consumer<ThemeModeNotifier>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Flutter Task Manager',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            darkTheme: buildAppTheme(dark: true),
            themeMode: theme.themeMode,
            routes: {
              '/': (_) => const SplashScreen(),
              '/login': (_) => const LoginScreen(),
              '/signup': (_) => const SignupScreen(),
            },
            onGenerateRoute: (settings) {
              final page = switch (settings.name) {
                '/home' => const AuthGate(),
                '/tasks' => const TaskListScreen(),
                '/calendar' => const CalendarScreen(),
                '/profile' => const ProfileScreen(),
                _ => null,
              };
              if (page != null) {
                return PageRouteBuilder<void>(
                  settings: settings,
                  transitionDuration: const Duration(milliseconds: 360),
                  reverseTransitionDuration: const Duration(milliseconds: 260),
                  pageBuilder: (context, animation, secondaryAnimation) => page,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        );
                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.08, 0.02),
                              end: Offset.zero,
                            ).animate(curved),
                            child: child,
                          ),
                        );
                      },
                );
              }
              if (settings.name == '/task-detail') {
                final task = settings.arguments as TaskModel;
                return MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(task: task),
                  settings: settings,
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(showRedirect: false);
        }
        return snapshot.data == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}
