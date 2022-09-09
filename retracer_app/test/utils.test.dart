import 'package:retracer_app/src/utils.dart';
import 'package:test/test.dart';

void main() {
  test('extract', () {
    final url = extractUrlFromComment(
        '[windows_debug_info (1).zip](https://github.com/boyan01/mixin_crash_dump_retracer/files/9531646/windows_debug_info.1.zip)');
    expect(url,
        'https://github.com/boyan01/mixin_crash_dump_retracer/files/9531646/windows_debug_info.1.zip');
  });
}
