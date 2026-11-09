import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/Features/Settings/Models/setting_prefs.dart';
import 'package:scioly_codebusters/library.dart';

class Settings extends ConsumerStatefulWidget {
  final AudioController? audioCont;
  const Settings({super.key, this.audioCont});

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  double curSliderVal = 1;

  @override
  void initState() {
    super.initState();
    curSliderVal = settingsStore?.prefs.bgVolume ?? 1;
  }

  Future<void> _savePrefs(SettingPrefs Function(SettingPrefs) update) async {
    final store = settingsStore;
    if (store == null) throw StateError('Settings have not been initialized.');
    await store.save(update(store.prefs));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final prefs = settingsStore?.prefs;
    final musicOn = widget.audioCont?.isBgPlaying() ?? false;
    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "Settings",
            style: TextStyle(
              shadows: [Shadow(color: AppTheme.logoGreen, blurRadius: 5)],
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(insetPadding),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const HeadingWidget(
                    neonColor: AppTheme.logoGreen,
                    title: 'Background Music',
                    numIcon: Icon(Icons.music_note, color: Colors.black),
                    showUnderline: false,
                  ),
                  value: musicOn,
                  onChanged: widget.audioCont == null
                      ? null
                      : (_) {
                          widget.audioCont!.toggleBgSound();
                          setState(() {});
                        },
                ),
                Slider(
                  value: curSliderVal,
                  thumbColor: musicOn ? AppTheme.logoGreen : Colors.grey,
                  activeColor: musicOn ? AppTheme.logoGreen : Colors.grey,
                  onChanged: (value) async {
                    if (widget.audioCont?.isBgPlaying() ?? false) {
                      curSliderVal = value;
                      await _savePrefs(
                        (prefs) => prefs.copyWith(bgVolume: value),
                      );
                      widget.audioCont?.setBgVolume(value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const HeadingWidget(
                    neonColor: Colors.yellowAccent,
                    title: 'Matrix Effect',
                    numIcon: Icon(Icons.compare_outlined, color: Colors.black),
                    showUnderline: false,
                  ),
                  value: prefs?.bgMatrixOn ?? bgMatrixOn,
                  onChanged: (value) async {
                    await _savePrefs(
                      (current) => current.copyWith(bgMatrixOn: value),
                    );
                    bgMatrixOn = value;
                  },
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const HeadingWidget(
                    neonColor: AppTheme.logoGreen,
                    title: 'Use extended quote collection',
                    numIcon: Icon(
                      Icons.library_books_outlined,
                      color: Colors.black,
                    ),
                    showUnderline: false,
                  ),
                  subtitle: const Text(
                    'Include additional imported quotes in new puzzles.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: prefs?.useExtendedQuoteCollection ?? true,
                  onChanged: (value) async {
                    await _savePrefs(
                      (current) =>
                          current.copyWith(useExtendedQuoteCollection: value),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const HeadingWidget(
                    neonColor: AppTheme.logoGreen,
                    title: 'Skip completed quotes',
                    numIcon: Icon(
                      Icons.check_circle_outline,
                      color: Colors.black,
                    ),
                    showUnderline: false,
                  ),
                  subtitle: const Text(
                    'New puzzles use quotes you have not solved yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: prefs?.skipCompletedQuotes ?? true,
                  onChanged: (value) async {
                    await _savePrefs(
                      (current) => current.copyWith(skipCompletedQuotes: value),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const HeadingWidget(
                    neonColor: AppTheme.logoGreen,
                    title: 'Frequency based word list order',
                    numIcon: Icon(Icons.sort, color: Colors.black),
                    showUnderline: false,
                  ),
                  subtitle: const Text(
                    'Show common English puzzle suggestions first; the main Dictionary is unchanged.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: prefs?.frequencyWordOrder ?? true,
                  onChanged: (value) async {
                    await _savePrefs(
                      (current) => current.copyWith(frequencyWordOrder: value),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
