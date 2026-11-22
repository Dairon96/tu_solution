import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellTab { inicio, ordenes, clientes, inventario }

/// Pestaña seleccionada en la barra inferior. Se comparte para que el panel
/// de inicio pueda llevar al usuario a otra pestaña ya filtrada.
class ShellViewModel extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.inicio;

  void go(ShellTab tab) => state = tab;
}

final shellTabProvider =
    NotifierProvider<ShellViewModel, ShellTab>(ShellViewModel.new);
