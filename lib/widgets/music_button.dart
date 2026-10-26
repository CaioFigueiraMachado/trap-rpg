import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/trapper_card.dart';
import '../services/music_service.dart';

/// Botões de música de um trapper: tocar o arquivo local (se existir)
/// e abrir o artista no Spotify.
class MusicButtons extends StatelessWidget {
  const MusicButtons({super.key, required this.card});
  final TrapperCard card;

  Future<void> _openSpotify(BuildContext context) async {
    final ok = await launchUrl(card.spotifyUrl, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Spotify.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final music = MusicService.instance;
    return FutureBuilder<bool>(
      future: music.hasTrack(card.id),
      builder: (context, snapshot) {
        final hasTrack = snapshot.data ?? false;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (hasTrack)
              ListenableBuilder(
                listenable: music,
                builder: (context, _) {
                  final playing = music.isPlaying(card.id);
                  return FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      backgroundColor: playing ? AppColors.danger : AppColors.accent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => music.toggle(card.id),
                    icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(playing ? 'Parar música' : 'Tocar música'),
                  );
                },
              ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 46),
                foregroundColor: const Color(0xFF1DB954),
                side: const BorderSide(color: Color(0xFF1DB954)),
              ),
              onPressed: () => _openSpotify(context),
              icon: const Icon(Icons.headphones),
              label: const Text('Ouvir no Spotify'),
            ),
          ],
        );
      },
    );
  }
}
