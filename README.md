# Tu Solution — Gestión de reparaciones

Aplicación Android en **Flutter** para el taller "Tu Solution" (reparación de celulares, tablets y laptops).
Segundo Examen Parcial — Programación para Dispositivos Móviles, Ingeniería Informática, 3er año.

- Persistencia local en SQLite con **Drift**: funciona sin internet y los datos se conservan al cerrar la app.
- Gestión de estado con **Riverpod**.
- Arquitectura **MVVM**: View (widgets) → ViewModel (Riverpod) → DAO (Drift) → SQLite.
- Material 3, tipografía Poppins, modo claro y oscuro.

## Capturas

Las capturas de la app en un emulador o teléfono Android están en la carpeta [`screenshots/`](screenshots/).

| Inicio | Órdenes | Detalle de orden |
|---|---|---|
| ![](screenshots/01_inicio.png) | ![](screenshots/02_ordenes.png) | ![](screenshots/03_detalle_orden.png) |

| Recibir equipo | Historial del equipo | Inventario |
|---|---|---|
| ![](screenshots/04_recibir_equipo.png) | ![](screenshots/05_historial_equipo.png) | ![](screenshots/06_inventario.png) |

## Cómo abrir y ejecutar

### Requisitos

- Flutter 3.38 o superior (desarrollado con Flutter 3.47 / Dart 3.13).
- Android SDK (Android Studio) y un emulador Android o un teléfono con depuración USB.

