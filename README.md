# Piscigranja — Boletería

Sistema de punto de venta (POS) para la emisión y gestión de tickets de entrada en una piscigranja. Desarrollado con Flutter para escritorio Windows, con soporte de impresión térmica, exportación de reportes y actualizaciones automáticas.

---

## Características

### Boletería
- Registro de visitantes por tipo: adultos y niños
- Cálculo automático del total según tarifas configuradas por día de la semana
- Métodos de pago: Efectivo, Yape y Plin
- Vista previa del ticket antes de confirmar
- Impresión directa a impresora configurada (PDF vía `printing`)
- Anulación de tickets emitidos

### Dashboard
- Resumen del día: cantidad de tickets vendidos e ingresos totales
- Desglose de ingresos por método de pago
- Lista de tickets del día con opción de anulación
- Historial de ventas consultable por rango de fechas

### Configuración
- Precios de adulto y niño configurables para cada día de la semana (Lunes–Domingo)
- Selección de impresora predeterminada
- Exportación del historial en **CSV** o **PDF**

### Actualizaciones automáticas
- Al iniciar la app, verifica si hay una nueva versión publicada en GitHub Releases
- Muestra un diálogo con las notas del release y permite descargar e instalar el nuevo instalador sin salir de la app

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| UI / Framework | Flutter 3 + Material 3 |
| Lenguaje | Dart |
| Estado | Provider |
| Base de datos | SQLite (`sqflite` + `sqflite_common_ffi`) |
| Impresión / PDF | `pdf` + `printing` |
| Exportación | `csv`, `file_picker`, `open_filex` |
| Actualizaciones | GitHub Releases API (`http`, `package_info_plus`) |
| Ventana desktop | `window_manager` (pantalla completa, sin barra de título) |

---

## Estructura del proyecto

```
lib/
├── main.dart                        # Entrada: inicializa window, SQLite y localización
├── app.dart                         # MaterialApp + MultiProvider raíz
├── core/
│   ├── app_colors.dart
│   ├── database/                    # AppDatabase (singleton SQLite)
│   ├── export/                      # ExportService — CSV y PDF
│   └── update/                      # UpdateService + UpdateDialog (GitHub Releases)
└── features/
    ├── configuracion/
    │   ├── data/                    # ConfigModel, ConfigRepository
    │   └── presentation/            # ConfigProvider, ConfiguracionScreen
    └── tickets/
        ├── data/                    # TicketModel, TicketRepository
        └── presentation/
            ├── providers/           # TicketProvider
            └── screens/
                ├── dashboard_screen.dart
                ├── boleteria_screen.dart
                └── ticket_preview_screen.dart
```

---

## Instalación y compilación

### Requisitos
- Flutter SDK `^3.10.0`
- Windows 10/11 (target principal)

### Clonar y ejecutar en desarrollo

```bash
git clone https://github.com/jhongam2418/aguadeuwu.git
cd aguadeuwu
flutter pub get
flutter run -d windows
```

### Compilar instalador para producción

```bash
flutter build windows --release
```

Luego compilar el instalador con **Inno Setup** usando el script [`installer.iss`](installer.iss) incluido en el repositorio. El archivo resultante debe llamarse `PiscigranjaInstaller.exe` y adjuntarse al release de GitHub.

---

## Sistema de actualizaciones automáticas

La app consulta `https://api.github.com/repos/jhongam2418/aguadeuwu/releases/latest` al iniciar.

Para que el diálogo de actualización aparezca:
1. Crear un nuevo release en GitHub con un tag **mayor** que la versión en `pubspec.yaml` (ej. `v1.0.1`)
2. Adjuntar el instalador con el nombre exacto: **`PiscigranjaInstaller.exe`**

---

## Base de datos

La base de datos SQLite se almacena en:

```
%LOCALAPPDATA%\Piscigranja\piscigranja.db
```

Contiene dos tablas: `tickets` (ventas del día) y `config` (precios e impresora).

---

## Licencia

Proyecto privado. Todos los derechos reservados.