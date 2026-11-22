import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart' as f;
import '../../viewmodels/orders_viewmodel.dart';
import '../widgets/common.dart';

Future<void> showAddLaborSheet(BuildContext context, int orderId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AddLaborSheet(orderId: orderId),
  );
}

class _AddLaborSheet extends ConsumerStatefulWidget {
  const _AddLaborSheet({required this.orderId});

  final int orderId;

  @override
  ConsumerState<_AddLaborSheet> createState() => _AddLaborSheetState();
}

class _AddLaborSheetState extends ConsumerState<_AddLaborSheet> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _cost = TextEditingController();

  static const _suggestions = [
    'Diagnóstico',
    'Cambio de pantalla',
    'Cambio de batería',
    'Cambio de conector de carga',
    'Limpieza interna',
    'Reinstalación de sistema',
  ];

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = await runAction(
      context,
      () => ref.read(orderActionsProvider).addLabor(
            widget.orderId,
            _description.text,
            f.parseAmount(_cost.text)!,
          ),
      success: 'Trabajo anotado.',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Anotar trabajo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final s in _suggestions)
                  ActionChip(
                    label: Text(s),
                    onPressed: () => _description.text = s,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción del trabajo',
                prefixIcon: Icon(Icons.handyman_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Describe el trabajo' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Costo de mano de obra',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                final n = f.parseAmount(v ?? '');
                if (n == null) return 'Escribe un monto válido';
                if (n < 0) return 'No puede ser negativo';
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
