import 'package:retracer_app/src/dump_comment_parser.dart';
import 'package:test/test.dart';

void main() {
  test('parse example 1', () {
    final content = """
version: 0.36.1

[8e63e760-5067-4dd5-b1ca-55579e8f9977.zip](https://github.com/boyan01/mixin_crash_dump_retracer/files/9502057/8e63e760-5067-4dd5-b1ca-55579e8f9977.zip)
    """;
    final result = parseDumpComment(content);
    expect(result, isNotNull);
    expect(result!.version, '0.36.1');
    expect(result.miniDumpUrl,
        'https://github.com/boyan01/mixin_crash_dump_retracer/files/9502057/8e63e760-5067-4dd5-b1ca-55579e8f9977.zip');
  });
  test('parse example 2', () {
    final content = """
VERSION: 0.36.1

[8e63e760-5067-4dd5-b1ca-55579e8f9977.zip](https://github.com/boyan01/mixin_crash_dump_retracer/files/9502057/8e63e760-5067-4dd5-b1ca-55579e8f9977.zip)
    """;
    final result = parseDumpComment(content);
    expect(result, isNotNull);
    expect(result!.version, '0.36.1');
    expect(result.miniDumpUrl,
        'https://github.com/boyan01/mixin_crash_dump_retracer/files/9502057/8e63e760-5067-4dd5-b1ca-55579e8f9977.zip');
  });
}
