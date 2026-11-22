import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart' as f;
import '../../data/database/app_database.dart';
import '../../models/workshop_exception.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../../viewmodels/orders_viewmodel.dart';

/// Hoja para elegir un repuesto del inventario y la cantidad usada.
Future<void> showAddPartSheet(BuildContext context, int orderId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (context, scroll) =>
          _AddPartSheet(orderId: orderId, scroll: scroll),
    ),
  );
}

class _AddPartSheet extends ConsumerStatefulWidget {
  const _AddPartSheet({required this.orderId, required this.scroll});

  final int orderId;
  final ScrollController scroll;

  @override
  ConsumerState<_AddPartSheet> createState() => _AddPartSheetState();
}

class _AddPartSheetState extends ConsumerState<_AddPartSheet> {
  String _search = '';

  Future<void> _choose(Part part) async {
    final qty = await showDialog<int>(
      context: context,
      builder: (_) => _QuantityDialog(part: part),
    );
    if (qty == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await ref
          .read(orderActionsProvider)
          .addPart(widget.orderId, part.id, qty);
      if (!mounted) return;
      Navigator.pop(context);
      final low = updated.stock <= updated.minStock;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            low
                ? '¡Atención! ${updated.name} quedó con ${updated.stock} '
                    'unidad(es): está por agotarse.'
                : 'Se usaron $qty × ${part.name}. Quedan ${updated.stock}.',
          ),
        ),
      );
    } on WorkshopException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = ref.watch(allPartsProvider).value ?? const [];
    final scheme = Theme.of(context).colorScheme;
    final term = _search.toLowerCase();
    final filtered = parts
        .where(
          (p) =>
              term.isEmpty ||
              p.name.toLowerCase().contains(term) ||
              p.code.toLowerCase().contains(term),
        )
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Usar repuesto',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o código',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scroll,
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final p = filtered[i];
              final out = p.stock == 0;
              final low = p.stock <= p.minStock;
              return ListTile(
                enabled: !out,
                leading: Icon(
                  out ? Icons.block : Icons.memory_outlined,
                  color: out ? scheme.error : scheme.primary,
                ),
                title: Text(p.name),
                subtitle: Text('${p.code} · ${f.money(p.price)}'),
                trailing: Text(
                  out ? 'Agotado' : '${p.stock} disp.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: out
                        ? scheme.error
                        : low
                            ? AppTheme.warningColor(scheme)
                            : null,
                  ),
                ),
                onTap: out ? null : () => _choose(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.part});

  final Part part;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.part;
    return AlertDialog(
      title: Text(p.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Disponibles: ${p.stock}'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '$_qty',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton.filledTonal(
                onPressed:
                    _qty < p.stock ? () => setState(() => _qty++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Subtotal: ${f.money(_qty * p.price)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _qty),
          child: const Text('Usar'),
        ),
      ],
    );
  }
}
