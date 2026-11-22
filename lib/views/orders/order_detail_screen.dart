import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart' as f;
import '../../models/enums.dart';
import '../../models/view_data.dart';
import '../../viewmodels/orders_viewmodel.dart';
import '../customers/customer_detail_screen.dart';
import '../customers/device_history_screen.dart';
import '../widgets/common.dart';
import '../widgets/technician_picker.dart';
import 'add_labor_sheet.dart';
import 'add_part_sheet.dart';

/// Detalle de una orden: responsable, estado, trabajos, repuestos y total.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Orden ${f.orderNumber(orderId)}'),
        actions: [
          if (detail.value case final d? when d.summary.status.isOpen)
            PopupMenuButton<String>(
              onSelected: (v) => _onMenu(context, ref, d, v),
              itemBuilder: (_) => [
                if (d.summary.isTaken)
                  const PopupMenuItem(
                    value: 'reassign',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz),
                      title: Text('Pasar a otro técnico'),
                    ),
                  ),
                if (d.summary.status == OrderStatus.enReparacion)
                  const PopupMenuItem(
                    value: 'release',
                    child: ListTile(
                      leading: Icon(Icons.person_remove_outlined),
                      title: Text('Liberar orden'),
                    ),
                  ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: ListTile(
                    leading: Icon(Icons.cancel_outlined),
                    title: Text('Cancelar orden'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: AsyncBody(
        value: detail,
        builder: (d) => d == null
            ? const EmptyState(
                icon: Icons.search_off,
                message: 'La orden no existe.',
              )
            : _DetailBody(detail: d),
      ),
      bottomNavigationBar: detail.value == null
          ? null
          : _ActionBar(detail: detail.value!),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    OrderDetail d,
    String action,
  ) async {
    final vm = ref.read(orderActionsProvider);
    switch (action) {
      case 'reassign':
        final t = await pickTechnician(
          context,
          title: '¿A quién se le pasa la orden?',
          excludeId: d.summary.order.technicianId,
        );
        if (t != null && context.mounted) {
          await runAction(
            context,
            () => vm.reassign(orderId, t.id),
            success: 'Ahora el responsable es ${t.name}.',
          );
        }
      case 'release':
        final ok = await confirm(
          context,
          title: 'Liberar orden',
          message:
              'La orden volverá a "Recibida" sin responsable para que otro técnico la tome.',
          confirmLabel: 'Liberar',
        );
        if (ok && context.mounted) {
          await runAction(context, () => vm.release(orderId),
              success: 'Orden liberada.');
        }
      case 'cancel':
        final reason = await _askCancelReason(context);
        if (reason != null && context.mounted) {
          await runAction(
            context,
            () => vm.cancel(orderId, reason),
            success: 'Orden cancelada. Los repuestos volvieron al almacén.',
          );
        }
    }
  }

  Future<String?> _askCancelReason(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar orden'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Los repuestos usados se devolverán al inventario. '
              'Esta acción no se puede deshacer.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Cancelar orden'),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = detail.summary;
    final order = s.order;
    final scheme = Theme.of(context).colorScheme;
    final canWork = order.status.allowsWork;
    final vm = ref.read(orderActionsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ---------- Estado y responsable ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(order.status),
                    const Spacer(),
                    Text(
                      'Recibida ${f.dateTime(order.receivedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatusTimeline(status: order.status),
                const Divider(height: 28),
                _ResponsibleBanner(summary: s),
              ],
            ),
          ),
        ),

        // ---------- Equipo y cliente ----------
        const SectionTitle('Equipo'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(s.device.type.icon, color: scheme.primary),
                title: Text(s.deviceLabel),
                subtitle: Text(
                  '${s.device.type.label} · Serie ${s.device.serialNumber}',
                ),
                trailing: const Icon(Icons.history),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeviceHistoryScreen(deviceId: s.device.id),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.person_outline, color: scheme.primary),
                title: Text(s.customer.name),
                subtitle: Text('Tel. ${s.customer.phone}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomerDetailScreen(customerId: s.customer.id),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.report_problem_outlined,
                      label: 'Falla reportada',
                      value: order.reportedFault,
                    ),
                    if (detail.receivedBy != null)
                      InfoRow(
                        icon: Icons.move_to_inbox_outlined,
                        label: 'Recibido por',
                        value: detail.receivedBy!.name,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ---------- Trabajos ----------
        SectionTitle(
          'Trabajos realizados',
          trailing: canWork
              ? TextButton.icon(
                  onPressed: () => showAddLaborSheet(context, order.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                )
              : null,
        ),
        Card(
          child: detail.labor.isEmpty
              ? ListTile(
                  leading: const Icon(Icons.handyman_outlined),
                  title: Text(
                    canWork
                        ? 'Aún no se anotan trabajos.'
                        : 'Sin trabajos anotados.',
                  ),
                )
              : Column(
                  children: [
                    for (final l in detail.labor)
                      ListTile(
                        leading: const Icon(Icons.handyman_outlined),
                        title: Text(l.description),
                        subtitle: Text(f.dateTime(l.createdAt)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f.money(l.cost),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (canWork)
                              IconButton(
                                tooltip: 'Quitar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => runAction(
                                  context,
                                  () => vm.removeLabor(l.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),

        // ---------- Repuestos ----------
        SectionTitle(
          'Repuestos utilizados',
          trailing: canWork
              ? TextButton.icon(
                  onPressed: () => showAddPartSheet(context, order.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                )
              : null,
        ),
        Card(
          child: detail.parts.isEmpty
              ? const ListTile(
                  leading: Icon(Icons.memory_outlined),
                  title: Text('No se han usado repuestos.'),
                )
              : Column(
                  children: [
                    for (final p in detail.parts)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.secondaryContainer,
                          child: Text(
                            '${p.line.quantity}',
                            style:
                                TextStyle(color: scheme.onSecondaryContainer),
                          ),
                        ),
                        title: Text(p.part.name),
                        subtitle: Text(
                          '${p.part.code} · ${p.line.quantity} × ${f.money(p.line.unitPrice)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f.money(p.subtotal),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (canWork)
                              IconButton(
                                tooltip: 'Quitar y devolver al almacén',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => runAction(
                                  context,
                                  () => vm.removePart(p.line.id),
                                  success: '${p.part.name} devuelto al almacén.',
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),

        // ---------- Total ----------
        const SizedBox(height: 16),
        Card(
          color: scheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TotalRow('Mano de obra', f.money(detail.laborTotal)),
                _TotalRow('Repuestos', f.money(detail.partsTotal)),
                const Divider(height: 20),
                _TotalRow('Total', f.money(detail.total), bold: true),
              ],
            ),
          ),
        ),

        // ---------- Notas ----------
        const SectionTitle('Notas'),
        _NotesCard(orderId: order.id, notes: order.notes),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSecondaryContainer;
    final style = TextStyle(
      color: color,
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Muestra bien visible quién es el responsable de la orden.
class _ResponsibleBanner extends StatelessWidget {
  const _ResponsibleBanner({required this.summary});

  final OrderSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tech = summary.technician;
    final order = summary.order;

    if (tech == null) {
      return Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.tertiaryContainer,
            child: Icon(Icons.person_off_outlined,
                color: scheme.onTertiaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              order.status.isOpen
                  ? 'Nadie ha tomado esta orden todavía.'
                  : 'Orden sin responsable.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: scheme.primary,
          child: Text(tech.name[0], style: TextStyle(color: scheme.onPrimary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Responsable',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              Text(
                tech.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (order.takenAt != null)
                Text(
                  'La tomó ${f.relative(order.takenAt!)}',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Línea de progreso recibida → en reparación → lista → entregada.
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});

  final OrderStatus status;

  static const _steps = [
    OrderStatus.recibida,
    OrderStatus.enReparacion,
    OrderStatus.lista,
    OrderStatus.entregada,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (status == OrderStatus.cancelada) {
      return Text(
        'Esta orden fue cancelada.',
        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w500),
      );
    }
    final current = _steps.indexOf(status);
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? AppTheme.statusColor(_steps[i], scheme)
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _steps[i].label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        i == current ? FontWeight.w700 : FontWeight.w400,
                    color: i <= current
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (i < _steps.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

/// Botón principal según el estado: tomar, marcar lista o entregar.
class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = detail.summary.order;
    final vm = ref.read(orderActionsProvider);
    final buttons = <Widget>[];

    switch (order.status) {
      case OrderStatus.recibida:
        buttons.add(
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.pan_tool_outlined),
              label: const Text('Tomar orden'),
              onPressed: () async {
                final t = await pickTechnician(
                  context,
                  title: '¿Quién toma la orden?',
                );
                if (t != null && context.mounted) {
                  await runAction(
                    context,
                    () => vm.take(order.id, t.id),
                    success: '${t.name} es ahora el responsable.',
                  );
                }
              },
            ),
          ),
        );
      case OrderStatus.enReparacion:
        buttons.add(
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Marcar como lista'),
              onPressed: () => runAction(
                context,
                () => vm.markReady(order.id),
                success: 'Equipo listo para entregar.',
              ),
            ),
          ),
        );
      case OrderStatus.lista:
        buttons
          ..add(
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('Reabrir'),
                onPressed: () => runAction(
                  context,
                  () => vm.reopen(order.id),
                  success: 'La orden volvió a reparación.',
                ),
              ),
            ),
          )
          ..add(const SizedBox(width: 12))
          ..add(
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.handshake_outlined),
                label: const Text('Entregar'),
                onPressed: () async {
                  final ok = await confirm(
                    context,
                    title: 'Entregar equipo',
                    message:
                        'Se entrega el equipo a ${detail.summary.customer.name}. '
                        'Total a cobrar: ${f.money(detail.total)}.',
                    confirmLabel: 'Entregar',
                  );
                  if (ok && context.mounted) {
                    await runAction(
                      context,
                      () => vm.deliver(order.id),
                      success: 'Equipo entregado.',
                    );
                  }
                },
              ),
            ),
          );
      case OrderStatus.entregada:
      case OrderStatus.cancelada:
        return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(children: buttons),
      ),
    );
  }
}

class _NotesCard extends ConsumerStatefulWidget {
  const _NotesCard({required this.orderId, required this.notes});

  final int orderId;
  final String? notes;

  @override
  ConsumerState<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<_NotesCard> {
  late final _controller = TextEditingController(text: widget.notes ?? '');
  bool _dirty = false;

  @override
  void didUpdateWidget(covariant _NotesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty && widget.notes != oldWidget.notes) {
      _controller.text = widget.notes ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          onChanged: (_) => setState(() => _dirty = true),
          decoration: const InputDecoration(
            hintText: 'Diagnóstico, observaciones, contraseña de desbloqueo…',
          ),
        ),
        if (_dirty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FilledButton.tonal(
              onPressed: () async {
                final ok = await runAction(
                  context,
                  () => ref
                      .read(orderActionsProvider)
                      .saveNotes(widget.orderId, _controller.text),
                  success: 'Notas guardadas.',
                );
                if (ok && mounted) setState(() => _dirty = false);
              },
              child: const Text('Guardar notas'),
            ),
          ),
      ],
    );
  }
}
