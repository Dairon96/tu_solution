import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart' as f;
import '../../data/database/app_database.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../widgets/common.dart';

/// Alta o edición de un repuesto.
class PartFormScreen extends ConsumerStatefulWidget {
  const PartFormScreen({super.key, this.part});

  /// Null = repuesto nuevo.
  final Part? part;

  @override
  ConsumerState<PartFormScreen> createState() => _PartFormScreenState();
}

class _PartFormScreenState extends ConsumerState<PartFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.part?.code);
  late final _name = TextEditingController(text: widget.part?.name);
  late final _price =
      TextEditingController(text: widget.part?.price.toStringAsFixed(2));
  late final _stock =
      TextEditingController(text: widget.part?.stock.toString() ?? '0');
  late final _minStock =
      TextEditingController(text: widget.part?.minStock.toString() ?? '2');

  @override
  void dispose() {
    for (final c in [_code, _name, _price, _stock, _minStock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = await runAction(
      context,
      () => ref.read(inventoryViewModelProvider).save(
            PartFormData(
              code: _code.text,
              name: _name.text,
              price: f.parseAmount(_price.text)!,
              stock: int.parse(_stock.text),
              minStock: int.parse(_minStock.text),
            ),
            id: widget.part?.id,
          ),
      success: widget.part == null ? 'Repuesto creado.' : 'Repuesto guardado.',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Campo obligatorio' : null;

  String? _integer(String? v) =>
      int.tryParse(v ?? '') == null ? 'Número entero' : null;

  @override
  Widget build(BuildContext context) {
    final editing = widget.part != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar repuesto' : 'Nuevo repuesto')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.memory_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) =>
                  f.parseAmount(v ?? '') == null ? 'Monto inválido' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Existencias'),
                    validator: _integer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minStock,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Stock mínimo',
                    ),
                    validator: _integer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando las existencias lleguen al stock mínimo o menos, '
              'el repuesto aparecerá como "por agotarse".',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
