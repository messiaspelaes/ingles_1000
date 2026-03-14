import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../utils/app_logger.dart';

/// Widget que processa e renderiza texto do Anki, incluindo tags de som [sound:...]
class AnkiContent extends StatefulWidget {
  final String content;
  final String deckId;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool autoPlay;

  const AnkiContent({
    super.key,
    required this.content,
    required this.deckId,
    this.style,
    this.textAlign,
    this.autoPlay = false,
  });

  @override
  State<AnkiContent> createState() => _AnkiContentState();
}

class _AnkiContentState extends State<AnkiContent> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final soundFile = _extractSoundFile(widget.content);
        if (soundFile != null) {
          _playSound(soundFile);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnkiContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tocar se o conteúdo mudou ou se o autoPlay foi ativado e o card é o mesmo
    if (widget.autoPlay && (oldWidget.content != widget.content || (!oldWidget.autoPlay && widget.autoPlay))) {
      final soundFile = _extractSoundFile(widget.content);
      if (soundFile != null) {
        _playSound(soundFile);
      }
    }
  }

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
      
      AppLogger.i(LogCategory.audio, 'Tentando tocar: $filename | DeckId: ${widget.deckId}');
      
      final file = File(filePath);
      if (file.existsSync()) {
        AppLogger.s(LogCategory.audio, 'Arquivo encontrado! Tamanho: ${file.lengthSync()} bytes');
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        AppLogger.w(LogCategory.audio, 'Arquivo não encontrado no path principal: $filePath');
        
        // Diagnóstico: listar diretórios disponíveis em media/
        final mediaDirObj = Directory(mediaBaseDir);
        if (mediaDirObj.existsSync()) {
          final dirs = mediaDirObj.listSync();
          // AppLogger.i(LogCategory.audio, 'Pastas em media/: ${dirs.map((d) => d.path.split('/').last).toList()}');
          
          // Verificar se o arquivo existe em alguma pasta de media
          for (final d in dirs) {
            if (d is Directory) {
              final checkFile = File('${d.path}/$filename');
              if (checkFile.existsSync()) {
                AppLogger.s(LogCategory.audio, 'Arquivo encontrado no fallback: ${d.path}');
                // Tocar do caminho correto
                await _audioPlayer.play(DeviceFileSource(checkFile.path));
                return;
              }
            }
          }
          AppLogger.e(LogCategory.audio, 'Arquivo definitivo não encontrado em nenhuma pasta', filename);
        } else {
          AppLogger.e(LogCategory.audio, 'Diretório media/ não existe', mediaBaseDir);
        }
        
        if (mounted) {
          setState(() => _isPlaying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Áudio não encontrado: $filename')),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.e(LogCategory.audio, 'Erro geral no player de áudio', e, stack);
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao tocar áudio: $e')),
        );
      }
    } finally {
      // O listener de finalização já está configurado no initState
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
