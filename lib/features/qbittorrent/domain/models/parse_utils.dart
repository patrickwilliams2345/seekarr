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

/// Lenient bool parser for qBittorrent API responses, which historically mix
/// `true`/`false`, `1`/`0`, and their string equivalents across versions and
/// endpoints (notably `is_private`, `force_start`, `super_seeding`).
///
/// - `null` → `false`
/// - `bool` passes through
/// - `num`: any non-zero value is `true`; `0` is `false`
/// - Everything else: case-insensitive match on `'true'` or `'1'`
bool parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  return s == 'true' || s == '1';
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

/// Human-readable duration.
///
/// Returns `''` for `seconds <= 0` so callers can decide what "empty" means
/// (e.g. `—` for never-seen, or just an empty cell for freshly added). For
/// positive inputs renders as `'Xd HH:MM:SS'` (omitting the day prefix when
/// `d == 0`). Matches the shape the qBittorrent WebUI uses on the General tab.
String formatDuration(int seconds) {
  if (seconds <= 0) return '';
  final d = seconds ~/ 86400;
  final h = (seconds % 86400) ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final hh = h.toString().padLeft(2, '0');
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  if (d > 0) return '${d}d $hh:$mm:$ss';
  return '$hh:$mm:$ss';
}

/// qBittorrent per-torrent speed-limit rendering.
///
/// - `< 0` (qB's unlimited sentinel) → `'∞'`
/// - `== 0` (qB's "limit cleared" state) → `'0'` (NOT `'0 B/s'`, to match
///   the WebUI's discrete "0 / ∞" pair)
/// - positive → `formatSpeed`
String formatLimit(int bytesPerSecond) {
  if (bytesPerSecond < 0) return '∞';
  if (bytesPerSecond == 0) return '0';
  return formatSpeed(bytesPerSecond);
}

/// Local-time `YYYY-MM-DD HH:MM` rendering of a Unix epoch in seconds.
///
/// Returns `'—'` for `seconds <= 0` (covers both 0 = "never" and qB's -1
/// sentinels). No `intl` dependency — pads with `padLeft` instead.
String formatEpochDate(int seconds) {
  if (seconds <= 0) return '—';
  final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000).toLocal();
  String two(int x) => x.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}

/// Same rendering as [formatDuration] but reserved for "relative time"
/// call-sites (e.g. "Reannounce in" countdowns). Identical for now; the split
/// keeps the door open for a future locale-aware variant.
String formatRelativeSeconds(int seconds) {
  if (seconds <= 0) return '';
  return formatDuration(seconds);
}
