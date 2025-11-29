import 'package:flutter/foundation.dart';
import 'fsrs_executor_stub.dart';

class FsrsExecutorWeb implements FsrsExecutor {
  @override
  Future<void> initialize() async {
    debugPrint('FSRS JS não suportado na Web via flutter_js (usando fallback Dart).');
  }

  @override
  Future<Map<String, dynamic>?> evaluate(Map<String, dynamic> params) async {
    // Retorna null para forçar o uso do fallback em Dart
    return null;
  }

  @override
  void dispose() {}
}

FsrsExecutor getExecutor() => FsrsExecutorWeb();

