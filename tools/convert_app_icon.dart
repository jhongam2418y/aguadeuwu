import 'dart:io';
import 'package:image/image.dart' as img;

List<int> _toLittleEndian(int value, int bytes) {
  final result = <int>[];
  for (int i = 0; i < bytes; i++) {
    result.add(value & 0xFF);
    value >>= 8;
  }
  return result;
}

Future<void> main(List<String> args) async {
  final srcPath = 'assets/images/app_icon.png';
  final dstPath = 'windows/runner/resources/app_icon.ico';

  final srcFile = File(srcPath);
  if (!await srcFile.exists()) {
    stderr.writeln('Source not found: $srcPath');
    exit(1);
  }

  final srcBytes = await srcFile.readAsBytes();
  final image = img.decodeImage(srcBytes);
  if (image == null) {
    stderr.writeln('Failed to decode image: $srcPath');
    exit(2);
  }

  // Icon sizes to include (common Windows sizes).
  final sizes = [16, 24, 32, 48, 64, 128, 256];
  final List<List<int>> pngList = [];

  for (final s in sizes) {
    final resized = img.copyResize(image, width: s, height: s, interpolation: img.Interpolation.average);
    final png = img.encodePng(resized);
    pngList.add(png);
  }

  // Build ICO file (ICONDIR + ICONDIRENTRYs + image data). We'll store PNG-encoded images
  // inside the ICO, which is supported on modern Windows (Vista+).
  final out = <int>[];

  // ICONDIR: reserved(2) type(2) count(2)
  out.addAll([0, 0]); // reserved
  out.addAll([1, 0]); // type = 1 (icon)
  out.addAll([pngList.length, 0]); // count

  int offset = 6 + (16 * pngList.length);

  for (int i = 0; i < pngList.length; i++) {
    final png = pngList[i];
    final s = sizes[i];
    // width/height: 0 means 256
    out.add(s >= 256 ? 0 : s);
    out.add(s >= 256 ? 0 : s);
    out.add(0); // color count
    out.add(0); // reserved
    out.addAll([0, 0]); // planes (set to 0 for PNG)
    out.addAll([0, 0]); // bit count (set to 0 for PNG)
    out.addAll(_toLittleEndian(png.length, 4));
    out.addAll(_toLittleEndian(offset, 4));
    offset += png.length;
  }

  for (final png in pngList) {
    out.addAll(png);
  }

  final outFile = File(dstPath);
  await outFile.create(recursive: true);
  await outFile.writeAsBytes(out);

  stdout.writeln('Wrote icon to: $dstPath (included sizes: ${sizes.join(', ')})');
}
