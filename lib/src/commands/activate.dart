
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
// class ActivateCommand extends Command<void> {
//   final name = 'activate';
//   final description =
//       '''Activates global dart scripts of the project in the current directory tree.
//   '''
//           .trim();
//
//   @override
//   FutureOr<void> run() async {
//     await requirePackageDir((package) async {
//       await Process.start(
//         'dart',
//         [
//           'pub',
//           'global',
//           'activate',
//           '--source',
//           'path',
//           package.path,
//         ],
//       ).join(
//         errorMessage: 'Failed to activate project.',
//       );
//     });
//   }
// }
