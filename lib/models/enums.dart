import 'package:flutter/material.dart';

/// Estados por los que pasa una orden de reparación.
///
/// Flujo normal: recibida → enReparacion → lista → entregada.
/// Desde cualquier estado abierto la orden puede quedar cancelada.
enum OrderStatus {
  recibida('Recibida', Icons.inbox_outlined),
  enReparacion('En reparación', Icons.build_outlined),
  lista('Lista', Icons.check_circle_outline),
  entregada('Entregada', Icons.handshake_outlined),
  cancelada('Cancelada', Icons.cancel_outlined);

  const OrderStatus(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Una orden está abierta mientras el equipo sigue en el taller.
  bool get isOpen =>
      this == recibida || this == enReparacion || this == lista;

  /// Solo se anotan trabajos y repuestos mientras se está reparando.
  bool get allowsWork => this == enReparacion;

  static const openStatuses = [recibida, enReparacion, lista];
}

/// Tipos de equipo que repara el taller.
enum DeviceType {
  celular('Celular', Icons.smartphone),
  tablet('Tablet', Icons.tablet_android),
  laptop('Laptop', Icons.laptop);

  const DeviceType(this.label, this.icon);

  final String label;
  final IconData icon;
}
