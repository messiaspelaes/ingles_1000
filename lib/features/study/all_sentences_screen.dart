import 'package:flutter/material.dart' hide Card;

import '../../models/card.dart';
import '../../models/note.dart';
import '../../services/database_service.dart';
import '../../core/widgets/anki_content.dart';
import 'card_fields_section.dart';

class AllSentencesScreen extends StatefulWidget {
  const AllSentencesScreen({super.key});

  @override
  State<AllSentencesScreen> createState() => _AllSentencesScreenState();
}

class _AllSentencesScreenState extends State<AllSentencesScreen> {
  final DatabaseService _databaseService = DatabaseService();

  static const int _pageSize = 10;

  int _currentPageIndex = 0;
  int _totalCards = 0;
  bool _isLoading = true;
  List<Card> _cards = [];
  final Map<String, Note> _notesById = {};

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);

    try {
      final total = await _databaseService.getTotalCardsCount();
      _totalCards = total;
      if (_totalCards == 0) {
        _cards = [];
      } else {
        await _loadPage(0);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _pageCount {
    if (_totalCards == 0) return 0;
    return (_totalCards / _pageSize).ceil();
  }

  Future<void> _loadPage(int pageIndex) async {
    if (_totalCards == 0) {
      setState(() {
        _cards = [];
        _currentPageIndex = 0;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final offset = pageIndex * _pageSize;
      final cards = await _databaseService.getAllCardsOrdered(
        limit: _pageSize,
        offset: offset,
      );

      final notes = <Note>[];
      for (final card in cards) {
        final existing = _notesById[card.noteId];
        if (existing != null) {
          notes.add(existing);
        } else {
          final note = await _databaseService.getNoteById(card.noteId);
          if (note != null) {
            _notesById[note.id] = note;
            notes.add(note);
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _currentPageIndex = pageIndex;
        _cards = cards;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = _pageCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de todas as frases'),
      ),
      body: _isLoading && _totalCards == 0
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (pageCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bloco ${_currentPageIndex + 1} de $pageCount',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _currentPageIndex > 0 && !_isLoading
                                  ? () => _loadPage(_currentPageIndex - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            IconButton(
                              onPressed: (_currentPageIndex < pageCount - 1) &&
                                      !_isLoading
                                  ? () => _loadPage(_currentPageIndex + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: _totalCards == 0
                      ? const Center(
                          child: Text(
                            'Nenhuma frase encontrada.',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _cards.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final card = _cards[index];
                                final note = _notesById[card.noteId];
                                if (note == null) {
                                  return const SizedBox.shrink();
                                }
                                final globalIndex =
                                    _currentPageIndex * _pageSize + index + 1;
                                return _SentenceItem(
                                  index: globalIndex,
                                  card: card,
                                  note: note,
                                  databaseService: _databaseService,
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}

class _SentenceItem extends StatelessWidget {
  final int index;
  final Card card;
  final Note note;
  final DatabaseService databaseService;

  const _SentenceItem({
    required this.index,
    required this.card,
    required this.note,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '#$index',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            AnkiContent(
              content: note.frontField,
              deckId: card.deckId,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              autoPlay: false,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnkiContent(
                content: note.backField,
                deckId: card.deckId,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                autoPlay: false,
              ),
            ),
            const SizedBox(height: 12),
            CardFieldsSection(
              cardId: card.id,
              phrase: note.frontField,
              databaseService: databaseService,
            ),
          ],
        ),
      ),
    );
  }
}

