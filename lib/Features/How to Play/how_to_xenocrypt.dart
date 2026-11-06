import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

class XenocryptInstructionsPage extends StatelessWidget {
  const XenocryptInstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = Colors.lightGreenAccent.shade400;

    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'How to Play: Xenocrypts',
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: desktopContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle('What is a Xenocrypt?'),
                  Paragraph(
                    'A Xenocrypt is a cryptogram puzzle where the encrypted message is in another language — most commonly Spanish.',
                  ),
                  Paragraph(
                    'You solve it the same way you would an Aristocrat: by figuring out which letter stands for which. But the final answer is in Spanish instead of English.',
                  ),
                  ExampleBlock(
                    ciphertext: 'ZBP XRM LZQ BXP OZXA',
                    solution: 'LAS DOS HAN LOS HECHOS',
                  ),
                  SectionTitle('Tips to Solve'),
                  BulletPoints([
                    'Learn basic Spanish words: “el”, “la”, “de”, “que”, “por”, etc.',
                    'Look for common patterns like repeating letters or articles.',
                    'Use letter frequencies — Spanish has common letters too (E, A, O, L).',
                    'Use the dictionary tool to get Spanish word suggestions by pattern.',
                  ]),
                  SectionTitle('Additional notes'),
                  BulletPoints([
                    'll is considered two letters',
                    'Ñ is its own letter, but accented letters are not treated as seperate letters',
                  ]),
                  Container(
                    padding: EdgeInsets.all(insetPadding),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(50),
                      border: Border.all(color: Colors.blueAccent, width: 1),
                    ),
                    child: Icon(
                      Icons.menu_book_sharp,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SectionTitle('Good News'),
                  Paragraph(
                    'You don’t need to be fluent in Spanish to solve a Xenocrypt. Pattern recognition, logic, and a little trial and error go a long way.',
                  ),
                  SectionTitle('Need Help?'),
                  BulletPoints([
                    '✅ Show Correct — Highlights which letters are correct.',
                    '📖 Dictionary — Suggests words for a selected pattern.',
                    '💬 Hint — Reveals the correct letter at a selected spot.',
                  ]),
                  SectionTitle('Game Modes'),
                  BulletPoints([
                    'Assisted — Fills in identical letters automatically',
                    'Manual — Fill every letter manually, good for paper competition practice',
                  ]),
                  SectionTitle('Star Solves'),
                  BulletPoints([
                    '⭐ One stars: Solve with any hints (dictionary, show correct, or hint button).',
                    '⭐⭐ Two stars: Solve with no hints.',
                    '⭐⭐⭐ Three stars: Solve with no hints and no undo/delete.',
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
