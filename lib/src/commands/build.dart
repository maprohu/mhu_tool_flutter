import 'dart:io';

import 'package:mhu/src/commands/common.dart';
import 'package:mhu_dart_commons/io.dart';

class PubGetCommand extends DartCommand {
  PubGetCommand()
      : super(
          name: 'pubget',
          arguments: [
            'pub',
            'get',
          ],
        );

  final aliases = [
    'pg',
  ];
}

Future<bool> pubGetBefore() async {
  await PubGetCommand().run();
  return true;
}

Future<bool> buildRunnerBefore() async {
  try {
    await DartCommand(
      name: 'check_build_runner',
      arguments: [
        'run',
        'build_runner',
      ],
    ).run();
    return await pubGetBefore();
  } on MhuExitStatusException catch (e) {
    return false;
  }
}


class BuildCommand extends DartCommand {
  BuildCommand()
      : super(
          name: 'build',
          arguments: [
            'run',
            'build_runner',
            'build',
            '--verbose',
            '--delete-conflicting-outputs',
          ],
          before: buildRunnerBefore,
        );
}

class WatchCommand extends DartCommand {
  WatchCommand()
      : super(
          name: 'watch',
          arguments: [
            'run',
            'build_runner',
            'watch',
            '--verbose',
            '--delete-conflicting-outputs',
          ],
          before: buildRunnerBefore,
        );
}
