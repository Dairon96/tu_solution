import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/shell_viewmodel.dart';
import 'views/customers/customers_screen.dart';
import 'views/home/home_screen.dart';
import 'views/inventory/inventory_screen.dart';
import 'views/orders/orders_screen.dart';

class TuSolutionApp extends StatelessWidget {
  const TuSolutionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tu Solution',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}

/// Estructura principal con barra de navegación inferior.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _pages = [
    HomeScreen(),
    OrdersScreen(),
    CustomersScreen(),
    InventoryScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellTabProvider);
    final lowStock = ref.watch(lowStockProvider).value?.length ?? 0;

    return Scaffold(
      body: IndexedStack(index: tab.index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) =>
            ref.read(shellTabProvider.notifier).go(ShellTab.values[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Órdenes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: lowStock > 0,
              label: Text('$lowStock'),
              child: const Icon(Icons.inventory_2_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: lowStock > 0,
              label: Text('$lowStock'),
              child: const Icon(Icons.inventory_2),
            ),
            label: 'Inventario',
          ),
        ],
      ),
    );
  }
}
