import 'dart:io';

import 'package:actions_toolkit_dart/core.dart' as action;
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

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
    final pdbFiles = await _downloadPdbFiles();
    if (pdbFiles == null || pdbFiles.isEmpty) {
      action.error(message: 'No pdb files found');
      exit(-1);
    }
    action.info(message: 'pdb files: $pdbFiles');
  }

  Future<List<String>?> _downloadPdbFiles() async {
    action.startGroup(name: 'Find PDB files');
    final slug = RepositorySlug.full(arguments.repositorySlug);
    final issues = await githubClient.issues.listByRepo(
      slug,
      labels: ['pdb', parsed.version],
    ).toList();
    if (issues.isEmpty) {
      action.info(message: 'No PDB files found for version ${parsed.version}');
      return null;
    }

    if (issues.length > 1) {
      action.warning(
        message: 'Found multiple PDB files for version ${parsed.version}',
      );
    }
    final issue = issues.first;
    final pdbUrl = RegExp(r'(?<=\().+?(?=\))').firstMatch(issue.body)?.group(0);
    if (pdbUrl == null) {
      action.warning(
        message: 'No PDB url found in issue ${issue.htmlUrl}: ${issue.body}',
      );
      return null;
    }
    action.debug(message: 'Found PDB file: $pdbUrl');
    final downloadedFile = await downloadFile(pdbUrl);
    final pdbFiles = await unzipFile(downloadedFile);
    action.endGroup();
    return pdbFiles;
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
  await downloadedFile.writeAsBytes(response.bodyBytes);
  return downloadedFile.path;
}

// unzip file to local temp directory. return the directory path.
Future<List<String>> unzipFile(String filePath) async {
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
  return unzipDir.listSync().map((e) => e.path).toList();
}
