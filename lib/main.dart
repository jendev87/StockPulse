import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/stock_take/bloc/stock_take_bloc.dart';
import 'repositories/inventory_repository.dart';
// ignore: unused_import
import 'repositories/mock_inventory_repository.dart';
import 'repositories/api_inventory_repository.dart';

void main() {
  runApp(const StockPulseApp());
}

class StockPulseApp extends StatelessWidget {
  final InventoryRepository? inventoryRepository;

  const StockPulseApp({
    super.key,
    this.inventoryRepository,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<InventoryRepository>(
      create: (_) => inventoryRepository ?? ApiInventoryRepository(),
      child: BlocProvider<StockTakeBloc>(
        create: (context) => StockTakeBloc(
          repository: context.read<InventoryRepository>(),
        )..add(const LoadActiveStockTake()),
        child: MaterialApp.router(
          title: 'StockPulse',
          theme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
