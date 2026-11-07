import 'package:scioly_codebusters/library.dart';
import 'package:flutter/material.dart';

class QuoteHomePage extends StatelessWidget {
  const QuoteHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.backgroundGradient,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Quotes'),
            bottom: const TabBar(
              unselectedLabelColor: Colors.white,
              tabs: [
                Tab(text: 'All Quotes'),
                Tab(text: 'Favorites'),
              ],
            ),
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWindowsDesktop ? windowsScreenInset : 0,
            ),
            child: const TabBarView(children: [AllQuotesTab(), FavoritesTab()]),
          ),
          //floatingActionButton: const AddQuoteButton(),
        ),
      ),
    );
  }
}
