import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static bool sfxOn = true;
  static bool bgmOn = true;
  static bool _isBgmPlaying = false;

  static late AudioPool _clickPool;
  static late AudioPool _explosionPool;
  static late AudioPool _splashPool;

  static late AudioPool _startPool;
  static late AudioPool _powerUpPool;
  static late AudioPool _monsterPool;
  static late AudioPool _sinkPool;
  static late AudioPool _winPool;
  static late AudioPool _losePool;

  static Future<void> init() async {
    await FlameAudio.audioCache.load('bgm.mp3');

    try {
      _clickPool = await FlameAudio.createPool('click.wav', minPlayers: 1, maxPlayers: 3);
      _explosionPool = await FlameAudio.createPool('explosion.wav', minPlayers: 1, maxPlayers: 3);
      _splashPool = await FlameAudio.createPool('splash.wav', minPlayers: 1, maxPlayers: 3);

      _startPool = await FlameAudio.createPool('start.wav', minPlayers: 1, maxPlayers: 1);
      _powerUpPool = await FlameAudio.createPool('powerup.wav', minPlayers: 1, maxPlayers: 2);
      _monsterPool = await FlameAudio.createPool('monster.wav', minPlayers: 1, maxPlayers: 2);
      _sinkPool = await FlameAudio.createPool('sink.wav', minPlayers: 1, maxPlayers: 2);

      _winPool = await FlameAudio.createPool('win.wav', minPlayers: 1, maxPlayers: 1);
      _losePool = await FlameAudio.createPool('lose.wav', minPlayers: 1, maxPlayers: 1);

    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  static Future<void> playBgm() async {
    if (bgmOn && !_isBgmPlaying) {
      try {
        await FlameAudio.bgm.play('bgm.mp3', volume: 0.25);
        _isBgmPlaying = true;
      } catch (e) {
        debugPrint("BGM play error: $e");
      }
    }
  }

  static void stopBgm() {
    FlameAudio.bgm.stop();
    _isBgmPlaying = false;
  }

  static void pauseBgm() {
    if (_isBgmPlaying) FlameAudio.bgm.pause();
  }

  static void resumeBgm() {
    if (bgmOn && _isBgmPlaying) FlameAudio.bgm.resume();
  }

  static void toggleSound() {
    bool newState = !sfxOn;
    sfxOn = newState;
    bgmOn = newState;

    if (newState) {
      playClick();
      playBgm();
    } else {
      stopBgm();
    }
  }

  static void playClick() {
    if (sfxOn) _clickPool.start(volume: 1.0);
  }

  static void playExplosion() {
    if (sfxOn) _explosionPool.start(volume: 0.8);
  }

  static void playSplash() {
    if (sfxOn) _splashPool.start(volume: 0.6);
  }

  static void playStart() {
    if (sfxOn) _startPool.start(volume: 1.0);
  }

  static void playPowerUp() {
    if (sfxOn) _powerUpPool.start(volume: 0.6);
  }

  static void playMonster() {
    if (sfxOn) _monsterPool.start(volume: 0.8);
  }

  static void playSink() {
    if (sfxOn) _sinkPool.start(volume: 1.0);
  }

  static void playWin() {
    if (sfxOn) {
      stopBgm();
      _winPool.start(volume: 1.0);
    }
  }

  static void playLoss() {
    if (sfxOn) {
      stopBgm();
      _losePool.start(volume: 1.0);
    }
  }
}