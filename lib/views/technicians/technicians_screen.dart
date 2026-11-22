import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/technicians_viewmodel.dart';
import '../widgets/common.dart';

/// Gestión de los técnicos del taller.
class TechniciansScreen extends ConsumerWidget {
  const TechniciansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techs = ref.watch(techniciansProvider);
    final workload = ref.watch(workloadProvider).value ?? const [];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Técnicos')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Agregar técnico',
        onPressed: () => _edit(context, ref, null),
        child: const Icon(Icons.person_add_alt),
      ),
      body: AsyncBody(
        value: techs,
        builder: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final t = list[i];
            final load = workload
                .where((w) => w.technician.id == t.id)
                .firstOrNull;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: t.active
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  child: Text(t.name[0]),
                ),
                title: Text(t.name),
                subtitle: Text(
                  t.active
                      ? '${load?.total ?? 0} orden(es) asignada(s)'
                      : 'Inactivo',
                ),
                trailing: Switch(
                  value: t.active,
                  onChanged: (v) => runAction(
                    context,
                    () => ref
                        .read(techniciansViewModelProvider)
                        .setActive(t.id, v),
                  ),
                ),
                onTap: () => _edit(context, ref, t),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Technician? t) async {
    final controller = TextEditingController(text: t?.name);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t == null ? 'Nuevo técnico' : 'Editar técnico'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final vm = ref.read(techniciansViewModelProvider);
              final ok = await runAction(
                dialogContext,
                () => t == null
                    ? vm.create(controller.text)
                    : vm.rename(t.id, controller.text),
              );
              if (ok && dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
