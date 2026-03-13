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
import '../../models/review_log.dart';
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

  // Fila de cards da sessão atual
  final List<Card> _newQueue = [];
  final List<Card> _reviewQueue = [];

  Card? _currentCard;
  Note? _currentNote;
  bool _showAnswer = false;
  bool _isLoading = true;

  // Contadores da sessão (decrementam conforme respostas)
  int _novosRestantes = 0;
  int _revisoesRestantes = 0;

  // Para calcular tempo gasto no card
  DateTime? _cardShownAt;

  // Limite de novos por dia (FSRS padrão = 10)
  static const int _limitNovos = 10;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  /// Inicializa a sessão: carrega as filas e define os contadores
  Future<void> _initSession() async {
    setState(() => _isLoading = true);

    try {
      // Quantos novos já foram estudados hoje (para respeitar o limite diário)
      final novosHoje = await _databaseService.getStudiedNewCardsTodayCount();
      final novosPossiveis = (_limitNovos - novosHoje).clamp(0, _limitNovos);

      // Carregar filas da sessão
      final novos = await _databaseService.getNewCards(limit: novosPossiveis);
      final revisoes = await _databaseService.getReviewCards(); // Todos os devidos

      _newQueue.clear();
      _reviewQueue.clear();
      _newQueue.addAll(novos);
      _reviewQueue.addAll(revisoes);

      setState(() {
        _novosRestantes = _newQueue.length;
        _revisoesRestantes = _reviewQueue.length;
      });

      await _showNextCard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar sessão: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Pega o próximo card da fila e exibe
  Future<void> _showNextCard() async {
    Card? next;

    // Prioridade: revisões primeiro, depois novos
    if (_reviewQueue.isNotEmpty) {
      next = _reviewQueue.removeAt(0);
    } else if (_newQueue.isNotEmpty) {
      next = _newQueue.removeAt(0);
    }

    if (next != null) {
      final note = await _databaseService.getNoteById(next.noteId);
      if (mounted) {
        setState(() {
          _currentCard = next;
          _currentNote = note;
          _showAnswer = false;
          _cardShownAt = DateTime.now();
        });
      }
    } else {
      // Sessão encerrada
      if (mounted) {
        setState(() {
          _currentCard = null;
          _currentNote = null;
        });
      }
    }
  }

  Future<void> _answerCard(CardRating rating) async {
    if (_currentCard == null) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final timeTakenMs = _cardShownAt != null
          ? now.difference(_cardShownAt!).inMilliseconds
          : 0;

      // Guardar estado FSRS anterior para o ReviewLog
      final difficultyBefore = _currentCard!.fsrsDifficulty;
      final stabilityBefore = _currentCard!.fsrsStability;
      final intervalBefore = _currentCard!.intervalDays;
      final wasNew = _currentCard!.queueType == CardQueueType.newCard;

      // 1. Calcular próximo estado com FSRS
      final fsrsResult = await _fsrsService.calculateNextState(
        card: _currentCard!,
        rating: rating,
        now: now,
      );

      // 2. Atualizar card
      _currentCard!.fsrsDifficulty = fsrsResult.difficulty;
      _currentCard!.fsrsStability = fsrsResult.stability;
      _currentCard!.intervalDays = fsrsResult.intervalDays;
      _currentCard!.dueDate = fsrsResult.dueDate;
      _currentCard!.reviewsCount++;
      _currentCard!.lastReviewAt = now;
      _currentCard!.updatedAt = now;

      if (rating == CardRating.again) {
        _currentCard!.lapsesCount++;
        _currentCard!.queueType = CardQueueType.relearning;
      } else {
        _currentCard!.queueType = CardQueueType.review;
      }

      // 3. Salvar card atualizado
      await _databaseService.saveCard(_currentCard!);

      // 4. Salvar ReviewLog (isso é o que faz os contadores funcionarem)
      final reviewLog = ReviewLog(
        id: '${now.millisecondsSinceEpoch}_${_currentCard!.id}',
        cardId: _currentCard!.id,
        userId: '',
        rating: rating,
        intervalBefore: intervalBefore,
        intervalAfter: fsrsResult.intervalDays,
        timeTakenMs: timeTakenMs,
        fsrsDifficultyBefore: difficultyBefore,
        fsrsStabilityBefore: stabilityBefore,
        fsrsDifficultyAfter: fsrsResult.difficulty,
        fsrsStabilityAfter: fsrsResult.stability,
        reviewedAt: now,
      );
      await _databaseService.saveReviewLog(reviewLog);

      // 5. Decrementar contador correto
      if (wasNew) {
        setState(() => _novosRestantes = (_novosRestantes - 1).clamp(0, _limitNovos));
      } else {
        setState(() => _revisoesRestantes = (_revisoesRestantes - 1).clamp(0, _revisoesRestantes));
      }

      // 6. Próximo card
      await _showNextCard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar resposta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                'Parabéns! 🎉',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você completou sua sessão de hoje.\nVolte amanhã para continuar!',
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
      ),
      body: Column(
        children: [
          // Barra de progresso da sessão
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCounter(
                  icon: Icons.fiber_new,
                  color: Colors.blue[700]!,
                  label: 'Novos',
                  value: _novosRestantes,
                  isCurrent: _currentCard?.queueType == CardQueueType.newCard,
                ),
                const SizedBox(width: 32),
                _buildCounter(
                  icon: Icons.history,
                  color: Colors.orange[700]!,
                  label: 'Revisão',
                  value: _revisoesRestantes,
                  isCurrent: _currentCard?.queueType != CardQueueType.newCard,
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
                              content: _currentNote?.frontField ?? '',
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
                                  content: _currentNote?.frontField ?? '',
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
                                    content: _currentNote?.backField ?? '',
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

          // Botões
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
                    _buildAnswerButton('Novamente', CardRating.again, Colors.red),
                    _buildAnswerButton('Difícil', CardRating.hard, Colors.orange),
                    _buildAnswerButton('Bom', CardRating.good, Colors.blue),
                    _buildAnswerButton('Fácil', CardRating.easy, Colors.green),
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
                    onPressed: () => setState(() => _showAnswer = true),
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

  Widget _buildCounter({
    required IconData icon,
    required Color color,
    required String label,
    required int value,
    required bool isCurrent,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: TextStyle(
            color: color,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: isCurrent ? 15 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton(String label, CardRating rating, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _answerCard(rating),
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
