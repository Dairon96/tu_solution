import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/daos/orders_dao.dart';
import '../../data/database/app_database.dart';
import '../../models/enums.dart';
import '../../models/workshop_exception.dart';
import '../../viewmodels/reception_viewmodel.dart';
import '../../viewmodels/technicians_viewmodel.dart';
import '../widgets/common.dart';
import 'order_detail_screen.dart';

/// Formulario de entrada de un equipo al taller (crea la orden).
class ReceptionScreen extends ConsumerStatefulWidget {
  const ReceptionScreen({super.key});

  @override
  ConsumerState<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends ConsumerState<ReceptionScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _serial = TextEditingController();
  final _fault = TextEditingController();

  DeviceType _type = DeviceType.celular;
  int? _receivedById;

  /// Aviso cuando el número de serie ya está registrado.
  String? _serialInfo;

  @override
  void dispose() {
    for (final c in [_phone, _name, _brand, _model, _serial, _fault]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onPhoneChanged(String phone) async {
    final vm = ref.read(receptionProvider.notifier);
    final customer = await vm.lookupPhone(phone);
    if (customer != null && mounted) {
      setState(() => _name.text = customer.name);
    }
  }

  void _useDevice(Device? d) {
    ref.read(receptionProvider.notifier).selectDevice(d);
    setState(() {
      _serialInfo = null;
      if (d == null) {
        _brand.clear();
        _model.clear();
        _serial.clear();
        _type = DeviceType.celular;
      } else {
        _brand.text = d.brand;
        _model.text = d.model;
        _serial.text = d.serialNumber;
        _type = d.type;
      }
    });
  }

  Future<void> _onSerialDone() async {
    final state = ref.read(receptionProvider);
    if (state.selectedDevice != null) return;
    final device =
        await ref.read(receptionProvider.notifier).lookupSerial(_serial.text);
    if (!mounted) return;
    setState(() {
      if (device == null) {
        _serialInfo = null;
      } else {
        _brand.text = device.brand;
        _model.text = device.model;
        _type = device.type;
        _serialInfo = 'Este equipo ya estuvo en el taller: se agregará '
            'la nueva visita a su historial.';
      }
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final orderId = await ref.read(receptionProvider.notifier).submit(
            ReceptionData(
              customerName: _name.text,
              customerPhone: _phone.text,
              deviceType: _type,
              brand: _brand.text,
              model: _model.text,
              serialNumber: _serial.text,
              reportedFault: _fault.text,
              receivedById: _receivedById!,
            ),
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Equipo recibido. Orden creada.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
      );
    } on WorkshopException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Campo obligatorio' : null;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receptionProvider);
    final techs = ref.watch(activeTechniciansProvider).value ?? const [];
    final scheme = Theme.of(context).colorScheme;
    final lockedDevice = state.selectedDevice != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Recibir equipo')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            // ---------------- Dueño ----------------
            const SectionTitle('Dueño'),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
                helperText: 'Si el cliente ya existe se reconoce por su teléfono',
              ),
              onChanged: _onPhoneChanged,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre',
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: state.existingCustomer == null
                    ? null
                    : Tooltip(
                        message: 'Cliente registrado',
                        child: Icon(Icons.verified, color: scheme.primary),
                      ),
              ),
              readOnly: state.existingCustomer != null,
              validator: _required,
            ),

            // ---------------- Equipo ----------------
            const SectionTitle('Equipo'),
            if (state.customerDevices.isNotEmpty) ...[
              Text(
                'Equipos que este cliente ya trajo:',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final d in state.customerDevices)
                    ChoiceChip(
                      avatar: Icon(d.type.icon, size: 18),
                      label: Text('${d.brand} ${d.model}'),
                      selected: state.selectedDevice?.id == d.id,
                      onSelected: (sel) => _useDevice(sel ? d : null),
                    ),
                  ChoiceChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Equipo nuevo'),
                    selected: state.selectedDevice == null,
                    onSelected: (_) => _useDevice(null),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SegmentedButton<DeviceType>(
              segments: [
                for (final t in DeviceType.values)
                  ButtonSegment(
                    value: t,
                    icon: Icon(t.icon),
                    label: Text(t.label),
                  ),
              ],
              selected: {_type},
              onSelectionChanged:
                  lockedDevice ? null : (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brand,
                    readOnly: lockedDevice,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Marca'),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _model,
                    readOnly: lockedDevice,
                    decoration: const InputDecoration(labelText: 'Modelo'),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Focus(
              onFocusChange: (has) {
                if (!has) _onSerialDone();
              },
              child: TextFormField(
                controller: _serial,
                readOnly: lockedDevice,
                decoration: const InputDecoration(
                  labelText: 'Número de serie / IMEI',
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
                validator: _required,
                onFieldSubmitted: (_) => _onSerialDone(),
              ),
            ),
            if (_serialInfo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _serialInfo!,
                        style: TextStyle(fontSize: 12, color: scheme.primary),
                      ),
                    ),
                  ],
                ),
              ),

            // ---------------- Falla ----------------
            const SectionTitle('Falla reportada'),
            TextFormField(
              controller: _fault,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: '¿Qué le pasa al equipo según el dueño?',
              ),
              validator: _required,
            ),

            const SectionTitle('Recibido por'),
            DropdownButtonFormField<int>(
              initialValue: _receivedById,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.engineering_outlined),
              ),
              hint: const Text('Técnico que recibe el equipo'),
              items: [
                for (final t in techs)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => setState(() => _receivedById = v),
              validator: (v) => v == null ? 'Elige quién lo recibe' : null,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: state.saving ? null : _submit,
              icon: state.saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Registrar orden'),
            ),
          ],
        ),
      ),
    );
  }
}
