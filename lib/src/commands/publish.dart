import 'package:mhu/src/commands/build.dart';

import 'common.dart';

class DryPubCommand extends DartCommand {
  DryPubCommand()
      : super(
    name: 'drypub',
    arguments: [
      'pub',
      'publish',
      '--dry-run',
    ],
    before: BuildCommand().toBefore,
  );
}
