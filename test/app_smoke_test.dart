import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tu_solution/app.dart';
import 'package:tu_solution/data/database/app_database.dart';
import 'package:tu_solution/providers/database_providers.dart';

/// Deja que Drift responda (fuera del reloj falso del test) y redibuja.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Prueba de humo: la app arranca con los datos de demo y se puede navegar.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('la app muestra el inicio y navega a las pestañas',
      (tester) async {
    await initializeDateFormatting('es');
    final db = AppDatabase.forTesting(
      NativeDatabase.memory(),
      seedDemoData: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const TuSolutionApp(),
      ),
    );
    await settle(tester);

    expect(find.text('Tu Solution'), findsOneWidget);
    expect(find.text('Órdenes abiertas'), findsOneWidget);
    expect(find.text('Trabajo por técnico'), findsOneWidget);

    await tester.tap(find.text('Inventario'));
    await settle(tester);
    expect(find.text('Batería iPhone 11'), findsOneWidget);

    await tester.tap(find.text('Clientes'));
    await settle(tester);
    expect(find.text('Ana Rodríguez'), findsOneWidget);

    // Desmontar la app para cancelar los streams de Drift. La base está en
    // memoria y se descarta al terminar la prueba.
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}
