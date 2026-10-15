const _domain = 'https://latest-dev.vbsxr.com';

String? resolveImageUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;

  final p = path.trim();
  final full = p.startsWith('http')
      ? p
      : (p.startsWith('/') ? '$_domain$p' : '$_domain/$p');
  return Uri.encodeFull(full);
}
