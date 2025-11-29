/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 * Baseado em libanki/src/main/java/com/ichi2/anki/libanki/revlog
 */

import 'card.dart';

/// Modelo de Review Log - Histórico de revisões
/// Baseado em AnkiDroid revlog
class ReviewLog {
  final String id;
  final String cardId;
  final String userId;

  /// Rating (AGAIN=1, HARD=2, GOOD=3, EASY=4)
  final CardRating rating;

  /// Intervalo antes e depois da revisão
  final int? intervalBefore;
  final int? intervalAfter;

  /// Tempo gasto na revisão (milissegundos)
  final int timeTakenMs;

  /// FSRS state antes e depois
  final double? fsrsDifficultyBefore;
  final double? fsrsStabilityBefore;
  final double? fsrsDifficultyAfter;
  final double? fsrsStabilityAfter;

  /// Timestamp
  final DateTime reviewedAt;

  ReviewLog({
    required this.id,
    required this.cardId,
    required this.userId,
    required this.rating,
    this.intervalBefore,
    this.intervalAfter,
    this.timeTakenMs = 0,
    this.fsrsDifficultyBefore,
    this.fsrsStabilityBefore,
    this.fsrsDifficultyAfter,
    this.fsrsStabilityAfter,
    required this.reviewedAt,
  });

  /// Cria um ReviewLog a partir de um Map (Supabase)
  factory ReviewLog.fromMap(Map<String, dynamic> map) {
    return ReviewLog(
      id: map['id'] as String,
      cardId: map['card_id'] as String,
      userId: map['user_id'] as String,
      rating: CardRating.fromValue(map['rating'] as int),
      intervalBefore: map['interval_before'] as int?,
      intervalAfter: map['interval_after'] as int?,
      timeTakenMs: map['time_taken_ms'] as int? ?? 0,
      fsrsDifficultyBefore:
          (map['fsrs_difficulty_before'] as num?)?.toDouble(),
      fsrsStabilityBefore:
          (map['fsrs_stability_before'] as num?)?.toDouble(),
      fsrsDifficultyAfter:
          (map['fsrs_difficulty_after'] as num?)?.toDouble(),
      fsrsStabilityAfter:
          (map['fsrs_stability_after'] as num?)?.toDouble(),
      reviewedAt: DateTime.parse(map['reviewed_at'] as String),
    );
  }

  /// Converte ReviewLog para Map (Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'user_id': userId,
      'rating': rating.value,
      'interval_before': intervalBefore,
      'interval_after': intervalAfter,
      'time_taken_ms': timeTakenMs,
      'fsrs_difficulty_before': fsrsDifficultyBefore,
      'fsrs_stability_before': fsrsStabilityBefore,
      'fsrs_difficulty_after': fsrsDifficultyAfter,
      'fsrs_stability_after': fsrsStabilityAfter,
      'reviewed_at': reviewedAt.toIso8601String(),
    };
  }
}

