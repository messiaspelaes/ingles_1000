import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'dart:convert';
import 'fsrs_executor_stub.dart';

class FsrsExecutorNative implements FsrsExecutor {
  JavascriptRuntime? _jsRuntime;

  @override
  Future<void> initialize() async {
    try {
      _jsRuntime = getJavascriptRuntime();
      
      // Tenta carregar fsrs.js (opcional por enquanto)
      try {
        final fsrsCode = await rootBundle.loadString('assets/js/fsrs.js');
        _jsRuntime!.evaluate(fsrsCode);
      } catch (e) {
        debugPrint('Aviso: fsrs.js não encontrado (Native).');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar FSRS Native: $e');
      _jsRuntime = null;
    }
  }

  @override
  Future<Map<String, dynamic>?> evaluate(Map<String, dynamic> params) async {
    if (_jsRuntime == null) return null;

    final jsCode = '''
      (function() {
        const params = ${jsonEncode(params)};
        // Simulação temporária igual ao serviço original
        const newStability = params.stability * 1.5;
        const newDifficulty = params.difficulty;
        const newInterval = Math.max(1, Math.floor(newStability));
        
        return {
          difficulty: newDifficulty,
          stability: newStability,
          interval: newInterval,
          dueDate: params.now + (newInterval * 24 * 60 * 60 * 1000)
        };
      })();
    ''';

    try {
      final result = _jsRuntime!.evaluate(jsCode);
      if (result.isError) {
        debugPrint('JS Error: ${result.stringResult}');
        return null;
      }
      return jsonDecode(result.stringResult) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JS Evaluate Error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _jsRuntime?.dispose();
  }
}

FsrsExecutor getExecutor() => FsrsExecutorNative();

