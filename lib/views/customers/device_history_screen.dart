import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart' as f;
import '../../models/view_data.dart';
import '../../viewmodels/customers_viewmodel.dart';
import '../orders/order_detail_screen.dart';
import '../widgets/common.dart';

/// Historial de un equipo: cada visita con lo que se reparó y las piezas
/// que se cambiaron.
class DeviceHistoryScreen extends ConsumerWidget {
  const DeviceHistoryScreen({super.key, required this.deviceId});

  final int deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceProvider(deviceId));
    final history = ref.watch(deviceHistoryProvider(deviceId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial del equipo')),
      body: AsyncBody(
        value: device,
        builder: (d) => d == null
            ? const EmptyState(icon: Icons.devices, message: 'No existe.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(d.type.icon, size: 36, color: scheme.primary),
                      title: Text(
                        '${d.brand} ${d.model}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${d.type.label} · Serie ${d.serialNumber}'),
                    ),
                  ),
                  AsyncBody(
                    value: history,
                    builder: (visits) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionTitle('${visits.length} visita(s) al taller'),
                        for (final v in visits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _VisitCard(detail: v),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final order = detail.summary.order;
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${f.orderNumber(order.id)} · ${f.date(order.receivedAt)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  StatusChip(order.status, dense: true),
                ],
              ),
              const SizedBox(height: 6),
              Text('Falla: ${order.reportedFault}', style: muted),
              if (detail.summary.technician != null)
                Text('Técnico: ${detail.summary.technician!.name}',
                    style: muted),
              if (detail.labor.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Trabajos',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                for (final l in detail.labor) Text('• ${l.description}'),
              ],
              if (detail.parts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Piezas cambiadas',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                for (final p in detail.parts)
                  Text('• ${p.line.quantity} × ${p.part.name}'),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total ${f.money(detail.total)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
