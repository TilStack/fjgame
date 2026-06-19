// Service de sons singleton. Joue les MP3 depuis assets/sounds/.
// Silencieux si le fichier est absent ou si enabled == false.

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  bool get enabled => _enabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('sound_enabled') ?? true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  Future<void> _play(String file) async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/$file'));
    } catch (_) {}
  }

  Future<void> playCardFlip() => _play('card_flip.mp3');
  Future<void> playCardDeal() => _play('card_deal.mp3');
  Future<void> playSuccess() => _play('success.mp3');
  Future<void> playFail() => _play('fail.mp3');
  Future<void> playFamilyComplete() => _play('family_complete.mp3');
  Future<void> playGameWin() => _play('game_win.mp3');
  Future<void> playButtonTap() => _play('button_tap.mp3');
}
