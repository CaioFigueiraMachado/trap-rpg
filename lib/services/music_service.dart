import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Toca as músicas dos trappers que estiverem em `lib/assets/music/<id>.mp3`.
///
/// O app descobre sozinho quais arquivos existem (AssetManifest), então
/// basta colocar o arquivo na pasta e reiniciar.
class MusicService extends ChangeNotifier {
  MusicService._() {
    // Por padrão o audioplayers procura em "assets/"; nossos arquivos estão em "lib/assets/".
    _player.audioCache = AudioCache(prefix: '');
    _player.onPlayerComplete.listen((_) {
      if (!_loop) {
        _playingId = null;
        notifyListeners();
      }
    });
  }
  static final instance = MusicService._();

  static const _folder = 'lib/assets/music/';
  static const _extensions = ['.mp3', '.m4a', '.ogg', '.wav'];

  final _player = AudioPlayer();
  Map<String, String>? _tracks; // cardId -> caminho do asset
  String? _playingId;
  bool _loop = false;
  bool muted = false;

  String? get playingId => _playingId;
  bool isPlaying(String cardId) => _playingId == cardId;

  /// Mapa cardId -> arquivo de música disponível.
  Future<Map<String, String>> tracks() async {
    final cached = _tracks;
    if (cached != null) return cached;
    final found = <String, String>{};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final path in manifest.listAssets()) {
        if (!path.startsWith(_folder)) continue;
        final file = path.substring(_folder.length);
        final ext = _extensions.where(file.toLowerCase().endsWith).firstOrNull;
        if (ext != null) found[file.substring(0, file.length - ext.length).toLowerCase()] = path;
      }
    } catch (e) {
      debugPrint('Não foi possível ler as músicas: $e');
    }
    return _tracks = found;
  }

  Future<bool> hasTrack(String cardId) async => (await tracks()).containsKey(cardId);

  /// Toca a música de uma carta. `loop` é usado na trilha da batalha.
  Future<bool> play(String cardId, {bool loop = false}) async {
    final path = (await tracks())[cardId];
    if (path == null) return false;
    _loop = loop;
    await _player.stop();
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await _player.play(AssetSource(path), volume: muted ? 0 : 0.8);
    _playingId = cardId;
    notifyListeners();
    return true;
  }

  Future<void> toggle(String cardId) async {
    if (isPlaying(cardId)) {
      await stop();
    } else {
      await play(cardId);
    }
  }

  /// Trilha da batalha: a primeira carta do time que tiver música.
  Future<String?> playBattleTheme(List<String> cardIds) async {
    final available = await tracks();
    for (final id in cardIds) {
      if (available.containsKey(id)) {
        await play(id, loop: true);
        return id;
      }
    }
    return null;
  }

  Future<void> setMuted(bool value) async {
    muted = value;
    await _player.setVolume(value ? 0 : 0.8);
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _playingId = null;
    notifyListeners();
  }
}
