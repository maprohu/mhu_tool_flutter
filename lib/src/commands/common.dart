import 'dart:async';
import 'dart:io';

import 'package:mhu_dart_commons/io.dart';
import 'package:pubspec/pubspec.dart';

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
  late final File iconPng = assets.file("icon.png");
  late final File iconAdaptivePng = assets.file("icon_adaptive.png");
  late final File titlePng = assets.file("title.png");
  late final File shortTitlePng = assets.file("short_title.png");
  late final File playStorePng = assets.file("play_store.png");

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
}
