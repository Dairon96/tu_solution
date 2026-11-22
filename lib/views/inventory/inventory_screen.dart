import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart' as f;
import '../../data/database/app_database.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../widgets/common.dart';
import 'part_form_screen.dart';

/// Almacén de repuestos con aviso de los que están por agotarse.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(inventoryFilterProvider);
    final vm = ref.read(inventoryFilterProvider.notifier);
    final parts = ref.watch(partsListProvider);
    final lowCount = ref.watch(lowStockProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Repuesto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: vm.setSearch,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o código',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: !filter.onlyLow,
                  onSelected: (_) => vm.setOnlyLow(false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: Text('Por agotarse ($lowCount)'),
                  selected: filter.onlyLow,
                  onSelected: (_) => vm.setOnlyLow(true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncBody(
              value: parts,
              builder: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: filter.onlyLow
                          ? 'Ningún repuesto está por agotarse.'
                          : 'No hay repuestos registrados.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _PartCard(part: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartCard extends ConsumerWidget {
  const _PartCard({required this.part});

  final Part part;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final out = part.stock == 0;
    final low = part.stock <= part.minStock;
    final stockColor = out
        ? scheme.error
        : low
            ? AppTheme.warningColor(scheme)
            : scheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PartFormScreen(part: part)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${part.stock}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: stockColor,
                      ),
                    ),
                    Text('uds.',
                        style: TextStyle(fontSize: 10, color: stockColor)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${part.code} · ${f.money(part.price)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (low)
                      Text(
                        out
                            ? 'Agotado'
                            : 'Por agotarse (mínimo ${part.minStock})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: stockColor,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Entrada de mercancía',
                icon: const Icon(Icons.add_box_outlined),
                onPressed: () => _restock(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restock(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final qty = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Entrada: ${part.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Unidades recibidas',
            helperText: 'Existencias actuales: ${part.stock}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, int.tryParse(controller.text)),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (qty == null || !context.mounted) return;
    await runAction(
      context,
      () => ref.read(inventoryViewModelProvider).addStock(part.id, qty),
      success: 'Se agregaron $qty unidad(es) de ${part.name}.',
    );
  }
}
