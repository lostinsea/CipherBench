import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

class HomePage extends StatefulWidget {
  final AudioController? audioCont;
  const HomePage({super.key, this.audioCont});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    audioCont = widget.audioCont;
    audioCont?.playBgSound();
    bgMatrixOn = settingsBox?.get('prefs').bgMatrixOn;
  }

  @override
  Widget build(BuildContext context) {
    GameSetup.init(context);
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

    return Container(
      decoration: AppTheme.backgroundGradient,
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Stack(
        children: [
          const ConditionalBg(),
          Scaffold(
            backgroundColor: AppTheme.appBarBackground,
            appBar: AppBar(
              title: const Text(
                "SYSTEM",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: Border(
                bottom: BorderSide(color: AppTheme.logoGreen, width: 1),
              ),
              actions: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppTheme.logoGreen, width: 2),
                  ),
                  margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: IconButton(
                    iconSize: 18,
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Settings(audioCont: widget.audioCont),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: desktopContentWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            if (!isWindows) ...[
                              const HomeLogo(),
                              const SizedBox(height: 50),
                            ],
                            HomeButtonWidget(
                              btnText: "Aristocrat",
                              neonColor: Colors.pinkAccent,
                              num: "01",
                              onPressed: () async {
                                await buttonClickSound();
                                // Make sure context is still valid with mounted
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GamePageSetup(
                                      gameId: "Aristocrat",
                                      language: Language.english,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 25),
                            HomeButtonWidget(
                              btnText: "Patristocrat",
                              neonColor: Colors.yellowAccent,
                              num: "02",
                              onPressed: () async {
                                await buttonClickSound();
                                // Make sure context is still valid with mounted
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GamePageSetup(
                                      gameId: "Patristocrat",
                                      language: Language.english,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 25),
                            HomeButtonWidget(
                              btnText: "Xenocrypt",
                              neonColor: Colors.lightBlueAccent,
                              num: "03",
                              onPressed: () async {
                                await buttonClickSound();
                                // Make sure context is still valid with mounted
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GamePageSetup(
                                      gameId: "Xenocrypt",
                                      language: Language.spanish,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 25),
                            HomeButtonWidget(
                              btnText: "View Dictionary",
                              neonColor: AppTheme.logoGreen,
                              num: "04",
                              onPressed: () async {
                                await buttonClickSound();
                                // Make sure context is still valid with mounted
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DictionaryPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 25),
                            HomeButtonWidget(
                              btnText: "View Solved Puzzles",
                              neonColor: Colors.pinkAccent,
                              num: "05",
                              onPressed: () async {
                                await buttonClickSound();
                                // Make sure context is still valid with mounted
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuoteHomePage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (isWindows)
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: HomeLogo(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
