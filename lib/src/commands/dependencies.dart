import 'package:mhu_dart_commons/commons.dart';

import 'common.dart';

class AddCommand extends DartCommand {
  AddCommand()
      : super.parsed(
          name: 'add',
          arguments: (cmd) => [
            'pub',
            'add',
            ...cmd.argResults?.let((r) => r.arguments) ?? ['<package>'],
          ],
        );
}
