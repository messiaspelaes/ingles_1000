import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'features/study/study_screen.dart';
import 'features/study/all_sentences_screen.dart';
import 'features/progress/progress_screen.dart';
import 'core/license/about_screen.dart';
import 'services/database_service.dart';
import 'services/apkg_service.dart';
import 'models/note.dart';
import 'models/card.dart' as app_card;
import 'utils/date_utils.dart' as app_date_utils;
import 'utils/app_logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ApkgService _apkgService = ApkgService();
  bool _isAutoImporting = false;

  @override
  void initState() {
    super.initState();
    _checkAndAutoImport();
  }

  Future<void> _checkAndAutoImport() async {
    final count = await _databaseService.countDecks();
    if (count == 0) {
      setState(() => _isAutoImporting = true);
      try {
        await _importDefaultDeck();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao importar deck padrão: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isAutoImporting = false);
      }
    }
  }

  Future<void> _importDefaultDeck() async {
    const assetPath = 'assets/decks/ingles_1000.apkg';

    // 1. Importar dos assets
    final importResult = await _apkgService.importApkgFromAsset(assetPath);

    // 2. Criar deck
    const deckName = '1000 Frases mais comuns em Inglês';
    final deckId = await _databaseService.createDeck(deckName);

    // 3. Salvar notas
    final noteMap = <int, String>{};
    int noteCounter = 0;
    for (final ankiNote in importResult.notes) {
      final noteId =
          '${DateTime.now().millisecondsSinceEpoch}_${noteCounter++}';
      noteMap[ankiNote.id] = noteId;

      final note = Note(
        id: noteId,
        deckId: deckId,
        userId: '',
        fields: ankiNote.fields,
        tags: ankiNote.tags,
        modelName: 'Basic',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ankiGuid: ankiNote.guid,
        ankiNoteId: ankiNote.id,
      );
      await _databaseService.saveNote(note);
    }

    // 4. Salvar cards
    int cardCounter = 0;
    for (final ankiCard in importResult.cards) {
      if (!noteMap.containsKey(ankiCard.noteId)) continue;

      final cardId =
          '${DateTime.now().millisecondsSinceEpoch}_${cardCounter++}';
      final noteId = noteMap[ankiCard.noteId]!;

      app_card.CardQueueType queueType;
      if (ankiCard.queue == 0) {
        queueType = app_card.CardQueueType.newCard;
      } else if (ankiCard.queue == 1 || ankiCard.queue == 3) {
        queueType = app_card.CardQueueType.learning;
      } else if (ankiCard.queue == 2) {
        queueType = app_card.CardQueueType.review;
      } else {
        queueType = app_card.CardQueueType.newCard;
      }

      final dueDate = app_date_utils.DateUtils.ankiTimestampToDateTime(
        ankiCard.due,
      );

      final card = app_card.Card(
        id: cardId,
        noteId: noteId,
        deckId: deckId,
        userId: '',
        queueType: queueType,
        fsrsDifficulty: 0.3,
        fsrsStability:
            ankiCard.interval > 0 ? ankiCard.interval.toDouble() : 0.0,
        fsrsRetrievability: 1.0,
        dueDate: dueDate,
        intervalDays: ankiCard.interval,
        easeFactor: ankiCard.easeFactor,
        reviewsCount: ankiCard.reviewsCount,
        lapsesCount: ankiCard.lapsesCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ankiCardId: ankiCard.id,
        ankiDue: ankiCard.due,
      );
      await _databaseService.saveCard(card);
    }

    // 5. Salvar mídias
    if (importResult.mediaFiles.isNotEmpty) {
      AppLogger.i(LogCategory.general, 'Salvando ${importResult.mediaFiles.length} arquivos de mídia para deck $deckId');
      final dir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${dir.path}/media/$deckId');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      AppLogger.i(LogCategory.general, 'Diretório de mídia: ${mediaDir.path}');
      int saved = 0;
      for (final entry in importResult.mediaFiles.entries) {
        final mediaFile = File('${mediaDir.path}/${entry.key}');
        await mediaFile.writeAsBytes(entry.value);
        saved++;
      }
      AppLogger.s(LogCategory.general, '$saved arquivos de mídia salvos com sucesso');
    } else {
      AppLogger.w(LogCategory.general, 'ATENÇÃO: importResult.mediaFiles está VAZIO!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho
                  const SizedBox(height: 40),
                  // Usar um ícone se o logo.svg não existir, ou envolver em try-catch
                  Icon(Icons.language, size: 80, color: Colors.blue[600]),
                  const SizedBox(height: 20),
                  const Text(
                    'Aprenda as 1000 frases\nmais usadas em inglês',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  // Botão de estudo
                  _buildOptionCard(
                    context,
                    icon: Icons.school,
                    title: "Começar a Estudar",
                    subtitle: "Pratique com as frases essenciais",
                    color: Colors.blue[400]!,
                    onTap: () {
                      // Navegar para tela de estudo
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudyScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Botão de progresso
                  _buildOptionCard(
                    context,
                    icon: Icons.assessment,
                    title: "Meu Progresso",
                    subtitle: "Veja seu gráfico de memorização",
                    color: Colors.green[400]!,
                    onTap: () {
                      // Navegar para tela de gráfico
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Lista de todas as frases
                  _buildOptionCard(
                    context,
                    icon: Icons.list,
                    title: "Lista de todas as frases",
                    subtitle: "Navegue por todas as frases",
                    color: Colors.orange[400]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllSentencesScreen(),
                        ),
                      );
                    },
                  ),

                  // Rodapé
                  const Spacer(),
                  const Text(
                    "Baseado no algoritmo FSRS de repetição espaçada",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sobre / Licenças',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (_isAutoImporting)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Configurando seu deck de inglês...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
