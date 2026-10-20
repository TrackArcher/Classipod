/// Default public Elzicy / RadioScraper host.
const String defaultElzicyBaseUrl = 'https://api.elzen.stream';

String? normalizeElzicyBaseUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  var normalized = url.trim();
  if (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  if (!normalized.contains('://')) {
    final scheme = _shouldUseHttp(normalized) ? 'http' : 'https';
    normalized = '$scheme://$normalized';
  }
  final uri = Uri.tryParse(normalized);
  if (uri == null || uri.host.isEmpty) return null;
  var path = uri.path;
  if (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  for (final suffix in [
    '/api/stream-history',
    '/api/history',
    '/api',
  ]) {
    if (path.endsWith(suffix)) {
      path = path.substring(0, path.length - suffix.length);
      break;
    }
  }
  if (path.isEmpty || path == '/') {
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }
  var result = uri.replace(path: path, query: null).toString();
  if (result.endsWith('/')) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}

bool _shouldUseHttp(String host) {
  final hostPart = host.split('/').first.split(':').first.toLowerCase();
  if (hostPart == 'localhost') return true;
  return RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(hostPart);
}
