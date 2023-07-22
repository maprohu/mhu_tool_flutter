
import 'common.dart';

class ActivateCommand extends DartCommand {
  ActivateCommand()
      : super(
          name: 'activate',
          arguments: [
            'pub',
            'global',
            'activate',
            '--source',
            'path',
            '.',
          ],
        );
}
