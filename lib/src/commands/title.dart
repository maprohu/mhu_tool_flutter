import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mhu/src/util/util.dart';
import 'package:mhu_dart_commons/io.dart';
import 'package:xml/xml.dart';
import 'common.dart';
import 'package:yaml/yaml.dart';
import 'package:html/parser.dart' as html;

const manifestJson = [
  'web',
  'manifest.json',
];
const indexHtml = [
  'web',
  'index.html',
];
const androidManifestXml = [
  'android',
  'app',
  'src',
  'main',
  'AndroidManifest.xml',
];

const infoPlist = [
  'ios',
  'Runner',
  'Info.plist',
];

class TitleCommand extends Command {
  final name = 'title';
  final description = '''Updates the title of the application on the supported platforms.
Currently supported platforms are: web, android, ios.
  
Need to add the following to pubspec.yaml before running the command

mhu:
  title: <title>
  short_title: <short title> # Optional, defaults to 'title'  
  '''
      .trim();

  @override
  FutureOr run() async {
    await requirePackageDir((package) async {
      await runTitle(package);
    });
  }
}

Future<void> runTitle(DartPackageDir package) async {
  final psy = package.pubspecYamlFile;
  final yamlString = await psy.readAsString();
  final yaml = loadYaml(yamlString, sourceUrl: psy.uri);
  final mhu = yaml['mhu'];
  final String? title = mhu?['title'];

  if (title == null) {
    throw MhuToolException(
        'The file ${psy.path} must contain the value "mhu.title".');
  }

  final String shortTitle = mhu['short_title'] ?? title;

  stdout.writeln("""Updating apps:
  title       = $title
  short_title = $shortTitle""");

  final titles = Title(title, shortTitle);

  final project = psy.parent;

  await updateIndexHtml(
    project.fileTo(indexHtml),
    titles,
  );

  await updateManifestJson(
    project.fileTo(manifestJson),
    titles,
  );

  await updateAndroidManifestXml(
    project.fileTo(androidManifestXml),
    titles,
  );

  await updateInfoPlist(
    project.fileTo(infoPlist),
    titles,
  );
}

class Title {
  final String title;
  final String shortTitle;

  Title(this.title, this.shortTitle);
}

Future updateIndexHtml(
  File file,
  Title title,
) async {
  if (!await file.exists()) {
    stdout.writeln("${file.path} does not exist, skipping web target.");
    return;
  }

  final htmlString = await file.readAsString();
  final doc = html.parse(
    htmlString,
    sourceUrl: file.uri.toString(),
  );

  final head = doc.head!;

  final titleElements = head.querySelectorAll('title');

  var dirty = false;

  if (titleElements.isEmpty) {
    stderr.writeln("WARNING: 'title' element not found in ${file.path}");
  } else if (titleElements.length > 1) {
    stderr.writeln(
      "WARNING: ${titleElements.length} 'title' elements found in ${file.path}",
    );
  }

  for (final titleElement in titleElements) {
    if (titleElement.innerHtml != title.title) {
      titleElement.innerHtml = title.title;
      dirty = true;
    }
  }

  final appleTitles =
      head.querySelectorAll('meta[name="apple-mobile-web-app-title"]');

  if (appleTitles.isEmpty) {
    stderr
        .writeln("WARNING: Apple title meta element not found in ${file.path}");
  } else if (appleTitles.length > 1) {
    stderr.writeln(
      "WARNING: ${appleTitles.length} Apple title meta elements found in ${file.path}",
    );
  }

  for (final titleElement in appleTitles) {
    if (titleElement.attributes['content'] != title.title) {
      titleElement.attributes['content'] = title.title;
      dirty = true;
    }
  }

  await writeIfDirty(
    file: file,
    dirty: dirty,
    content: () => doc.outerHtml,
  );
}

Future updateManifestJson(
  File file,
  Title title,
) async {
  if (!await file.exists()) {
    stdout.writeln("${file.path} does not exist, skipping target.");
    return;
  }

  final jsonString = await file.readAsString();
  final json = jsonDecode(jsonString);

  var dirty = false;

  if (json['name'] != title.title) {
    json['name'] = title.title;
    dirty = true;
  }

  if (json['short_name'] != title.shortTitle) {
    json['short_name'] = title.shortTitle;
    dirty = true;
  }

  await writeIfDirty(
    file: file,
    dirty: dirty,
    content: () {
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    },
  );
}

Future updateAndroidManifestXml(
  File file,
  Title title,
) async {
  if (!await file.exists()) {
    stdout.writeln("${file.path} does not exist, skipping target.");
    return;
  }

  final xmlString = await file.readAsString();
  final doc = XmlDocument.parse(xmlString);

  var dirty = false;

  final appElement = doc.rootElement.childElements
      .firstWhere((e) => e.name.local == 'application');

  final labelAttr =
      appElement.attributes.firstWhere((e) => e.name.local == 'label');

  if (labelAttr.value != title.shortTitle) {
    dirty = true;
    labelAttr.value = title.shortTitle;
  }

  await writeIfDirty(
    file: file,
    dirty: dirty,
    content: () {
      return doc.toXmlString(pretty: true);
    },
  );
}

Future updateInfoPlist(
  File file,
  Title title,
) async {
  if (!await file.exists()) {
    stdout.writeln("${file.path} does not exist, skipping target.");
    return;
  }

  final xmlString = await file.readAsString();
  final doc = XmlDocument.parse(xmlString);

  var dirty = false;

  final dictElement =
      doc.rootElement.childElements.firstWhere((e) => e.name.local == 'dict');

  final nameKey = dictElement.childElements.firstWhere(
      (e) => e.name.local == 'key' && e.innerText == 'CFBundleDisplayName');
  final nameValue = nameKey.nextElementSibling!;

  if (nameValue.name.local != 'string') {
    throw MhuToolException(
      'Unexpected element found: ${nameValue.toXmlString(pretty: true)}',
    );
  }

  if (nameValue.innerText != title.shortTitle) {
    dirty = true;
    nameValue.innerText = title.shortTitle;
  }

  await writeIfDirty(
    file: file,
    dirty: dirty,
    content: () {
      return doc.toXmlString(pretty: true);
    },
  );
}
