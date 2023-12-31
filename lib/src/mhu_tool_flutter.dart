import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mhu/src/commands/build.dart';
import 'package:mhu/src/commands/dependencies.dart';
import 'package:mhu/src/commands/proto.dart';
import 'package:mhu/src/commands/publish.dart';
import 'package:mhu/src/commands/title.dart';
import 'package:mhu/src/commands/update.dart';
import 'package:mhu/src/commands/screenshots.dart';
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
    ..addCommand(ProtocCommand())
    ..addCommand(PblibCommand())
    ..addCommand(PbfieldCommand())
    ..addCommand(PbCommand())
    ..addCommand(IconCommand())
    ..addCommand(TitleCommand())
    ..addCommand(ScreenshotsCommand())
    ..addCommand(UpdateCommand())
    ..addCommand(ActivateCommand())
    ..addCommand(AddCommand())
    ..addCommand(PubGetCommand())
    ..addCommand(DryPubCommand())
    ..addCommand(BuildCommand())
    ..addCommand(WatchCommand());

  try {
    await runner.run(args);
  } on MhuException catch (e) {
    stderr.writeln('ERROR: $e');
  }
}
