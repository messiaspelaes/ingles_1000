/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 * Utiliza FSRS (Free Spaced Repetition Scheduler) - https://github.com/open-spaced-repetition/fsrs4anki
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'fsrs/fsrs_executor.dart';
import '../models/card.dart';

/// Serviço para calcular intervalos usando FSRS
/// Integra fsrs.js via flutter_js
class FsrsService {
  static final FsrsService _instance = FsrsService._internal();
  factory FsrsService() => _instance;
  FsrsService._internal();

  FsrsExecutor? _executor;
  bool _initialized = false;

  /// Inicializa o runtime JavaScript e carrega fsrs.js
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Tenta criar o executor (Native ou Web)
      try {
        _executor = getFsrsExecutor();
        await _executor!.initialize();
      } catch (e) {
        // Se o runtime JS não estiver disponível, usa apenas fallback
        debugPrint('Aviso: Runtime JavaScript não disponível, usando cálculo fallback: $e');
        _executor = null;
      }
      
      _initialized = true;
    } catch (e) {
      // Em caso de erro, marca como inicializado mas sem JS runtime
      _initialized = true;
      _executor = null;
      debugPrint('Erro ao inicializar FSRS, usando cálculo fallback: $e');
    }
  }

  /// Calcula o próximo estado do card após uma revisão
  /// Baseado em AnkiDroid Scheduler.answerCard()
  Future<FsrsResult> calculateNextState({
    required Card card,
    required CardRating rating,
    required DateTime now,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Prepara os parâmetros FSRS
      final params = {
        'difficulty': card.fsrsDifficulty,
        'stability': card.fsrsStability,
        'retrievability': card.fsrsRetrievability,
        'lastReview': card.lastReviewAt?.millisecondsSinceEpoch ?? now.millisecondsSinceEpoch,
        'now': now.millisecondsSinceEpoch,
        'rating': rating.value,
      };

      if (_executor == null) {
        // Se não houver runtime JS, usa fallback
        return _calculateFallback(card, rating, now);
      }

      final resultMap = await _executor!.evaluate(params);

      if (resultMap == null) {
        return _calculateFallback(card, rating, now);
      }

      return FsrsResult(
        difficulty: (resultMap['difficulty'] as num).toDouble(),
        stability: (resultMap['stability'] as num).toDouble(),
        intervalDays: (resultMap['interval'] as num).toInt(),
        dueDate: DateTime.fromMillisecondsSinceEpoch(resultMap['dueDate'] as int),
      );
    } catch (e) {
      debugPrint('Erro no cálculo FSRS: $e');
      // Fallback para cálculo simples se FSRS falhar
      return _calculateFallback(card, rating, now);
    }
  }

  /// Cálculo fallback simplificado (SM-2 like)
  FsrsResult _calculateFallback(Card card, CardRating rating, DateTime now) {
    double newStability = card.fsrsStability;
    double newDifficulty = card.fsrsDifficulty;
    int newInterval = 1;

    switch (rating) {
      case CardRating.again:
        newStability = 0.0;
        newDifficulty = (card.fsrsDifficulty + 0.2).clamp(0.0, 1.0);
        newInterval = 1;
        break;
      case CardRating.hard:
        newStability = card.fsrsStability * 1.2;
        newDifficulty = (card.fsrsDifficulty + 0.15).clamp(0.0, 1.0);
        newInterval = (newStability).round().clamp(1, 365);
        break;
      case CardRating.good:
        newStability = card.fsrsStability * 2.5;
        newDifficulty = card.fsrsDifficulty;
        newInterval = (newStability).round().clamp(1, 365);
        break;
      case CardRating.easy:
        newStability = card.fsrsStability * 4.0;
        newDifficulty = (card.fsrsDifficulty - 0.15).clamp(0.0, 1.0);
        newInterval = (newStability).round().clamp(1, 365);
        break;
    }

    return FsrsResult(
      difficulty: newDifficulty,
      stability: newStability,
      intervalDays: newInterval,
      dueDate: now.add(Duration(days: newInterval)),
    );
  }

  /// Limpa recursos
  void dispose() {
    _executor?.dispose();
    _initialized = false;
  }
}

/// Resultado do cálculo FSRS
class FsrsResult {
  final double difficulty;
  final double stability;
  final int intervalDays;
  final DateTime dueDate;

  FsrsResult({
    required this.difficulty,
    required this.stability,
    required this.intervalDays,
    required this.dueDate,
  });
}
