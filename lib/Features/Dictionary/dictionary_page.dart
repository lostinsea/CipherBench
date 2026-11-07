import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DictionaryPage extends ConsumerWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tabs = TabBar(
      unselectedLabelColor: Colors.white,
      tabs: [
        Tab(text: 'English'),
        Tab(text: 'Spanish'),
      ],
    );
    final colors = [
      AppTheme.logoGreen,
      Colors.yellowAccent,
      Colors.blueAccent,
      Colors.redAccent,
    ];

    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: AppTheme.backgroundGradient,
        child: Scaffold(
          backgroundColor: AppTheme.appBarBackground,
          appBar: AppBar(
            title: isWindowsDesktop
                ? const Row(
                    children: [
                      Text('Pattern Dictionary'),
                      SizedBox(width: 24),
                      Expanded(child: tabs),
                    ],
                  )
                : const Text('Pattern Dictionary'),
            backgroundColor: AppTheme.appBarBackground,
            bottom: isWindowsDesktop ? null : tabs,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWindowsDesktop ? windowsScreenInset : 0,
            ),
            child: TabBarView(
              children: [
                DictionaryTab(dictionaryId: "english", colors: colors),
                DictionaryTab(dictionaryId: "spanish", colors: colors),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
