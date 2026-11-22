import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tu_solution/app.dart';
import 'package:tu_solution/data/database/app_database.dart';
import 'package:tu_solution/providers/database_providers.dart';

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
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.text('Tu Solution'), findsOneWidget);
    expect(find.text('Órdenes abiertas'), findsOneWidget);
    expect(find.text('Trabajo por técnico'), findsOneWidget);

    await tester.tap(find.text('Inventario'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(find.text('Batería iPhone 11'), findsOneWidget);

    await tester.tap(find.text('Clientes'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(find.text('Ana Rodríguez'), findsOneWidget);

    // Desmontar antes de cerrar la base para no dejar streams activos.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
