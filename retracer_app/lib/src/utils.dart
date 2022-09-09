String? extractUrlFromComment(String comment) {
  final matches = RegExp(r'(?<=\().+?(?=\))').allMatches(comment);
  for (final match in matches) {
    final url = match.group(0);
    if (url == null) {
      continue;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && const {'https', 'http'}.contains(uri.scheme)) {
      return url;
    }
  }
  return null;
}
