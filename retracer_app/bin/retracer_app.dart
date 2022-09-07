import 'dart:io';

import 'package:actions_toolkit_dart/core.dart' as action;
import 'package:retracer_app/retracer_app.dart';

void main(List<String> arguments) async {
  final token = action.getInput(name: 'github_token');
  final content = arguments[0];

  final argument = Arguments(
    content: content,
    githubToken: token,
    repositorySlug: Platform.environment['GITHUB_REPOSITORY']!,
  );

  await RetracerApp(argument).run();
}
