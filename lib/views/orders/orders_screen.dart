import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/orders_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/order_card.dart';
import '../widgets/technician_picker.dart';
import 'reception_screen.dart';

/// Lista de órdenes con filtros por estado, técnico y búsqueda.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(ordersFilterProvider);
    final vm = ref.read(ordersFilterProvider.notifier);
    final orders = ref.watch(ordersListProvider);

    if (_search.text != filter.search) _search.text = filter.search;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes'),
        actions: [
          IconButton(
            tooltip: 'Filtrar por técnico',
            icon: Icon(
              filter.technician == null
                  ? Icons.person_search_outlined
                  : Icons.person_search,
            ),
            onPressed: () async {
              final t = await pickTechnician(context, title: 'Ver órdenes de…');
              if (t != null) vm.setTechnician(t);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Recibir equipo',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReceptionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: vm.setSearch,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, equipo, serie o #orden',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => vm.setSearch(''),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (filter.technician != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      avatar: const Icon(Icons.engineering, size: 18),
                      label: Text(filter.technician!.name),
                      selected: true,
                      onDeleted: () => vm.setTechnician(null),
                    ),
                  ),
                for (final scope in OrdersScope.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(scope.label),
                      selected: filter.scope == scope,
                      onSelected: (_) => vm.setScope(scope),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: AsyncBody(
              value: orders,
              builder: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_outlined,
                      message: 'No hay órdenes con estos filtros.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => OrderCard(summary: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
