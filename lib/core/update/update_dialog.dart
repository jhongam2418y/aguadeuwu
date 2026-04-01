import 'package:flutter/material.dart';
import 'update_service.dart';

// =============================================================================
// Punto de entrada público — llama esto desde main() o initState del home
// =============================================================================

/// Verifica si hay actualización y, si la hay, muestra los diálogos.
/// Debe llamarse con un [BuildContext] válido y montado.
Future<void> checkAndPromptUpdate(BuildContext context) async {
  final info = await UpdateService.instance.checkForUpdates();
  if (info == null) return;

  if (!context.mounted) return;

  final aceptar = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _UpdateAvailableDialog(info: info),
  );

  if (aceptar != true) return;
  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _DownloadProgressDialog(info: info),
  );
}

// =============================================================================
// _UpdateAvailableDialog — informa que hay nueva versión
// =============================================================================
class _UpdateAvailableDialog extends StatelessWidget {
  final UpdateInfo info;
  const _UpdateAvailableDialog({required this.info});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.system_update_rounded,
                color: Color(0xFF00695C), size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Nueva versión disponible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              _VersionChip(label: 'Actual', version: info.currentVersion, muted: true),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Color(0xFF4E6D68)),
              ),
              _VersionChip(label: 'Nueva', version: info.version),
            ],
          ),
          if (info.releaseNotes != null && info.releaseNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FAF8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB2DFDB)),
              ),
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Text(
                  info.releaseNotes!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'La actualización se descargará e instalará automáticamente. '
            'La aplicación se cerrará al finalizar.',
            style: TextStyle(fontSize: 13, color: Color(0xFF4E6D68)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontSize: 15),
          ),
          child: const Text('Después'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Actualizar ahora'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// =============================================================================
// _DownloadProgressDialog — descarga bloqueante con progreso real
// =============================================================================
class _DownloadProgressDialog extends StatefulWidget {
  final UpdateInfo info;
  const _DownloadProgressDialog({required this.info});

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;   // 0.0 – 1.0
  int _received = 0;
  int _total = -1;
  String _statusText = 'Iniciando descarga…';
  bool _error = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      setState(() => _statusText = 'Conectando con el servidor…');

      final path = await UpdateService.instance.downloadInstaller(
        widget.info.downloadUrl,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            _total = total;
            if (total > 0) {
              _progress = received / total;
              _statusText =
                  'Descargando actualización… ${(_progress * 100).toStringAsFixed(0)}%';
            } else {
              // Tamaño desconocido: mostrar bytes descargados
              _progress = -1; // señal para usar indeterminate
              _statusText =
                  'Descargando… ${_formatBytes(received)}';
            }
          });
        },
      );

      if (!mounted) return;
      setState(() => _statusText = 'Descarga completa. Iniciando instalador…');

      // Breve pausa para que el usuario vea el mensaje final
      await Future.delayed(const Duration(milliseconds: 800));

      await UpdateService.instance.launchInstaller(path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _errorMsg = e.toString();
        _statusText = 'Error durante la descarga.';
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isIndeterminate = _progress < 0 || (_progress == 0.0 && _received == 0);
    final progressValue = isIndeterminate ? null : _progress.clamp(0.0, 1.0);
    final pctLabel = _total > 0
        ? '${(_progress * 100).toStringAsFixed(0)}%'
        : '';

    return PopScope(
      canPop: false, // bloquea el botón atrás durante la descarga
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícono
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _error
                      ? Icons.error_outline_rounded
                      : Icons.download_rounded,
                  color: _error
                      ? Colors.red.shade600
                      : const Color(0xFF00695C),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                _error ? 'Error de actualización' : 'Actualizando sistema…',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtítulo
              Text(
                _statusText,
                style: const TextStyle(
                      fontSize: 14, color: Color(0xFF4E6D68)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (!_error) ...[
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 14,
                    backgroundColor: const Color(0xFFE0F2F1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00695C)),
                  ),
                ),
                const SizedBox(height: 10),

                // Porcentaje + bytes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _total > 0
                          ? '${_formatBytes(_received)} / ${_formatBytes(_total)}'
                          : _received > 0
                              ? _formatBytes(_received)
                              : '',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF4E6D68)),
                    ),
                    if (pctLabel.isNotEmpty)
                      Text(
                        pctLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00695C),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  'No cierres la aplicación. Se reiniciará automáticamente.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // Mostrar error y opción de cerrar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMsg ?? 'Error desconocido.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 28),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cerrar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _VersionChip
// =============================================================================
class _VersionChip extends StatelessWidget {
  final String label;
  final String version;
  final bool muted;
  const _VersionChip(
      {required this.label, required this.version, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: muted
                    ? const Color(0xFF4E6D68)
                    : const Color(0xFF00695C))),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: muted
                ? const Color(0xFFF0F3F8)
                : const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: muted
                  ? const Color(0xFF4E6D68)
                  : const Color(0xFF00695C),
            ),
          ),
        ),
      ],
    );
  }
}
