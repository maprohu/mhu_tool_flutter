import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mhu/src/commands/common.dart';
import 'package:mhu_dart_builder/mhu_dart_builder.dart';
import 'package:mhu_dart_commons/io.dart';

// class ProtocCommand extends Command<void> {
//   final name = "protoc";
//   final description = "Run protoc";
//
//   @override
//   Future<void>? run() async {
//     await requirePackageDir((package) async {
//       final ps = await package.pubspec;
//       await runProtoc(
//         cwd: package.packageDir,
//         dependencies: ps.protoDeps().toList(),
//       );
//     });
//   }
// }

class PblibCommand extends Command<void> {
  final name = "pblib";
  final description = "Generates pblib";

  @override
  Future<void>? run() async {
    await requirePackageDir((package) async {
      final ps = await package.pubspec;
      await runPbLibGenerator(
        cwd: package.packageDir,
        dependencies: ps.protoDeps().toList(),
        protoc: false,
      );
    });
  }
}

class ProtocCommand extends DartCommand {
  static final _path = '.dart_tool/mhu/protoc.dart';

  ProtocCommand()
      : super(
    name: 'protoc',
    arguments: [
      _path,
    ],
    before: () async {
      return await requirePackageDir((package) async {
        final ps = await package.pubspec;
        final file = package.packageDir.file(_path);
        await file.parent.create(recursive: true);

        final deps = ps.protoDeps().map((e) => e.dartRawSingleQuoteStringLiteral).join(',');

        await file.writeAsString([
          "import 'package:mhu_dart_builder/mhu_dart_builder.dart';",
          'void main() async {',
          '  await runProtoc(dependencies: [$deps]);'
          '}',
        ].join('\n'));
        return true;
      });
    },
  );
}
class PbfieldCommand extends DartCommand {
  static final _path = '.dart_tool/mhu/pbfield.dart';

  PbfieldCommand()
      : super(
          name: 'pbfield',
          arguments: [
            _path,
          ],
          before: () async {
            return await requirePackageDir((package) async {
              final packageName = (await package.pubspec).name!;
              final file = package.packageDir.file(_path);
              await file.parent.create(recursive: true);

              final pblibPath = Directory("../..").pblibFile(packageName).filePath.join('/');

              await file.writeAsString([
                'import "$pblibPath";',
                "import 'package:mhu_dart_builder/mhu_dart_builder.dart';",
                'void main() async {',
                '  await runPbFieldGenerator(lib: ${pblibVarName(packageName)});',
                '}',
              ].join('\n'));
              return true;
            });
          },
        );
}

class PbCommand extends Command<void> {
  final name = "pb";
  final description = "Runs all protobuf";

  @override
  Future<void>? run() async {
    await ProtocCommand().run();
    await PblibCommand().run();
    await PbfieldCommand().run();
  }
}
