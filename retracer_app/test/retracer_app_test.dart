import 'dart:io';

import 'package:retracer_app/retracer_app.dart';
import 'package:test/test.dart';

void main() {
  test('download and unzip file', () async {
    final path = await downloadFile(
        'https://github.com/boyan01/mixin_crash_dump_retracer/files/9502057/8e63e760-5067-4dd5-b1ca-55579e8f9977.zip');
    expect(path, isNotEmpty);
    final file = File(path);
    expect(file.existsSync(), isTrue);
    final files = await unzipFile(path);
    expect(files, isNotEmpty);
  });
}
