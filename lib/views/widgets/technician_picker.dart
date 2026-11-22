import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../viewmodels/technicians_viewmodel.dart';

/// Hoja inferior para elegir un técnico. Como la app no tiene inicio de
/// sesión, cada acción que depende de una persona pregunta quién la hace.
Future<Technician?> pickTechnician(
  BuildContext context, {
  required String title,
  int? excludeId,
}) {
  return showModalBottomSheet<Technician>(
    context: context,
    showDragHandle: true,
    builder: (context) => _TechnicianSheet(title: title, excludeId: excludeId),
  );
}

class _TechnicianSheet extends ConsumerWidget {
  const _TechnicianSheet({required this.title, this.excludeId});

  final String title;
  final int? excludeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techs = ref.watch(activeTechniciansProvider).value ?? const [];
    final list = techs.where((t) => t.id != excludeId).toList();
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No hay otros técnicos activos.'),
            ),
          for (final t in list)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  t.name[0],
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
              title: Text(t.name),
              onTap: () => Navigator.pop(context, t),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
