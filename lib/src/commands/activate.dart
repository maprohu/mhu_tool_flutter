import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mhu_dart_commons/io.dart';
import 'common.dart';

class ActivateCommand extends Command<void> {
  final name = 'activate';
  final description =
      '''Activates global dart scripts of the project in the current directory tree.
  '''
          .trim();

  @override
  FutureOr<void> run() async {
    await requirePackageDir((package) async {
      await Process.start(
        'dart',
        [
          'pub',
          'global',
          'activate',
          '--source',
          'path',
          package.path,
        ],
      ).join(
        errorMessage: 'Failed to activate project.',
      );
    });
  }
}
