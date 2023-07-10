import 'package:mhu_dart_commons/commons.dart';

class MhuToolException implements MhuException {
  final String message;

  MhuToolException(this.message);

  @override
  String toString() {
    return '$runtimeType: $message';
  }
}