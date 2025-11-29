/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 * Baseado em libanki/src/main/java/com/ichi2/anki/libanki/Note.kt
 */

/// Modelo de Note (Nota) - Conteúdo base dos flashcards
/// Adaptado da estrutura do AnkiDroid
class Note {
  final String id;
  final String deckId;
  final String userId;

  /// Campos do card (lista de strings)
  /// Ex: ["Hello", "Olá", "audio.mp3"]
  final List<String> fields;

  /// Tags
  final List<String> tags;

  /// Modelo/Template (ex: "Basic", "Basic (and reversed card)")
  final String modelName;

  /// Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Metadata do Anki (se importado)
  final String? ankiGuid;
  final int? ankiNoteId;

  Note({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.fields,
    this.tags = const [],
    this.modelName = 'Basic',
    required this.createdAt,
    required this.updatedAt,
    this.ankiGuid,
    this.ankiNoteId,
  });

  /// Cria um Note a partir de um Map (Supabase)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      userId: map['user_id'] as String,
      fields: List<String>.from(map['fields'] as List),
      tags: List<String>.from(map['tags'] as List? ?? []),
      modelName: map['model_name'] as String? ?? 'Basic',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      ankiGuid: map['anki_guid'] as String?,
      ankiNoteId: map['anki_note_id'] as int?,
    );
  }

  /// Converte Note para Map (Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'user_id': userId,
      'fields': fields,
      'tags': tags,
      'model_name': modelName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'anki_guid': ankiGuid,
      'anki_note_id': ankiNoteId,
    };
  }

  /// Retorna o campo frontal (primeiro campo)
  String get frontField => fields.isNotEmpty ? fields[0] : '';

  /// Retorna o campo traseiro (segundo campo)
  String get backField => fields.length > 1 ? fields[1] : '';
}

