import 'package:flutter/material.dart';

import '../../models/enums.dart';

/// Tema central de la app (Material 3 + Poppins), con modo claro y oscuro.
class AppTheme {
  AppTheme._();

  static const seed = Color(0xFF0F6E5A);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: const ChipThemeData(showCheckmark: false),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  /// Color asociado a cada estado de orden (se adapta al modo oscuro).
  static Color statusColor(OrderStatus status, ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return switch (status) {
      OrderStatus.recibida => dark ? Colors.blue.shade200 : Colors.blue.shade700,
      OrderStatus.enReparacion =>
        dark ? Colors.orange.shade200 : Colors.orange.shade800,
      OrderStatus.lista => dark ? Colors.green.shade300 : Colors.green.shade700,
      OrderStatus.entregada => scheme.outline,
      OrderStatus.cancelada => scheme.error,
    };
  }

  static Color warningColor(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
          ? Colors.amber.shade300
          : Colors.amber.shade900;
}
