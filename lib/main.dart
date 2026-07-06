import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/stock/presentation/stock_screen.dart';

void main() {
  runApp(const ProviderScope(child: MisSkladApp()));
}

final _authRepoProvider = Provider((_) => AuthRepository());

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final loggedIn = await ref.read(_authRepoProvider).isLoggedIn();
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/stock';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/stock', builder: (_, __) => const StockScreen()),
    ],
  );
});

class MisSkladApp extends ConsumerWidget {
  const MisSkladApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'Склад МИС',
      routerConfig: router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A6FE0),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A6FE0),
        brightness: Brightness.dark,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
