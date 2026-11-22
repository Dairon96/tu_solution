import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../../viewmodels/orders_viewmodel.dart';
import '../../viewmodels/shell_viewmodel.dart';
import '../orders/reception_screen.dart';
import '../technicians/technicians_screen.dart';
import '../widgets/common.dart';
import '../widgets/order_card.dart';

/// Panel de inicio: estado del taller de un vistazo.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _goToOrders(WidgetRef ref, OrdersScope scope) {
    ref.read(ordersFilterProvider.notifier).showScope(scope);
    ref.read(shellTabProvider.notifier).go(ShellTab.ordenes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(statusCountsProvider).value ?? const {};
    final workload = ref.watch(workloadProvider);
    final lowStock = ref.watch(lowStockProvider).value ?? const [];
    final untaken = ref.watch(untakenOrdersProvider).value ?? const [];
    final scheme = Theme.of(context).colorScheme;

    final openTotal =
        OrderStatus.openStatuses.fold<int>(0, (s, st) => s + (counts[st] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.build_circle),
            SizedBox(width: 8),
            Text('Tu Solution'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Técnicos',
            icon: const Icon(Icons.engineering_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TechniciansScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReceptionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Recibir equipo'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // ---------- Resumen de órdenes abiertas ----------
          Card(
            color: scheme.primaryContainer,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _goToOrders(ref, OrdersScope.abiertas),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Órdenes abiertas',
                            style: TextStyle(color: scheme.onPrimaryContainer),
                          ),
                          Text(
                            '$openTotal',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${untaken.length} sin tomar',
                            style: TextStyle(color: scheme.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.assignment,
                        size: 56,
                        color: scheme.onPrimaryContainer.withValues(alpha: .5)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (status, scope) in [
                (OrderStatus.recibida, OrdersScope.recibida),
                (OrderStatus.enReparacion, OrdersScope.enReparacion),
                (OrderStatus.lista, OrdersScope.lista),
              ]) ...[
                Expanded(
                  child: _StatusTile(
                    status: status,
                    count: counts[status] ?? 0,
                    onTap: () => _goToOrders(ref, scope),
                  ),
                ),
                if (status != OrderStatus.lista) const SizedBox(width: 8),
              ],
            ],
          ),

          // ---------- Repuestos por agotarse ----------
          if (lowStock.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: AppTheme.warningColor(scheme).withValues(alpha: .12),
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded,
                    color: AppTheme.warningColor(scheme)),
                title: Text(
                  '${lowStock.length} repuesto(s) por agotarse',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  lowStock
                      .take(3)
                      .map((p) => '${p.name} (${p.stock})')
                      .join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(inventoryFilterProvider.notifier).setOnlyLow(true);
                  ref.read(shellTabProvider.notifier).go(ShellTab.inventario);
                },
              ),
            ),
          ],

          // ---------- Carga de trabajo ----------
          const SectionTitle('Trabajo por técnico'),
          AsyncBody(
            value: workload,
            builder: (list) => Card(
              child: Column(
                children: [
                  for (final w in list)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.secondaryContainer,
                        child: Text(
                          w.technician.name[0],
                          style:
                              TextStyle(color: scheme.onSecondaryContainer),
                        ),
                      ),
                      title: Text(w.technician.name),
                      subtitle: Text(
                        '${w.inRepair} en reparación · ${w.ready} listas',
                      ),
                      trailing: _LoadBadge(count: w.total),
                      onTap: () {
                        ref
                            .read(ordersFilterProvider.notifier)
                            .showTechnician(w.technician);
                        ref
                            .read(shellTabProvider.notifier)
                            .go(ShellTab.ordenes);
                      },
                    ),
                ],
              ),
            ),
          ),

          // ---------- Órdenes esperando técnico ----------
          SectionTitle(
            'Esperando técnico',
            trailing: untaken.isEmpty
                ? null
                : TextButton(
                    onPressed: () => _goToOrders(ref, OrdersScope.sinTomar),
                    child: const Text('Ver todas'),
                  ),
          ),
          if (untaken.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check),
                title: Text('Todas las órdenes tienen responsable'),
              ),
            )
          else
            for (final o in untaken.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OrderCard(summary: o),
              ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.status,
    required this.count,
    required this.onTap,
  });

  final OrderStatus status;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status, Theme.of(context).colorScheme);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(status.icon, color: color),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                status.label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadBadge extends StatelessWidget {
  const _LoadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: count == 0 ? scheme.surfaceContainerHighest : scheme.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: count == 0 ? scheme.onSurfaceVariant : scheme.onPrimary,
        ),
      ),
    );
  }
}
