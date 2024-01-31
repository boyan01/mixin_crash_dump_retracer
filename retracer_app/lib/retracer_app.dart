import 'dart:io';

import 'package:actions_toolkit_dart/core.dart' as action;
import 'package:archive/archive.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:retracer_app/src/utils.dart';

import 'src/arguments.dart';
import 'src/dump_comment_parser.dart';

export 'src/arguments.dart';

class RetracerApp {
  RetracerApp(this.arguments)
      : githubClient = GitHub(
          auth: Authentication.withToken(arguments.githubToken),
        ) {
    final parsed = parseDumpComment(arguments.content);
    if (parsed == null) {
      action.info(message: 'No stacktrace found');
      exit(-1);
    }
    this.parsed = parsed;
  }

  final Arguments arguments;
  late DumpCommentParseResult parsed;
  final GitHub githubClient;

  Future<void> run() async {
    // find version matched pdb files.
    final downloadedSymbolDir = await _downloadDebugInfoFiles();
    if (downloadedSymbolDir == null || downloadedSymbolDir.isEmpty) {
      action.error(message: 'No symbol files found');
      exit(-1);
    }
    action.info(message: 'download_symbol_directory: $downloadedSymbolDir');

    final symbolDirectory = await prepareSymbolFiles(downloadedSymbolDir);
    action.info(message: 'symbol_directory: $downloadedSymbolDir');

    final miniDumpFile = await _downloadCrashMiniDump();
    if (miniDumpFile == null || miniDumpFile.isEmpty) {
      action.error(message: 'No mini dump file found');
      exit(-1);
    }
    action.info(message: 'mini_dump_file: $miniDumpFile');

    action.setOutput(name: 'symbol_directory', value: symbolDirectory);
    action.setOutput(name: 'mini_dump_file', value: miniDumpFile);
  }

  Future<String?> _downloadCrashMiniDump() async {
    action.startGroup(name: 'download mini dump');
    final miniDumpZip = await downloadFile(parsed.miniDumpUrl);
    final directory = await unzipFile(miniDumpZip);
    final dir = Directory(directory);
    final files = dir.listSync();
    if (files.isEmpty) {
      action.error(message: 'No files found in $directory');
      return null;
    }
    final miniDumpFile = files.firstWhere((element) {
      return element is File && element.path.endsWith('.dmp');
    });
    action.endGroup();
    return miniDumpFile.path;
  }

  // return the symbol directory
  Future<String?> _downloadDebugInfoFiles() async {
    action.startGroup(name: 'Find PDB files');
    final slug = RepositorySlug.full(arguments.repositorySlug);
    final issues = await githubClient.issues.listByRepo(
      slug,
      state: 'all',
      labels: ['debug_info', 'v:${parsed.version}'],
    ).toList();
    if (issues.isEmpty) {
      action.info(
          message: 'No debug info files found for version ${parsed.version}');
      return null;
    }

    if (issues.length > 1) {
      action.warning(
        message:
            'Found multiple debug info files for version ${parsed.version}',
      );
    }
    final issue = issues.first;
    final fileUrl = extractUrlFromComment(issue.body);
    if (fileUrl == null) {
      action.warning(
        message:
            'No debug info url found in issue ${issue.htmlUrl}: ${issue.body}',
      );
      return null;
    }
    action.debug(message: 'Found debug info file: $fileUrl');
    final downloadedFile = await downloadFile(fileUrl);
    final symbolDirectory = await unzipFile(downloadedFile);
    action.endGroup();
    return symbolDirectory;
  }
}

// download file to local temp directory. return the file path.
Future<String> downloadFile(String url) async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    throw Exception('Failed to download file: $url');
  }
  final tempDir = await Directory.systemTemp.createTemp();
  final downloadedFile = File('${tempDir.path}/${p.basename(url)}');
  await downloadedFile.writeAsBytes(response.bodyBytes, flush: true);
  return downloadedFile.path;
}

// unzip file to local temp directory. return the directory path.
Future<String> unzipFile(String filePath) async {
  final tempDir = await Directory.systemTemp.createTemp();
  final unzipDir = Directory('${tempDir.path}/unzip');
  await unzipDir.create();
  final archive = ZipDecoder().decodeBytes(File(filePath).readAsBytesSync());
  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File('${unzipDir.path}/$filename')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory('${unzipDir.path}/$filename').createSync(recursive: true);
    }
  }
  return unzipDir.path;
}

/// move symbol file in [dirPath] to separated xxx.pdb/uuid/xxx.sym
Future<String> prepareSymbolFiles(String dirPath) async {
  final symbolsDir = await Directory.systemTemp.createTemp('symbols');
  final files = Directory(dirPath).listSync();
  for (final file in files) {
    if (file is File && file.path.endsWith('.sym')) {
      final content = file.readAsLinesSync();
      if (content.isEmpty) {
        continue;
      }
      final infos = content.first.split(' ');
      final uuid = infos[3];
      final pdbFileName = infos[4];

      final targetDir = Directory(p.join(symbolsDir.path, pdbFileName, uuid));
      await targetDir.create(recursive: true);
      await file.copy(p.join(targetDir.path, p.basename(file.path)));
    }
  }
  return symbolsDir.path;
}
