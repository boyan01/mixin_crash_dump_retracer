import 'package:retracer_app/src/utils.dart';

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

  final miniDumpUrl = extractUrlFromComment(comment);
  if (miniDumpUrl == null) {
    return null;
  }
  return DumpCommentParseResult(
    version: version,
    miniDumpUrl: miniDumpUrl,
  );
}
