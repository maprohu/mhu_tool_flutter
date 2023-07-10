import 'package:mhu/src/commands/common.dart';

class BuildCommand extends DartCommand {
  BuildCommand()
      : super(
          name: 'build',
          arguments: [
            'run',
            'build_runner',
            'build',
            '--verbose',
          ],
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
          ],
        );
}
