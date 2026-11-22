import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart' as f;
import '../../models/view_data.dart';
import '../orders/order_detail_screen.dart';
import 'common.dart';

/// Tarjeta de una orden: número, equipo, dueño, estado y responsable.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.summary, this.showCustomer = true});

  final OrderSummary summary;
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final order = summary.order;
    final tech = summary.technician;

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
                    f.orderNumber(order.id),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    f.relative(order.receivedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  StatusChip(order.status, dense: true),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(summary.device.type.icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.deviceLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                order.reportedFault,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (showCustomer) ...[
                    Icon(Icons.person_outline,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        summary.customer.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  _Responsible(name: tech?.name, isOpen: order.status.isOpen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Responsible extends StatelessWidget {
  const _Responsible({required this.name, required this.isOpen});

  final String? name;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (name == null) {
      if (!isOpen) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Sin tomar',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onTertiaryContainer,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            name![0],
            style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 6),
        Text(name!, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
