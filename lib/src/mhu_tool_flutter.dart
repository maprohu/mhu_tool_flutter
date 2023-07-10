import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mhu/src/commands/build.dart';
import 'package:mhu/src/version.g.dart';
import 'package:mhu_dart_commons/commons.dart';

import 'commands/activate.dart';
import 'commands/icon.dart';

const script = 'mhu';
const description =
    "A command line tool to help with Dart and Flutter development.\n"
    "Version $packageVersion";

void main(List<String> args) async {
  final runner = CommandRunner(script, description)
    ..addCommand(ActivateCommand())
    ..addCommand(IconCommand())
    ..addCommand(BuildCommand())
    ..addCommand(WatchCommand());

  try {
    await runner.run(args);
  } on MhuException catch (e) {
    stderr.writeln('ERROR: $e');
  }
}
