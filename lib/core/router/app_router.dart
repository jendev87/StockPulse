import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/reconciliation/screens/reconciliation_screen.dart';
import '../../features/scanner/screens/ai_vision_screen.dart';
import '../../features/scanner/screens/scanner_screen.dart';
import '../../features/stock_take/screens/count_screen.dart';
import '../../features/stock_take/screens/stock_take_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/stock-take',
        builder: (context, state) => const StockTakeScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/ai-vision',
        builder: (context, state) => const AiVisionScreen(),
      ),
      GoRoute(
        path: '/count/:sku',
        builder: (context, state) {
          final sku = state.pathParameters['sku'] ?? '';
          return CountScreen(sku: sku);
        },
      ),
      GoRoute(
        path: '/reconciliation',
        builder: (context, state) => const ReconciliationScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}
