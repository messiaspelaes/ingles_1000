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
      final String mediaBaseDir = '${dir.path}/media';
      final String deckMediaDir = '$mediaBaseDir/${widget.deckId}';
      final String filePath = '$deckMediaDir/$filename';
      
      print('[AnkiContent] Tentando tocar: $filename');
      print('[AnkiContent] DeckId: ${widget.deckId}');
      print('[AnkiContent] Caminho completo: $filePath');
      
      final file = File(filePath);
      if (file.existsSync()) {
        print('[AnkiContent] Arquivo encontrado! Tamanho: ${file.lengthSync()} bytes');
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        print('[AnkiContent] ARQUIVO NÃO ENCONTRADO: $filePath');
        
        // Diagnóstico: listar diretórios disponíveis em media/
        final mediaDirObj = Directory(mediaBaseDir);
        if (mediaDirObj.existsSync()) {
          final dirs = mediaDirObj.listSync();
          print('[AnkiContent] Pastas em media/: ${dirs.map((d) => d.path.split('/').last).toList()}');
          
          // Verificar se o arquivo existe em alguma pasta de media
          for (final d in dirs) {
            if (d is Directory) {
              final checkFile = File('${d.path}/$filename');
              if (checkFile.existsSync()) {
                print('[AnkiContent] *** ENCONTRADO em ${d.path} ***');
                // Tocar do caminho correto
                await _audioPlayer.play(DeviceFileSource(checkFile.path));
                return;
              }
            }
          }
          print('[AnkiContent] Arquivo não encontrado em nenhuma pasta de media');
        } else {
          print('[AnkiContent] Diretório media/ NÃO EXISTE: $mediaBaseDir');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Áudio não encontrado: $filename')),
          );
        }
      }
    } catch (e) {
      print('[AnkiContent] Erro ao tocar áudio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao tocar áudio: $e')),
        );
      }
    } finally {
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _isPlaying = false);
      });
      Future.delayed(const Duration(seconds: 5), () {
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
