import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    curSliderVal = settingsBox?.get('prefs').bgVolume;
  }

  @override
  Widget build(BuildContext context) {
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
        body: Container(
          padding: EdgeInsets.all(insetPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: desktopContentWidth),
              child: Column(
                children: [
                  HeadingWidget(
                    neonColor: AppTheme.logoGreen,
                    title: "Background Music",
                    numIcon: Icon(Icons.music_note, color: Colors.black),
                  ),
                  Slider(
                    value: curSliderVal,
                    thumbColor: widget.audioCont?.isBgPlaying() ?? false
                        ? AppTheme.logoGreen
                        : Colors.grey,
                    activeColor: widget.audioCont?.isBgPlaying() ?? false
                        ? AppTheme.logoGreen
                        : Colors.grey,
                    onChanged: (value) async {
                      if (widget.audioCont?.isBgPlaying() ?? false) {
                        await settingsBox?.put(
                          'prefs',
                          settingsBox?.get('prefs').copyWith(bgVolume: value),
                        );
                        widget.audioCont?.setBgVolume(value);
                        setState(() {
                          curSliderVal = value;
                        });
                      }
                    },
                  ),
                  StyledButtonWidget(
                    value: widget.audioCont?.isBgPlaying() ?? false
                        ? "Turn off Background Music"
                        : "Turn On Background Music",
                    onPressed: () async {
                      widget.audioCont?.toggleBgSound();
                      setState(() {});
                    },
                    bgColor: widget.audioCont?.isBgPlaying() ?? false
                        ? AppTheme.logoGreen
                        : Colors.redAccent,
                    paddingVertical: 10,
                  ),

                  // Bg Matrix Effect
                  SizedBox(height: 30),
                  HeadingWidget(
                    neonColor: Colors.yellowAccent,
                    title: "Matrix Effect",
                    numIcon: Icon(Icons.compare_outlined, color: Colors.black),
                  ),
                  StyledButtonWidget(
                    value: bgMatrixOn
                        ? "Turn off Background Effect"
                        : "Turn on Background Effect",
                    paddingVertical: 10,
                    marginVertical: 20,
                    bgColor: bgMatrixOn ? AppTheme.logoGreen : Colors.redAccent,
                    onPressed: () async {
                      await settingsBox?.put(
                        "prefs",
                        settingsBox
                            ?.get("prefs")
                            .copyWith(bgMatrixOn: !bgMatrixOn),
                      );
                      setState(() {
                        bgMatrixOn = !bgMatrixOn;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
