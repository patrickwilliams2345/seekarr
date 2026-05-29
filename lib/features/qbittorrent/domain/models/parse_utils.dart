int parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

String formatSize(int bytes) {
  if (bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  int i = 0;
  double s = bytes.toDouble();
  while (s >= 1024 && i < units.length - 1) {
    s /= 1024;
    i++;
  }
  return '${s.toStringAsFixed(1)} ${units[i]}';
}

String formatSpeed(int bytesPerSecond) {
  if (bytesPerSecond <= 0) return '0 B/s';
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  int i = 0;
  double s = bytesPerSecond.toDouble();
  while (s >= 1024 && i < units.length - 1) {
    s /= 1024;
    i++;
  }
  return '${s.toStringAsFixed(1)} ${units[i]}';
}
