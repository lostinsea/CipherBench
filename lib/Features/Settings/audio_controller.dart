import 'dart:async';

import 'package:logging/logging.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:scioly_codebusters/library.dart';

class AudioController {
  static final Logger _log = Logger('AudioController');

  SoLoud? _soloud;

  SoundHandle? _bgHandle;
  bool bgPlaying = true;
  double initVol = 1;

  Future<void> initialize() async {
    _soloud = SoLoud.instance;
    await _soloud!.init();
    bgPlaying = settingsBox?.get('prefs').isBgMusicOn;
    initVol = settingsBox?.get('prefs').bgVolume;
  }

  void dispose() {
    _soloud?.deinit();
  }

  Future<void> playSound(String assetKey) async {
    final source = await _soloud!.loadAsset(assetKey);
    await _soloud!.play(source);
  }

  Future<void> playBgSound() async {
    if (_bgHandle == null) {
      final source = await _soloud!.loadAsset(bgMusicFile);
      _bgHandle = await _soloud!.play(source, looping: true);
      setBgVolume(initVol);
      if (!bgPlaying) {
        toggleBgSound(updateState: false);
      }
    }
  }

  void toggleBgSound({bool updateState = true}) async {
    if (_bgHandle != null) {
      _soloud!.pauseSwitch(_bgHandle!);
      if (updateState) {
        bgPlaying = !bgPlaying;
        await updateSettingBox();
      }
    }
  }

  Future<void> updateSettingBox() async {
    await settingsBox?.put(
      "prefs",
      settingsBox?.get('prefs').copyWith(isBgMusicOn: bgPlaying),
    );
  }

  void setBgVolume(double vol) {
    if (_bgHandle != null) {
      _soloud!.setVolume(_bgHandle!, vol);
    }
  }

  bool isBgPlaying() {
    return bgPlaying;
  }

  Future<void> startMusic() async {
    _log.warning('Not implemented yet.');
  }
}
