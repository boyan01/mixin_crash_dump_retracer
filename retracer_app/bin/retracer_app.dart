import 'package:retracer_app/retracer_app.dart' as retracer_app;

void main(List<String> arguments) {
  print('Hello world: ${retracer_app.calculate()}!');
  print('argument: ${retracer_app.parseDumpComment(arguments[0])}');
}
