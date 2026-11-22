import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../viewmodels/customers_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/order_card.dart';
import 'device_history_screen.dart';

/// Cliente: datos, equipos y su historial de reparaciones.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerProvider(customerId));
    final devices = ref.watch(customerDevicesProvider(customerId));
    final orders = ref.watch(customerOrdersProvider(customerId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cliente'),
        actions: [
          if (customer.value != null)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context, ref, customer.value!),
            ),
        ],
      ),
      body: AsyncBody(
        value: customer,
        builder: (c) => c == null
            ? const EmptyState(icon: Icons.person_off, message: 'No existe.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              c.name[0],
                              style: TextStyle(
                                fontSize: 24,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text('Tel. ${c.phone}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SectionTitle('Equipos'),
                  AsyncBody(
                    value: devices,
                    builder: (list) => Card(
                      child: Column(
                        children: [
                          if (list.isEmpty)
                            const ListTile(title: Text('Sin equipos.')),
                          for (final d in list)
                            ListTile(
                              leading: Icon(d.device.type.icon,
                                  color: scheme.primary),
                              title:
                                  Text('${d.device.brand} ${d.device.model}'),
                              subtitle: Text(
                                'Serie ${d.device.serialNumber} · '
                                '${d.visits} visita(s)',
                              ),
                              trailing: const Icon(Icons.history),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeviceHistoryScreen(
                                    deviceId: d.device.id,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SectionTitle('Historial de reparaciones'),
                  AsyncBody(
                    value: orders,
                    builder: (list) => Column(
                      children: [
                        if (list.isEmpty)
                          const Card(
                            child: ListTile(title: Text('Sin órdenes.')),
                          ),
                        for (final o in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OrderCard(summary: o, showCustomer: false),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Customer c) async {
    final name = TextEditingController(text: c.name);
    final phone = TextEditingController(text: c.phone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await runAction(
                dialogContext,
                () => ref
                    .read(customersViewModelProvider)
                    .update(c.id, name.text, phone.text),
              );
              if (ok && dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente actualizado.')),
      );
    }
  }
}
