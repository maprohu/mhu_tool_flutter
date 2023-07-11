import 'package:mhu/src/commands/common.dart';

import '../mhu_tool_flutter.dart';

class UpdateCommand extends DartCommand {
  UpdateCommand() : super(
    name: 'update',
    arguments: [
      'pub',
      'global',
      'activate',
      script,
    ]
  );

}