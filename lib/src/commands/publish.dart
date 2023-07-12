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
  );
}
