/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 * Utiliza o pacote oficial Dart FSRS - https://pub.dev/packages/fsrs
 */

import 'package:fsrs/fsrs.dart' as fsrs;
import '../models/card.dart' as models;
import '../utils/app_logger.dart';

/// Serviço para calcular intervalos usando o pacote nativo FSRS em Dart.
class FsrsService {
  static final FsrsService _instance = FsrsService._internal();
  factory FsrsService() => _instance;
  FsrsService._internal();

  final fsrs.Scheduler _scheduler = fsrs.Scheduler();
  bool _initialized = false;

  /// Inicializa o serviço (agora apenas marca como pronto, já que o scheduler é nativo)
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    AppLogger.i(LogCategory.fsrs, 'FSRS nativo inicializado');
  }

  /// Calcula o próximo estado do card após uma revisão
  Future<FsrsResult> calculateNextState({
    required models.Card card,
    required models.CardRating rating,
    required DateTime now,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // 1. Mapeia o estado do card do app para o estado do pacote fsrs
      fsrs.State fsrsState;
      switch (card.queueType) {
        case models.CardQueueType.newCard:
          fsrsState =
              fsrs
                  .State
                  .learning; // FSRS não tem estado 'newCard', usa learning
          break;
        case models.CardQueueType.learning:
          fsrsState = fsrs.State.learning;
          break;
        case models.CardQueueType.review:
          fsrsState = fsrs.State.review;
          break;
        case models.CardQueueType.relearning:
          fsrsState = fsrs.State.relearning;
          break;
      }

      // 2. Cria o objeto Card esperado pelo pacote fsrs
      // Nota: o pacote usa UTC para datas e cardId é obrigatório (usamos o ankiCardId ou hash do ID)
      final fsrsCard = fsrs.Card(
        cardId: card.ankiCardId ?? card.id.hashCode,
        due: card.dueDate.toUtc(),
        stability: card.fsrsStability > 0 ? card.fsrsStability : null,
        difficulty: card.fsrsDifficulty > 0 ? card.fsrsDifficulty : null,
        state: fsrsState,
        lastReview: card.lastReviewAt?.toUtc(),
      );

      // 3. Mapeia o rating do app para o rating do pacote fsrs
      fsrs.Rating fsrsRating;
      switch (rating) {
        case models.CardRating.again:
          fsrsRating = fsrs.Rating.again;
          break;
        case models.CardRating.hard:
          fsrsRating = fsrs.Rating.hard;
          break;
        case models.CardRating.good:
          fsrsRating = fsrs.Rating.good;
          break;
        case models.CardRating.easy:
          fsrsRating = fsrs.Rating.easy;
          break;
      }

      // 4. Executa o cálculo
      final reviewResult = _scheduler.reviewCard(
        fsrsCard,
        fsrsRating,
        reviewDateTime: now.toUtc(),
      );
      final nextCard = reviewResult.card;

      return FsrsResult(
        difficulty: nextCard.difficulty ?? card.fsrsDifficulty,
        stability: nextCard.stability ?? card.fsrsStability,
        intervalDays: nextCard.due.difference(now).inDays.clamp(1, 365),
        dueDate: nextCard.due.toLocal(),
      );
    } catch (e, stack) {
      AppLogger.e(LogCategory.fsrs, 'Erro no cálculo FSRS nativo', e, stack);
      // Fallback para cálculo simples se algo der errado
      return _calculateFallback(card, rating, now);
    }
  }

  /// Cálculo fallback simplificado (SM-2 like) caso o pacote falhe
  FsrsResult _calculateFallback(
    models.Card card,
    models.CardRating rating,
    DateTime now,
  ) {
    double newStability = card.fsrsStability;
    double newDifficulty = card.fsrsDifficulty;
    int newInterval = 1;

    switch (rating) {
      case models.CardRating.again:
        newStability = 0.0;
        newDifficulty = (card.fsrsDifficulty + 0.2).clamp(0.0, 1.0);
        newInterval = 1;
        break;
      case models.CardRating.hard:
        newStability = card.fsrsStability * 1.2;
        newDifficulty = (card.fsrsDifficulty + 0.15).clamp(0.0, 1.0);
        newInterval = (newStability).round().clamp(1, 365);
        break;
      case models.CardRating.good:
        newStability = card.fsrsStability * 2.5;
        newDifficulty = card.fsrsDifficulty;
        newInterval = (newStability).round().clamp(1, 365);
        break;
      case models.CardRating.easy:
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

  /// Limpa recursos (vazio para o scheduler nativo)
  void dispose() {
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
