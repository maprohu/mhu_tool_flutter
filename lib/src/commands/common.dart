import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mhu_dart_commons/io.dart';
import 'package:pubspec/pubspec.dart';
import 'package:yaml/yaml.dart';

import '../util/util.dart';

const pubspecYamlFileName = 'pubspec.yaml';

class DartPackageDir {
  final File pubspecYamlFile;

  DartPackageDir(this.pubspecYamlFile);

  late final packageDir = pubspecYamlFile.parent;
  late final path = packageDir.path;

  late Future<PubSpec> pubspec = PubSpec.load(packageDir);

  late final Directory assets = packageDir.dir("assets");
  late final File splashPng = assets.file("splash.png");
  late final File iconSvg = assets.file("icon.svg");
  late final File iconPng = assets.file("icon.png");
  late final File iconAdaptivePng = assets.file("icon_adaptive.png");
  late final File titlePng = assets.file("title.png");
  late final File shortTitlePng = assets.file("short_title.png");
  late final File playStorePng = assets.file("play_store.png");
  late final File playStoreFeaturePng = assets.file("play_store_feature.png");

  late final Directory web = packageDir.dir('web');
  late final File indexHtml = web.file('index.html');
  late final File faviconPng = web.file('favicon.png');
  late final Directory webIcons = web.dir('icons');

  Future<void> addDependency(
    String name, {
    bool dev = false,
    String? path,
  }) async {
    final pubspecLoaded = await pubspec;
    final deps =
        dev ? pubspecLoaded.devDependencies : pubspecLoaded.dependencies;
    if (deps.containsKey(name)) {
      stdout.writeln('Project already contains dependency, not adding: $name');
      return;
    }

    await packageDir.runWithExitCode(
      'flutter',
      [
        'pub',
        'add',
        if (dev) '--dev',
        if (path != null) ...[
          '--path',
          path,
        ],
        name,
      ],
    );
  }
}

class PubspecYamlNotFound extends MhuToolException {
  PubspecYamlNotFound(Directory dir)
      : super(
          'Could not find "$pubspecYamlFileName" in parent hierarchy of $dir',
        );
}

Future<T> requirePackageDir<T>(
  FutureOr<T> Function(DartPackageDir package) action,
) async {
  var dir = Directory.current;

  while (true) {
    final file = dir.file(pubspecYamlFileName);

    if (await file.exists()) {
      return await action(
        DartPackageDir(file),
      );
    }

    final parent = dir.parent;

    if (dir.path == parent.path) {
      throw PubspecYamlNotFound(Directory.current);
    }

    dir = parent;
  }
}

extension PubSpecX on PubSpec {
  String? title() => unParsedYaml?['mhu']?['title'];

  String? shortTitle() => unParsedYaml?['mhu']?['short_title'];

  String? icon() => unParsedYaml?['mhu']?['icon'];

  String? foreground() => unParsedYaml?['mhu']?['color'];

  String? background() => unParsedYaml?['flutter_native_splash']?['color'];

  Iterable<String> protoDeps() {
    final YamlList? list = unParsedYaml?['mhu']?['proto_deps'];
    if (list == null) {
      return [];
    }
    return list.value.map((e) => e.toString());
  }
}

extension MhuCommandX<T> on Command<T> {
  bool hasOption(String option) {
    final argResults = this.argResults;
    if (argResults == null) {
      return false;
    }
    return argResults[option];
  }

  BeforeCommand get toBefore => () async {
        await this.run();
        return true;
      };
}

typedef BeforeCommand = FutureOr<bool> Function();

class RunCommand extends Command<void> {
  static const only = 'only';

  final String name;

  final String executable;

  final List<String> Function(Command<void> cmd) arguments;

  final BeforeCommand? before;

  late final String description = [
    'runs:',
    executable,
    ...arguments(this),
  ].join(' ');

  @override
  FutureOr<void>? run() async {
    final before = this.before;
    if (before != null && !hasOption(only)) {
      final goOn = await before();

      if (!goOn) {
        stdout.writeln('not running $name');
        return;
      }
    }
    await requirePackageDir((package) async {
      await package.packageDir.run(
        executable,
        arguments(this),
      );
    });
  }

  RunCommand.parsed({
    required this.name,
    required this.executable,
    required this.arguments,
    BeforeCommand? before,
  }) : before = before {
    if (before != null) {
      argParser.addFlag(
        only,
        abbr: 'o',
        help: 'do not run check before',
      );
    }
  }

  RunCommand({
    required String name,
    required String executable,
    required List<String> arguments,
    BeforeCommand? before,
  }) : this.parsed(
          name: name,
          executable: executable,
          arguments: (_) => arguments,
          before: before,
        );
}

class DartCommand extends RunCommand {
  DartCommand.parsed({
    required super.name,
    required super.arguments,
    super.before,
  }) : super.parsed(
          executable: 'dart',
        );

  DartCommand({
    required super.name,
    required super.arguments,
    super.before,
  }) : super(
          executable: 'dart',
        );
}

Future<void> writeIfDirty({
  required File file,
  required bool dirty,
  required String Function() content,
}) async {
  if (dirty) {
    stdout.writeln('Updating: ${file.path}');
    await file.writeAsString(content());
  } else {
    stdout.writeln('Not updating: ${file.path} is already up to date.');
  }
}
