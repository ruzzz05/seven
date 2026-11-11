/// `mm:ss.cs` a partir de milisegundos.
String formatMs(int ms) {
  String two(int v) => v.toString().padLeft(2, '0');
  final m = ms ~/ 60000;
  final s = (ms % 60000) ~/ 1000;
  final cs = (ms % 1000) ~/ 10;
  return '${two(m)}:${two(s)}.${two(cs)}';
}
