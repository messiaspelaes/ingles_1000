/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 * Baseado em libanki/src/main/java/com/ichi2/anki/libanki/Card.kt
 */

/// Estado do card (queue type)
/// Baseado em AnkiDroid QueueType enum
enum CardQueueType {
  newCard('NEW'),
  learning('LEARNING'),
  review('REVIEW'),
  relearning('RELEARNING');

  final String value;
  const CardQueueType(this.value);
}

/// Rating da resposta do usuário
/// Baseado em AnkiDroid Rating enum
enum CardRating {
  again(1), // Esqueceu
  hard(2),  // Difícil
  good(3),  // Bom
  easy(4);  // Fácil

  final int value;
  const CardRating(this.value);

  static CardRating fromValue(int value) {
    return CardRating.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CardRating.good,
    );
  }
}

/// Modelo de Card para repetição espaçada
/// Adaptado da estrutura do AnkiDroid
class Card {
  final String id;
  final String noteId;
  final String deckId;
  final String userId;

  // Estado
  CardQueueType queueType;
  
  // FSRS Parameters (Free Spaced Repetition Scheduler)
  // Adaptado de AnkiDroid FSRS implementation
  double fsrsDifficulty;      // Dificuldade (0-1)
  double fsrsStability;       // Estabilidade em dias
  double fsrsRetrievability;  // Probabilidade de recall (0-1)
  
  // Scheduling
  DateTime dueDate;           // Próxima revisão
  int intervalDays;          // Intervalo atual em dias
  double easeFactor;          // Fator de facilidade (legado SM-2)
  
  // Estatísticas
  int reviewsCount;
  int lapsesCount;
  DateTime? lastReviewAt;
  
  // Timestamps
  final DateTime createdAt;
  DateTime updatedAt;
  
  // Metadata do Anki (se importado)
  final int? ankiCardId;
  final int? ankiDue;

  Card({
    required this.id,
    required this.noteId,
    required this.deckId,
    required this.userId,
    this.queueType = CardQueueType.newCard,
    this.fsrsDifficulty = 0.3,
    this.fsrsStability = 0.0,
    this.fsrsRetrievability = 1.0,
    required this.dueDate,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.reviewsCount = 0,
    this.lapsesCount = 0,
    this.lastReviewAt,
    required this.createdAt,
    required this.updatedAt,
    this.ankiCardId,
    this.ankiDue,
  });

  /// Cria um Card a partir de um Map (Supabase)
  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'] as String,
      noteId: map['note_id'] as String,
      deckId: map['deck_id'] as String,
      userId: map['user_id'] as String,
      queueType: CardQueueType.values.firstWhere(
        (e) => e.value == map['queue_type'],
        orElse: () => CardQueueType.newCard,
      ),
      fsrsDifficulty: (map['fsrs_difficulty'] as num?)?.toDouble() ?? 0.3,
      fsrsStability: (map['fsrs_stability'] as num?)?.toDouble() ?? 0.0,
      fsrsRetrievability:
          (map['fsrs_retrievability'] as num?)?.toDouble() ?? 1.0,
      dueDate: DateTime.parse(map['due_date'] as String),
      intervalDays: map['interval_days'] as int? ?? 0,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      reviewsCount: map['reviews_count'] as int? ?? 0,
      lapsesCount: map['lapses_count'] as int? ?? 0,
      lastReviewAt: map['last_review_at'] != null
          ? DateTime.parse(map['last_review_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      ankiCardId: map['anki_card_id'] as int?,
      ankiDue: map['anki_due'] as int?,
    );
  }

  /// Converte Card para Map (Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'deck_id': deckId,
      'user_id': userId,
      'queue_type': queueType.value,
      'fsrs_difficulty': fsrsDifficulty,
      'fsrs_stability': fsrsStability,
      'fsrs_retrievability': fsrsRetrievability,
      'due_date': dueDate.toIso8601String(),
      'interval_days': intervalDays,
      'ease_factor': easeFactor,
      'reviews_count': reviewsCount,
      'lapses_count': lapsesCount,
      'last_review_at': lastReviewAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'anki_card_id': ankiCardId,
      'anki_due': ankiDue,
    };
  }

  /// Verifica se o card está vencido (due)
  bool get isDue => DateTime.now().isAfter(dueDate);

  /// Verifica se o card está em estado de revisão
  bool get isReview => queueType == CardQueueType.review;

  /// Verifica se o card está em estado de aprendizado
  bool get isLearning =>
      queueType == CardQueueType.learning ||
      queueType == CardQueueType.relearning;
}

