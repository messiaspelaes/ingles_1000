import 'package:flutter/material.dart';

import '../../services/database_service.dart';

class NoteField extends StatefulWidget {
  final String cardId;
  final DatabaseService databaseService;

  const NoteField({
    super.key,
    required this.cardId,
    required this.databaseService,
  });

  @override
  State<NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<NoteField> {
  bool _expanded = false;
  bool _loading = true;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadNote();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveNote();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardId != widget.cardId) {
      _controller.clear();
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    setState(() {
      _loading = true;
    });

    final note = await widget.databaseService.getCardNote(widget.cardId);

    if (!mounted) return;
    setState(() {
      _controller.text = note ?? '';
      _loading = false;
      _expanded = (note != null && note.trim().isNotEmpty);
    });
  }

  Future<void> _saveNote() async {
    await widget.databaseService.saveCardNote(widget.cardId, _controller.text);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'Anotação',
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
                : TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Escreva suas observações sobre este card...',
                    ),
                    onEditingComplete: () async {
                      await _saveNote();
                      FocusScope.of(context).unfocus();
                    },
                  ),
          ),
      ],
    );
  }
}

