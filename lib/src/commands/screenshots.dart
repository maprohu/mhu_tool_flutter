import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:mhu/src/commands/common.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:mhu_dart_commons/io.dart';
import 'package:mhu_dart_commons/screenshots.dart';

class ScreenshotsCommand extends Command<void> {
  final name = 'screenshots';
  final description = '''Takes screenshots for App Store listing.
  ''';

  @override
  List<String> get aliases => ['shots'];

  @override
  FutureOr<void>? run() async {
    await requirePackageDir((package) async {
      await takeScreenshots(package);
    });
  }
}

class SimctlRuntimes {
  List<Runtimes>? runtimes;

  SimctlRuntimes({this.runtimes});

  SimctlRuntimes.fromJson(Map<String, dynamic> json) {
    if (json['runtimes'] != null) {
      runtimes = <Runtimes>[];
      json['runtimes'].forEach((v) {
        runtimes!.add(new Runtimes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.runtimes != null) {
      data['runtimes'] = this.runtimes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Runtimes {
  String? bundlePath;
  String? buildversion;
  String? platform;
  String? runtimeRoot;
  String? identifier;
  String? version;
  bool? isInternal;
  bool? isAvailable;
  String? name;
  List<SupportedDeviceTypes>? supportedDeviceTypes;

  Runtimes(
      {this.bundlePath,
      this.buildversion,
      this.platform,
      this.runtimeRoot,
      this.identifier,
      this.version,
      this.isInternal,
      this.isAvailable,
      this.name,
      this.supportedDeviceTypes});

  Runtimes.fromJson(Map<String, dynamic> json) {
    bundlePath = json['bundlePath'];
    buildversion = json['buildversion'];
    platform = json['platform'];
    runtimeRoot = json['runtimeRoot'];
    identifier = json['identifier'];
    version = json['version'];
    isInternal = json['isInternal'];
    isAvailable = json['isAvailable'];
    name = json['name'];
    if (json['supportedDeviceTypes'] != null) {
      supportedDeviceTypes = <SupportedDeviceTypes>[];
      json['supportedDeviceTypes'].forEach((v) {
        supportedDeviceTypes!.add(new SupportedDeviceTypes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['bundlePath'] = this.bundlePath;
    data['buildversion'] = this.buildversion;
    data['platform'] = this.platform;
    data['runtimeRoot'] = this.runtimeRoot;
    data['identifier'] = this.identifier;
    data['version'] = this.version;
    data['isInternal'] = this.isInternal;
    data['isAvailable'] = this.isAvailable;
    data['name'] = this.name;
    if (this.supportedDeviceTypes != null) {
      data['supportedDeviceTypes'] =
          this.supportedDeviceTypes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SupportedDeviceTypes {
  String? bundlePath;
  String? name;
  String? identifier;
  String? productFamily;

  SupportedDeviceTypes(
      {this.bundlePath, this.name, this.identifier, this.productFamily});

  SupportedDeviceTypes.fromJson(Map<String, dynamic> json) {
    bundlePath = json['bundlePath'];
    name = json['name'];
    identifier = json['identifier'];
    productFamily = json['productFamily'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['bundlePath'] = this.bundlePath;
    data['name'] = this.name;
    data['identifier'] = this.identifier;
    data['productFamily'] = this.productFamily;
    return data;
  }
}

class SimctlDevices {
  Map<String, List<SimctlDevice>>? devices;

  SimctlDevices.fromJson(Map<String, dynamic> json) {
    json = json['devices']!;
    devices = {
      for (final e in json.entries)
        e.key: [
          for (final Map<String, dynamic> d in (e.value as List))
            SimctlDevice.fromJson(d)
        ],
    };
  }
}

class SimctlDevice {
  String? dataPath;
  int? dataPathSize;
  String? logPath;
  String? udid;
  bool? isAvailable;
  String? deviceTypeIdentifier;
  String? state;
  String? name;

  SimctlDevice({
    this.dataPath,
    this.dataPathSize,
    this.logPath,
    this.udid,
    this.isAvailable,
    this.deviceTypeIdentifier,
    this.state,
    this.name,
  });

  SimctlDevice.fromJson(Map<String, dynamic> json) {
    dataPath = json['dataPath'];
    dataPathSize = json['dataPathSize'];
    logPath = json['logPath'];
    udid = json['udid'];
    isAvailable = json['isAvailable'];
    deviceTypeIdentifier = json['deviceTypeIdentifier'];
    state = json['state'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['dataPath'] = this.dataPath;
    data['dataPathSize'] = this.dataPathSize;
    data['logPath'] = this.logPath;
    data['udid'] = this.udid;
    data['isAvailable'] = this.isAvailable;
    data['deviceTypeIdentifier'] = this.deviceTypeIdentifier;
    data['state'] = this.state;
    data['name'] = this.name;
    return data;
  }
}

Future<void> takeScreenshots(DartPackageDir package) async {
  final runtimesString = await package.packageDir.runAsString('xcrun', [
    'simctl',
    'list',
    'runtimes',
    'available',
    '-j',
  ]);

  final runtimes = SimctlRuntimes.fromJson(jsonDecode(runtimesString));

  final runtimeById = {
    for (final runtime in runtimes.runtimes!) runtime.identifier: runtime
  };

  final devicesString = await package.packageDir.runAsString('xcrun', [
    'simctl',
    'list',
    'devices',
    'available',
    '-j',
  ]);

  const phone67 = 'phone67';
  const phone55 = 'phone55';
  const pad6 = 'pad6';
  const pad2 = 'pad2';

  final deviceNames = {
    "iPhone 14 Pro Max": phone67,
    "iPhone 8 Plus": phone55,
    "iPad Pro (12.9-inch) (6th generation)": pad6,
    "iPad Pro (12.9-inch) (5th generation)": pad2,
  };

  final devices = SimctlDevices.fromJson(jsonDecode(devicesString));

  final simulators = devices.devices!.entries
      .expand(
        (element) => element.value.map(
          (e) => (
            runtime: runtimeById[element.key]!,
            device: e,
          ),
        ),
      )
      .where((element) => element.runtime.platform! == 'iOS')
      .groupListsBy((element) => element.device.name!)
      .map(
        (key, value) => MapEntry(
          key,
          value.maxBy(
            (element) => element.runtime.version!.let(double.parse),
          )!,
        ),
      )
      .entries
      .where((element) => deviceNames.containsKey(element.key))
      .map(
        (e) => (
          name: e.key,
          dir: deviceNames[e.key]!,
          version: e.value.runtime.version!,
          udid: e.value.device.udid!,
          booted: e.value.device.state == 'Booted',
        ),
      );

  final screenshotDir = package.packageDir.dirTo([
    'assets',
    'screenshots',
    'ios',
  ]);

  await screenshotDir.create(recursive: true);

  for (final sim in simulators) {
    print('booting: $sim');

    final targetDir = screenshotDir.dir(sim.dir);
    await targetDir.create(recursive: true);

    if (!sim.booted) {
      await package.packageDir.run('xcrun', [
        'simctl',
        'boot',
        sim.udid,
      ]);
    }

    final bound = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    print('bound: ${bound.port}');

    final running = await package.packageDir.startProcess('flutter', [
      'run',
      '-d',
      sim.udid,
      '-t',
      'tool/main_screenshots.dart',
      '--dart-define',
      '${ScreenshotParams.host}=${InternetAddress.loopbackIPv4.host}',
      '--dart-define',
      '${ScreenshotParams.port}=${bound.port}',
    ]);

    final client = await bound.first;

    var index = 0;
    Future<void> takeScreenshot(String name) async {
      index++;
      final indexString = index.toString().padLeft(3, '0');
      final fullName = '${indexString}_$name';
      print('taking screenshot: $fullName');

      final path = targetDir.file('$fullName.png');

      await package.packageDir.run('xcrun', [
        'simctl',
        'io',
        sim.udid,
        'screenshot',
        path.path,
      ]);
    }

    listening:
    await for (final bytes in client) {
      final msg = String.fromCharCodes(bytes);

      switch (msg) {
        case ScreenshotMessages.quit:
          break listening;
        case _:
          await takeScreenshot(msg);
          client.write(ScreenshotMessages.done);
          await client.flush();
      }
    }

    client.destroy();

    running.kill();

    await running.exitCode;

    await bound.close();
  }
}
