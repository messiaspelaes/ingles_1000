import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Widget que processa e renderiza texto do Anki, incluindo tags de som [sound:...]
class AnkiContent extends StatefulWidget {
  final String content;
  final String deckId;
  final TextStyle? style;
  final TextAlign? textAlign;

  const AnkiContent({
    super.key,
    required this.content,
    required this.deckId,
    this.style,
    this.textAlign,
  });

  @override
  State<AnkiContent> createState() => _AnkiContentState();
}

class _AnkiContentState extends State<AnkiContent> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  
  // Pegar somente o nome do arquivo, removendo `[sound:` e `]`
  String? _extractSoundFile(String text) {
    final regex = RegExp(r'\[sound:(.*?)\]');
    final match = regex.firstMatch(text);
    return match?.group(1);
  }

  // Remove as tags [sound:...] do texto para mostrar só as palavras
  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\[sound:.*?\]'), '').trim();
  }

  Future<void> _playSound(String filename) async {
    if (_isPlaying) return;
    
    setState(() => _isPlaying = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      // O banco de dados do Media salva arquivos dentro da pasta do deck
      final String filePath = '${dir.path}/media/${widget.deckId}/$filename';
      
      if (File(filePath).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arquivo de áudio não encontrado offline')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao tocar áudio: \$e')),
        );
      }
    } finally {
      // Audioplayers no complete não reseta sozinho perfeitamente sem listener
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _isPlaying = false);
      });
      // Em caso de erro garantimos q volta ao play normal dps de um tempo (fallback)
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isPlaying) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanText = _cleanText(widget.content);
    final soundFile = _extractSoundFile(widget.content);

    return Column(
      children: [
        if (soundFile != null)
           IconButton(
             iconSize: 48,
             color: Colors.blue,
             icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_circle_fill),
             onPressed: () => _playSound(soundFile),
           ),
        
        if (cleanText.isNotEmpty)
          Text(
            cleanText,
            style: widget.style ?? const TextStyle(fontSize: 20),
            textAlign: widget.textAlign ?? TextAlign.center,
          ),
      ],
    );
  }
}