### Paso a paso

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/Dairon96/tu_solution.git
   cd tu_solution
   ```
2. Descargar dependencias:
   ```bash
   flutter pub get
   ```
3. (Opcional) Regenerar el código de Drift. Los archivos `*.g.dart` ya están en el repositorio, así que solo hace falta si se cambian tablas o DAOs:
   ```bash
   dart run build_runner build
   ```
   > En Windows, si la ruta del proyecto tiene tildes o espacios y falla la compilación AOT, usar `dart run build_runner build --force-jit`.
4. Abrir un emulador Android (Android Studio → Device Manager) o conectar un teléfono, y comprobarlo con:
   ```bash
   flutter devices
   ```
5. Ejecutar la aplicación:
   ```bash
   flutter run
   ```
   O generar un APK instalable: `flutter build apk --release` (queda en `build/app/outputs/flutter-apk/app-release.apk`).
6. Ejecutar las pruebas (opcional):
   ```bash
   flutter test
   ```

La primera vez que se abre, la app crea la base de datos con los **3 técnicos** del taller y **datos de ejemplo** (repuestos, clientes, equipos y órdenes en distintos estados) para la demostración.
Para empezar con la base vacía, desinstalar la app y cambiar `AppDatabase()` por `AppDatabase(seedDemoData: false)` en `lib/providers/database_providers.dart`.

## Funcionalidades

| Necesidad del taller | Cómo lo resuelve la app |
|---|---|
| Saber quién tomó cada equipo | Botón **Tomar orden**: se elige el técnico y su nombre queda visible en la lista y el detalle. Si otro técnico intenta tomarla, la app lo impide e indica quién la tiene. Se puede **pasar a otro técnico** o **liberar**. |
| Estado de cada equipo | Flujo **Recibida → En reparación → Lista → Entregada**, o **Cancelada**. Línea de progreso en el detalle y filtros por estado. |
| Carga de cada técnico | En el inicio: órdenes en reparación y listas de cada técnico; al tocarlo se ven sus órdenes. |
| Stock que no cuadra | Al usar un repuesto en una orden las existencias bajan solas (en una transacción). Si se quita el repuesto o se cancela la orden, vuelven al almacén. No se puede usar más de lo que hay. |
| Repuestos por agotarse | Cada repuesto tiene un **stock mínimo**. Aviso en el inicio, contador en la pestaña Inventario, filtro "Por agotarse" y alerta al usar el repuesto. |
| Historial de un equipo o cliente | Historial del equipo con cada visita, sus trabajos y las piezas cambiadas. Ficha del cliente con sus equipos y todas sus órdenes. |
| Costo total | Mano de obra + repuestos, calculado en el detalle de la orden. |

### Pantallas

- **Inicio**: órdenes abiertas, conteo por estado, repuestos por agotarse, trabajo por técnico y órdenes esperando técnico.
- **Órdenes**: búsqueda (cliente, teléfono, marca, modelo, serie o número de orden), filtros por estado y por técnico.
- **Detalle de orden**: responsable, estado, equipo, dueño, falla, trabajos, repuestos, total y notas; acciones según el estado.
- **Recibir equipo**: reconoce al cliente por su teléfono y al equipo por su número de serie para no duplicarlos y mantener el historial.
- **Clientes**: lista, ficha del cliente e historial de cada equipo.
- **Inventario**: alta y edición de repuestos, entrada de mercancía y filtro de los que están por agotarse.
- **Técnicos** (icono en el inicio): agregar, renombrar o desactivar técnicos.

## Decisiones de diseño

- **Sin autenticación** (lo pide el enunciado): cuando una acción depende de una persona (recibir el equipo, tomar la orden) la app pregunta qué técnico la realiza.
- **Un cliente se identifica por su teléfono** y **un equipo por su número de serie/IMEI**. Si el equipo vuelve, se agrega una nueva orden a su historial; si cambió de dueño, se actualiza el dueño actual.
- **Un equipo no puede tener dos órdenes abiertas** a la vez.
- **Tomar una orden** la pasa automáticamente a "En reparación". La actualización solo se aplica si la orden sigue sin responsable, así dos técnicos no pueden tomarla a la vez.
- **Trabajos y repuestos solo se anotan "En reparación"**. Para marcarla como lista debe haber al menos un trabajo anotado. Una orden lista puede **reabrirse** si el equipo falla al probarlo.
- **Se guarda el precio unitario del repuesto en la orden**, para que el total no cambie si luego se actualiza el precio en el inventario.
- **Cancelar una orden devuelve los repuestos al almacén** para que el stock siga cuadrando.
- **Repuesto "por agotarse"**: existencias ≤ stock mínimo (configurable por repuesto, 2 por defecto).
- Moneda mostrada con el símbolo `$` y dos decimales.

## Arquitectura

```
lib/
├── main.dart                     # ProviderScope + arranque
├── app.dart                      # MaterialApp, tema y navegación inferior
├── core/
│   ├── theme/app_theme.dart      # Material 3, Poppins, claro/oscuro, colores de estado
│   └── utils/formatters.dart     # moneda, fechas, número de orden
├── models/                       # Model: enums, datos combinados, excepciones de negocio
├── data/
│   ├── database/
│   │   ├── tables.dart           # Tablas Drift
│   │   ├── app_database.dart     # Base de datos, migraciones, PRAGMA foreign_keys
│   │   └── seed.dart             # Técnicos y datos de demostración
│   └── daos/                     # Consultas (JOINs, streams, transacciones)
├── providers/                    # Instancia única de la base y de los DAOs
├── viewmodels/                   # ViewModel: Notifiers y StreamProviders de Riverpod
└── views/                        # View: pantallas y widgets
```

- **Model** (`models/`, `data/`): tablas Drift `Technicians`, `Customers`, `Devices`, `Parts`, `RepairOrders`, `LaborItems` y `OrderParts`, con claves foráneas. Las reglas del taller viven en los DAOs y usan **transacciones** cuando hay varias escrituras (recepción, usar/quitar repuestos, cancelar).
- **ViewModel** (`viewmodels/`): `Notifier`s de Riverpod que guardan el estado de la UI (filtros, formulario de recepción) y clases de acciones que llaman a los DAOs. Las listas son `StreamProvider`s sobre consultas `watch()` de Drift, así la UI se actualiza sola.
- **View** (`views/`): widgets que solo muestran datos y envían eventos al ViewModel. Los errores de negocio (`WorkshopException`) se muestran en un SnackBar.

### Modelo de datos

```
Customers 1───* Devices 1───* RepairOrders *───0..1 Technicians (responsable)
                                   │       *───0..1 Technicians (recibió)
                                   ├──* LaborItems
                                   └──* OrderParts *───1 Parts
```

## Pruebas

`test/orders_dao_test.dart` prueba las reglas del taller sobre una base SQLite en memoria: recepción, reutilización de cliente y equipo, órdenes duplicadas, tomar una orden ya tomada, descuento y devolución de stock, total de la orden, repuestos por agotarse, flujo completo y carga por técnico.
`test/app_smoke_test.dart` comprueba que la app arranca y navega entre pestañas.

## Paquetes

| Paquete | Uso |
|---|---|
| `drift`, `drift_flutter` | Base de datos SQLite tipada |
| `drift_dev`, `build_runner` | Generación de código de Drift |
| `flutter_riverpod` | Gestión de estado / ViewModels |
| `intl` | Formato de moneda y fechas |
| `path_provider` | Ubicación del archivo de la base |
