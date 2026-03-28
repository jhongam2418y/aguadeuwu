import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'dart:convert';

// ─── Versión actual de la app ─────────────────────────────────────────────────
// Actualiza este valor cada vez que hagas un release.
const String kAppVersion = '1.0.0';

const String _kApiUrl =
    'https://api.github.com/repos/jhongam2418/aguadeuwu/releases/latest';
const String _kAssetName = 'setup_pos.exe';

// =============================================================================
// UpdateInfo — datos del release obtenido de GitHub
// =============================================================================
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String? releaseNotes;

  const UpdateInfo({
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

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(minutes: 10),
  ));

  /// Compara versiones semver simples (ej: "1.0.1" > "1.0.0").
  /// Ignora el prefijo "v" si existe.
  bool _isNewer(String remote, String current) {
    List<int> parse(String v) =>
        v.replaceFirst('v', '').split('.').map((s) => int.tryParse(s) ?? 0).toList();

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

  /// Consulta GitHub Releases y devuelve [UpdateInfo] si hay nueva versión,
  /// o null si la app está al día o no se pudo comprobar.
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(_kApiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[Updater] HTTP ${response.statusCode} al consultar releases.');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (json['tag_name'] as String? ?? '').replaceFirst('v', '');
      final body = json['body'] as String?;

      debugPrint('[Updater] Versión remota: $tagName  |  Local: $kAppVersion');

      if (!_isNewer(tagName, kAppVersion)) return null;

      // Buscar el asset setup_pos.exe
      final assets = (json['assets'] as List<dynamic>? ?? []);
      final asset = assets.firstWhere(
        (a) => (a['name'] as String?) == _kAssetName,
        orElse: () => null,
      );

      if (asset == null) {
        debugPrint('[Updater] No se encontró el asset "$_kAssetName" en el release.');
        return null;
      }

      return UpdateInfo(
        version: tagName,
        downloadUrl: asset['browser_download_url'] as String,
        releaseNotes: body,
      );
    } catch (e) {
      debugPrint('[Updater] Error al consultar updates: $e');
      return null;
    }
  }

  /// Descarga el instalador y llama [onProgress] con (received, total).
  /// Devuelve la ruta local del archivo descargado.
  Future<String> downloadInstaller(
    String url, {
    required void Function(int received, int total) onProgress,
  }) async {
    final destPath = p.join(Directory.systemTemp.path, _kAssetName);
    debugPrint('[Updater] Descargando $url → $destPath');

    await _dio.download(
      url,
      destPath,
      onReceiveProgress: (received, total) {
        onProgress(received, total);
        if (total > 0) {
          final pct = (received / total * 100).toStringAsFixed(1);
          debugPrint('[Updater] Progreso: $pct% ($received / $total bytes)');
        }
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    debugPrint('[Updater] Descarga completa: $destPath');
    return destPath;
  }

  /// Ejecuta el instalador y cierra la app.
  Future<void> launchInstaller(String path) async {
    debugPrint('[Updater] Lanzando instalador: $path');
    await Process.start(
      path,
      [],
      mode: ProcessStartMode.detached,
      runInShell: false,
    );
    exit(0);
  }
}
