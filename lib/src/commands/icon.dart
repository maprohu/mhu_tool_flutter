import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mhu_dart_commons/io.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../util/util.dart';
import 'common.dart';

class IconCommand extends Command<void> {
  final name = 'icon';

  final description =
      '''Sets up launcher icons and splash screen for Flutter project.
Takes an SVG file as an argument (either a file path or and http url) and 
uses it to set up the splash screen and the launcher icons of the 
Flutter project in the current directory tree.  

See some icons here:
https://fonts.google.com/icons

The URL to the icon can be specified either as an argument or
in the pubspec.yaml file:

mhu:
  icon: https://fonts.gstatic.com/s/i/materialiconsoutlined/waves/v11/24px.svg
  '''
          .trim();

  @override
  FutureOr<void>? run() async {
    return await requirePackageDir((package) async {
      Future<String> urlFromPubspec() async {
        final pubspec = await package.pubspec;

        final svgUrl = pubspec.icon();

        if (svgUrl != null) {
          return svgUrl;
        }

        throw MhuToolException(
          'SVG URL must be specified either as a command line argument '
          'or in $pubspecYamlFileName',
        );
      }

      final params = argResults!.rest;

      final svgUrl = switch (params) {
        [final url] => url,
        [] => await urlFromPubspec(),
        _ => throw MhuToolException('"icon" command takes at most 1 parameter'),
      };

      await processIcon(svgUrl, package);
    });
  }
}

Future<XmlDocument> loadSvg(String svgUrl) async {
  var uri = Uri.parse(svgUrl);
  final scheme = uri.scheme;
  final String svgString;
  if (scheme == 'http' || scheme == 'https') {
    svgString = await http.read(uri);
  } else if (scheme == '') {
    svgString = await File(svgUrl).readAsString();
  } else {
    throw MhuToolException('I do not know how to retrieve: $svgUrl');
  }

  return XmlDocument.parse(svgString);
}

Future<File> resolveFile(String url) async {
  var uri = Uri.parse(url);
  final scheme = uri.scheme;
  if (scheme == 'http' || scheme == 'https') {
    final bytes = await http.readBytes(uri);
    final tempDir = await Directory.systemTemp.createTemp();
    final fileName = uri.pathSegments.last;
    final file = File(path.join(tempDir.path, fileName));
    stdout.writeln("Downloading to temporary file: ${file.path}");
    await file.writeAsBytes(bytes);
    return file;
  } else if (scheme == '') {
    return File(url);
  } else {
    throw MhuToolException('I do not know how to retrieve file: $url');
  }
}

Future<File> writeSvgToTemp(XmlDocument svg) async {
  final tempDir = await Directory.systemTemp.createTemp();
  final file = File(path.join(tempDir.path, 'temp.svg'));
  stdout.writeln("Writing SVG to temporary file: ${file.path}");
  await file.writeAsString(svg.toXmlString(pretty: true));
  return file;
}

void changeFillColor(XmlDocument svg, [String newColor = "#FFFFFF"]) {
  svg.firstElementChild!.setAttribute('fill', newColor);
}

