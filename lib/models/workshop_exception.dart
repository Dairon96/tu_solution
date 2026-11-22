/// Error de una regla de negocio del taller (por ejemplo, una orden que ya
/// tomó otro técnico o un repuesto sin existencias). El mensaje está pensado
/// para mostrarse tal cual al técnico.
class WorkshopException implements Exception {
  const WorkshopException(this.message);

  final String message;

  @override
  String toString() => message;
}
