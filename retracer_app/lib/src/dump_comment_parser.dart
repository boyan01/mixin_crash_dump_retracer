class DumpCommentParseResult {
  DumpCommentParseResult({
    required this.version,
    required this.miniDumpUrl,
  });

  final String version;

  final String miniDumpUrl;

  @override
  String toString() {
    return 'DumpCommentParseResult{version: $version, miniDumpUrl: $miniDumpUrl}';
  }
}

DumpCommentParseResult? parseDumpComment(String comment) {
  final match =
      RegExp(r'(?<=^version:).*', caseSensitive: false).firstMatch(comment);
  if (match == null) {
    return null;
  }
  final version = match.group(0)!.trim();

  final miniDumpUrlMatch = RegExp(r'(?<=\().+?(?=\))').firstMatch(comment);
  if (miniDumpUrlMatch == null) {
    return null;
  }
  final miniDumpUrl = miniDumpUrlMatch.group(0)!;

  return DumpCommentParseResult(
    version: version,
    miniDumpUrl: miniDumpUrl,
  );
}