Future<void> processIcon(
  String svgUrl,
  DartPackageDir app,
) async {
  await app.addDependency(
    'flutter_native_splash',
  );
  await app.addDependency(
    'flutter_launcher_icons',
    dev: true,
  );

  final pubspec = await app.pubspec;
  final background = pubspec.background() ?? 'white';
  final foreground = pubspec.foreground() ?? 'black';

  final svg = await loadSvg(svgUrl);
  // final svgFileOriginal = await writeSvgToTemp(svg);
  changeFillColor(
    svg,
    foreground,
  );
  final svgFileWithColor = await writeSvgToTemp(svg);

  final assets = app.assets;
  await assets.create(recursive: true);

  final splashFile = app.splashPng;

  await svgToPng(
    svg: svgFileWithColor,
    png: app.iconPng,
    size: 1024,
    factor: 0.8,
    background: background,
    errorMessage: 'Failed to create icon PNG.',
  );
  await svgToPng(
    svg: svgFileWithColor,
    png: app.iconAdaptivePng,
    size: 1024,
    factor: 0.5,
    background: 'transparent',
    errorMessage: 'Failed to create adaptive icon PNG.',
  );

  await app.packageDir.run(
    'flutter',
    [
      'pub',
      'run',
      'flutter_launcher_icons',
    ],
    errorMessage: 'Failed to generate launcher icons.',
  );

  stdout.writeln("Writing splash screen to: ${splashFile.path}");
  await app.packageDir.run(
    'rsvg-convert',
    [
      '--keep-aspect-ratio',
      '--width',
      '1024',
      '--output',
      splashFile.path,
      svgFileWithColor.path,
    ],
    errorMessage: 'Failed to create splash screen PNG.',
  );

  // https://legacy.imagemagick.org/Usage/text/
  Future writeBrandPng(String? label, File target) async {
    if (label != null) {
      stdout.writeln('Creating branding file: ${target.path}');
      await app.packageDir.run(
        'convert',
        [
          '-pointsize',
          '72',
          '-fill',
          foreground,
          '-background',
          'transparent',
          '-bordercolor',
          'transparent',
          '-border',
          'x128',
          'label:$label',
          target.absolute.path,
        ],
      );
    } else {
      stdout.writeln(
          'Attribute not specified, not creating branding file: ${target.path}');
    }
  }

  final pubSpec = await app.pubspec;
  await writeBrandPng(pubSpec.title(), app.titlePng);
  await writeBrandPng(pubSpec.shortTitle(), app.shortTitlePng);

  await app.packageDir.run(
    'flutter',
    [
      'pub',
      'run',
      'flutter_native_splash:create',
    ],
    errorMessage: 'Failed to generate Flutter splash screen.',
  );

  const icon192 = 'Icon-192.png';
  const icon512 = 'Icon-512.png';
  const iconMaskable192 = 'Icon-maskable-192.png';
  const iconMaskable512 = 'Icon-maskable-512.png';

  final webIcons = app.webIcons;
  await webIcons.create(recursive: true);

  Future webIcon(
    String name,
    String maskable,
    int size,
  ) async {
    await svgToPng(
      svg: svgFileWithColor,
      png: webIcons.file(name),
      background: background,
      size: size,
      errorMessage: 'Failed to create web icon: $name',
    );
    await svgToPng(
      svg: svgFileWithColor,
      png: webIcons.file(maskable),
      background: background,
      size: size,
      factor: 0.8,
      errorMessage: 'Failed to create web icon: $maskable',
    );
  }

  await webIcon(icon192, iconMaskable192, 192);
  await webIcon(icon512, iconMaskable512, 512);

  await svgToPng(
    svg: svgFileWithColor,
    png: app.faviconPng,
    background: background,
    size: 16,
    errorMessage: 'Failed to create web favicon.png',
  );

  await svgToPng(
    svg: svgFileWithColor,
    png: app.playStorePng,
    background: background,
    size: 512,
  );
}

Future svgToPng({
  required File svg,
  required File png,
  String? background,
  required int size,
  double factor = 1.0,
  String? errorMessage,
}) async {
  stdout.writeln('Converting SVG to PNG: ${png.path}');

  final int iconSize = (size * factor).toInt();
  final int iconOffset = (size - iconSize) ~/ 2;

  await Directory.current.run(
    'rsvg-convert',
    [
      '--keep-aspect-ratio',
      '--page-width',
      size.toString(),
      '--page-height',
      size.toString(),
      '--width',
      iconSize.toString(),
      '--left',
      iconOffset.toString(),
      '--top',
      iconOffset.toString(),
      if (background != null) ...[
        '--background-color',
        background,
      ],
      '--output',
      png.path,
      svg.path,
    ],
    errorMessage: errorMessage,
  );
}
