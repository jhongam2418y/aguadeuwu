import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

// URL de la API de GitHub Releases del repositorio.
const String _kApiUrl =
    'https://api.github.com/repos/jhongam2418/aguadeuwu/releases/latest';

// Nombre exacto del asset .exe dentro del release de GitHub.
const String _kAssetName = 'PiscigranjaInstaller.exe';

// =============================================================================
// UpdateInfo — datos del release obtenido de GitHub
// =============================================================================
class UpdateInfo {
  /// Versión instalada actualmente (leída de package_info_plus).
  final String currentVersion;

  /// Versión disponible en GitHub Releases.
  final String version;

  /// URL de descarga directa del instalador.
  final String downloadUrl;

  /// Notas del release (body del release en GitHub), puede ser null.
  final String? releaseNotes;

  const UpdateInfo({
    required this.currentVersion,
    required this.version,
    required this.downloadUrl,
    this.releaseNotes,
  });
}

// =============================================================================
// UpdateService
// =============================================================================
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  // Previene descargas simultáneas si el usuario llama varias veces.
  bool _isDownloading = false;

  // ── Comparador semver simple ──────────────────────────────────────────────
  // Acepta versiones con o sin prefijo "v" (ej: "v1.2.0" o "1.2.0").
  // Devuelve true únicamente si [remote] es mayor que [current].
  bool _isNewer(String remote, String current) {
    List<int> parse(String v) => v
        .replaceFirst('v', '')
        .split('.')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();

    final r = parse(remote);
    final c = parse(current);
    final len = r.length > c.length ? r.length : c.length;
    for (int i = 0; i < len; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }

  // ── checkForUpdates ───────────────────────────────────────────────────────
  /// Consulta la API de GitHub y compara con la versión instalada.
  /// Devuelve [UpdateInfo] si hay una versión más reciente, o null en caso
  /// contrario (sin actualización o error de red).
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Obtener versión actual del ejecutable vía package_info_plus.
      // En Windows Desktop lee el campo version de pubspec.yaml en producción.
      final pkgInfo = await PackageInfo.fromPlatform();
      final currentVersion = pkgInfo.version;

      // Consultar GitHub Releases API.
      final response = await http
          .get(
            Uri.parse(_kApiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[Updater] HTTP ${response.statusCode} al consultar releases.');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName =
          (json['tag_name'] as String? ?? '').replaceFirst('v', '');
      final body = json['body'] as String?;

      debugPrint('[Updater] Remota: $tagName  |  Local: $currentVersion');

      // No hay actualización si la versión remota no supera la local.
      if (!_isNewer(tagName, currentVersion)) return null;

      // Buscar el asset PiscigranjaInstaller.exe dentro de los assets del release.
      final assets = (json['assets'] as List<dynamic>? ?? []);
      final dynamic asset = assets.firstWhere(
        (a) => (a['name'] as String?) == _kAssetName,
        orElse: () => null,
      );

      if (asset == null) {
        debugPrint(
            '[Updater] No se encontró el asset "$_kAssetName" en el release.');
        return null;
      }

      return UpdateInfo(
        currentVersion: currentVersion,
        version: tagName,
        downloadUrl: asset['browser_download_url'] as String,
        releaseNotes: body,
      );
    } catch (e) {
      debugPrint('[Updater] Error al consultar updates: $e');
      return null;
    }
  }

  // ── downloadInstaller ─────────────────────────────────────────────────────
  /// Descarga el instalador usando streaming HTTP para reportar progreso real.
  ///
  /// [onProgress] recibe (bytesRecibidos, totalBytes).
  /// Si el servidor no devuelve Content-Length, totalBytes será -1.
  ///
  /// Lanza [StateError] si ya hay una descarga en curso.
  /// Lanza [HttpException] si el servidor responde con código != 200.
  Future<String> downloadInstaller(
    String url, {
    required void Function(int received, int total) onProgress,
  }) async {
    if (_isDownloading) {
      throw StateError('Ya hay una descarga en curso.');
    }
    _isDownloading = true;

    final destPath = p.join(Directory.systemTemp.path, _kAssetName);
    debugPrint('[Updater] Descargando $url → $destPath');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode != 200) {
        throw HttpException(
            'Error HTTP ${streamedResponse.statusCode} al descargar el instalador.');
      }

      // Content-Length puede ser -1 si el servidor no lo provee.
      final total = streamedResponse.contentLength ?? -1;
      int received = 0;

      final file = File(destPath);
      final sink = file.openWrite();

      try {
        // Leer el stream en chunks y escribir al archivo.
        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress(received, total);

          if (total > 0) {
            final pct = (received / total * 100).toStringAsFixed(1);
            debugPrint('[Updater] $pct% — $received / $total bytes');
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      debugPrint('[Updater] Descarga completa: $destPath');
      return destPath;
    } finally {
      client.close();
      _isDownloading = false;
    }
  }

  // ── launchInstaller ───────────────────────────────────────────────────────
  /// Ejecuta el instalador en modo detached y cierra la aplicación actual.
  Future<void> launchInstaller(String path) async {
    debugPrint('[Updater] Lanzando instalador: $path');
    await Process.start(
      path,
      [],
      mode: ProcessStartMode.detached,
      runInShell: false,
    );
    // Cierra la app para que el instalador pueda reemplazar el ejecutable.
    exit(0);
  }
}
