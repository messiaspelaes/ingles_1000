import 'package:flutter/material.dart';

import '../../services/database_service.dart';
import 'association_field.dart';
import 'note_field.dart';

class CardFieldsSection extends StatelessWidget {
  final String cardId;
  final String phrase;
  final DatabaseService databaseService;

  const CardFieldsSection({
    super.key,
    required this.cardId,
    required this.phrase,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        AssociationField(
          cardId: cardId,
          phrase: phrase,
          databaseService: databaseService,
        ),
        const SizedBox(height: 16),
        NoteField(
          cardId: cardId,
          databaseService: databaseService,
        ),
      ],
    );
  }
}

