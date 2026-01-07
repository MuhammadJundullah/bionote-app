import '../config/api.dart';

String? resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (path.startsWith('/')) {
    return '${ApiConfig.baseUrl}$path';
  }
  return '${ApiConfig.baseUrl}/$path';
}
