import 'package:flutter/material.dart';

import '../../services/database_service.dart';

class AssociationField extends StatefulWidget {
  final String cardId;
  final String phrase;
  final DatabaseService databaseService;

  const AssociationField({
    super.key,
    required this.cardId,
    required this.phrase,
    required this.databaseService,
  });

  @override
  State<AssociationField> createState() => _AssociationFieldState();
}

class _AssociationFieldState extends State<AssociationField> {
  bool _expanded = false;
  bool _loading = true;
  Map<String, String> _associations = {};
  String? _selectedWord;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAssociations();
  }

  @override
  void didUpdateWidget(covariant AssociationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardId != widget.cardId || oldWidget.phrase != widget.phrase) {
      _selectedWord = null;
      _controller.clear();
      _loadAssociations();
    }
  }

  Future<void> _loadAssociations() async {
    setState(() {
      _loading = true;
    });

    final data = await widget.databaseService.getAssociationsByCardId(widget.cardId);

    if (!mounted) return;
    setState(() {
      _associations = data;
      _loading = false;
      _expanded = _associations.isNotEmpty;
    });
  }

  List<String> _extractWords(String phrase) {
    var text = phrase;
    // Remover tags [sound:...]
    text = text.replaceAll(RegExp(r'\[sound:.*?\]'), ' ');
    // Remover HTML simples
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    // Normalizar espaços
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (text.isEmpty) return const [];
    return text.split(' ');
  }

  Future<void> _saveAssociation(String word, String text) async {
    await widget.databaseService.saveAssociation(widget.cardId, word, text);
    if (!mounted) return;
    setState(() {
      if (text.trim().isEmpty) {
        _associations.remove(word);
      } else {
        _associations[word] = text;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = _extractWords(widget.phrase);
    if (words.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Associação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: words.map((word) {
                          final hasAssociation = _associations[word]?.trim().isNotEmpty == true;
                          final isSelected = word == _selectedWord;
                          return FilterChip(
                            label: Text(word),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                if (_selectedWord == word) {
                                  _selectedWord = null;
                                  _controller.clear();
                                } else {
                                  _selectedWord = word;
                                  _controller.text = _associations[word] ?? '';
                                }
                              });
                            },
                            selectedColor: Colors.blue[100],
                            checkmarkColor: Colors.blue[900],
                            labelStyle: TextStyle(
                              color: hasAssociation ? Colors.blue[900] : null,
                              fontWeight: hasAssociation ? FontWeight.w600 : FontWeight.normal,
                            ),
                            backgroundColor: hasAssociation ? Colors.blue[50] : null,
                          );
                        }).toList(),
                      ),
                      if (_selectedWord != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Associação para "${''}"'.replaceFirst('""', '"${_selectedWord!}"'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _controller,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Escreva a associação que faz sentido para você...',
                          ),
                          onEditingComplete: () async {
                            final word = _selectedWord;
                            if (word != null) {
                              final text = _controller.text;
                              await _saveAssociation(word, text);
                            }
                            FocusScope.of(context).unfocus();
                          },
                          onSubmitted: (_) async {
                            final word = _selectedWord;
                            if (word != null) {
                              final text = _controller.text;
                              await _saveAssociation(word, text);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
          ),
      ],
    );
  }
}

