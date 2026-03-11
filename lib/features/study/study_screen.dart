/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 * Baseado em AnkiDroid/src/main/java/com/ichi2/anki/Reviewer.kt
 */

import 'package:flutter/material.dart' hide Card;
import '../../models/card.dart';
import '../../models/note.dart';
import '../../services/fsrs_service.dart';
import '../../services/database_service.dart';
import '../../core/widgets/anki_content.dart';

/// Tela de estudo com cards
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final FsrsService _fsrsService = FsrsService();
  final DatabaseService _databaseService = DatabaseService();

  Card? _currentCard;
  Note? _currentNote;
  bool _showAnswer = false;
  bool _isLoading = false;
  
  // Contadores para UI
  int _novosRestantes = 0;
  int _revisoesRestantes = 0;
  final int _limitNovos = 10;
  final int _limitRevisoes = 10;

  @override
  void initState() {
    super.initState();
    _loadNextCard();
  }

  Future<void> _loadNextCard() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _showAnswer = false;
    });

    try {
      // Pegar quantos já foram estudados hoje
      final int novosEstudados = await _databaseService.getStudiedNewCardsTodayCount();
      final int revisoesEstudadas = await _databaseService.getStudiedReviewCardsTodayCount();

      // Calcular quantos restam para hoje
      final int novosRestantes = (_limitNovos - novosEstudados).clamp(0, _limitNovos);
      final int revisoesRestantes = (_limitRevisoes - revisoesEstudadas).clamp(0, _limitRevisoes);

      Card? nextCard;

      // Prioridade 1: Revisões pendentes
      if (revisoesRestantes > 0) {
        final reviewCards = await _databaseService.getReviewCards(limit: revisoesRestantes);
        if (reviewCards.isNotEmpty) {
          nextCard = reviewCards.first;
        }
      }

      // Prioridade 2: Se não tem revisão ou acabaram, puxar novos
      if (nextCard == null && novosRestantes > 0) {
        final newCards = await _databaseService.getNewCards(limit: novosRestantes);
        if (newCards.isNotEmpty) {
          nextCard = newCards.first;
        }
      }
      
      if (nextCard != null && mounted) {
        final note = await _databaseService.getNoteById(nextCard.noteId);
        
        setState(() {
          _currentCard = nextCard;
          _currentNote = note;
          _novosRestantes = novosRestantes;
          _revisoesRestantes = revisoesRestantes;
        });
      } else if (mounted) {
        setState(() {
          _currentCard = null;
          _currentNote = null;
          _novosRestantes = novosRestantes;
          _revisoesRestantes = revisoesRestantes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar cards: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _answerCard(CardRating rating) async {
    if (_currentCard == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Calcular próximo estado com FSRS
      final fsrsResult = await _fsrsService.calculateNextState(
        card: _currentCard!,
        rating: rating,
        now: DateTime.now(),
      );

      // 2. Atualizar card
      _currentCard!.fsrsDifficulty = fsrsResult.difficulty;
      _currentCard!.fsrsStability = fsrsResult.stability;
      _currentCard!.intervalDays = fsrsResult.intervalDays;
      _currentCard!.dueDate = fsrsResult.dueDate;
      _currentCard!.reviewsCount++;
      _currentCard!.lastReviewAt = DateTime.now();
      _currentCard!.updatedAt = DateTime.now();

      if (rating == CardRating.again) {
        _currentCard!.lapsesCount++;
        _currentCard!.queueType = CardQueueType.relearning;
      } else {
        _currentCard!.queueType = CardQueueType.review;
      }

      // 3. Salvar no banco local
      await _databaseService.saveCard(_currentCard!);

      // 4. Carregar próximo card
      await _loadNextCard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar resposta: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentCard == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentCard == null && _currentNote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estudar')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
              const SizedBox(height: 16),
              const Text(
                'Parabéns!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você completou a sua meta de estudos de hoje.\nVolte amanhã para mais!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar ao Menu'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Mostrar informações do card
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progresso Hibrido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fiber_new, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Novos: $_novosRestantes / $_limitNovos',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: _currentCard?.queueType == CardQueueType.newCard ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Revisão: $_revisoesRestantes / $_limitRevisoes',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: _currentCard?.queueType != CardQueueType.newCard ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Card
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Material(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_showAnswer)
                            AnkiContent(
                              content: _currentNote?.frontField ?? 'Pergunta',
                              deckId: _currentCard?.deckId ?? '',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else
                            Column(
                              children: [
                                AnkiContent(
                                  content: _currentNote?.frontField ?? 'Pergunta',
                                  deckId: _currentCard?.deckId ?? '',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: AnkiContent(
                                    content: _currentNote?.backField ?? 'Resposta',
                                    deckId: _currentCard?.deckId ?? '',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Botões de resposta
          if (_showAnswer)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAnswerButton(
                      'Novamente',
                      CardRating.again,
                      Colors.red,
                    ),
                    _buildAnswerButton(
                      'Difícil',
                      CardRating.hard,
                      Colors.orange,
                    ),
                    _buildAnswerButton(
                      'Bom',
                      CardRating.good,
                      Colors.blue,
                    ),
                    _buildAnswerButton(
                      'Fácil',
                      CardRating.easy,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAnswer = true;
                      });
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Mostrar Resposta'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String label, CardRating rating, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  _answerCard(rating);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

