/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 */

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card.dart';
import '../models/note.dart';
import '../models/review_log.dart';

/// Serviço para interagir com Supabase
class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Obtém o usuário atual
  User? get currentUser => _client.auth.currentUser;

  /// Obtém cards que estão vencidos (due) para revisão
  Future<List<Card>> getDueCards({String? deckId}) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    var query = _client
        .from('cards')
        .select()
        .eq('user_id', userId)
        .lte('due_date', DateTime.now().toIso8601String())
        .order('due_date', ascending: true)
        .limit(50);

    if (deckId != null) {
      query = query.eq('deck_id', deckId);
    }

    final response = await query;
    return (response as List)
        .map((map) => Card.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  /// Salva um card
  Future<void> saveCard(Card card) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    await _client.from('cards').upsert(card.toMap());
  }

  /// Salva uma nota
  Future<void> saveNote(Note note) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    await _client.from('notes').upsert(note.toMap());
  }

  /// Salva um log de revisão
  Future<void> saveReviewLog(ReviewLog reviewLog) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    await _client.from('review_logs').insert(reviewLog.toMap());
  }

  /// Obtém todas as notas de um deck
  Future<List<Note>> getNotes(String deckId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    final response = await _client
        .from('notes')
        .select()
        .eq('deck_id', deckId)
        .eq('user_id', userId);

    return (response as List)
        .map((map) => Note.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  /// Cria um novo deck
  Future<String> createDeck(String name, {String? description}) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    final response = await _client.from('decks').insert({
      'user_id': userId,
      'name': name,
      'description': description,
    }).select();

    return (response.first as Map<String, dynamic>)['id'] as String;
  }
}

