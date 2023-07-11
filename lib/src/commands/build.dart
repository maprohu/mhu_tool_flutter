import 'package:mhu/src/commands/common.dart';

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
 ] ;
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
          before: PubGetCommand(),
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
          before: PubGetCommand(),
        );
}
