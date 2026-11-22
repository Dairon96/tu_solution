import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'es', symbol: r'$', decimalDigits: 2);
final _date = DateFormat('dd/MM/yyyy');
final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

String money(double value) => _money.format(value);

String date(DateTime value) => _date.format(value);

String dateTime(DateTime value) => _dateTime.format(value);

/// "hace 3 h", "hace 2 días"...
String relative(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 30) return 'hace ${diff.inDays} días';
  return date(value);
}

String orderNumber(int id) => '#${id.toString().padLeft(4, '0')}';

/// Convierte texto con coma o punto decimal en número.
double? parseAmount(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));
