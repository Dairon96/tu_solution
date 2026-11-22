import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../models/enums.dart';
import '../models/view_data.dart';
import '../providers/database_providers.dart';

/// Estado del panel de inicio: todo se observa con streams de Drift, así el
/// panel se mantiene al día sin recargar.

final statusCountsProvider = StreamProvider<Map<OrderStatus, int>>(
  (ref) => ref.watch(ordersDaoProvider).watchStatusCounts(),
);

final workloadProvider = StreamProvider<List<TechnicianWorkload>>(
  (ref) => ref.watch(techniciansDaoProvider).watchWorkload(),
);

final lowStockProvider = StreamProvider<List<Part>>(
  (ref) => ref.watch(partsDaoProvider).watchLowStock(),
);

/// Órdenes recibidas que nadie ha tomado todavía.
final untakenOrdersProvider = StreamProvider<List<OrderSummary>>(
  (ref) => ref.watch(ordersDaoProvider).watchOrders(
        statuses: {OrderStatus.recibida},
        onlyUntaken: true,
      ),
);
