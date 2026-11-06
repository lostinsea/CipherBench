import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

class StatsPage extends StatelessWidget {
  final String widgetKey;
  final QuoteStats stats;

  const StatsPage({super.key, required this.widgetKey, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: AppTheme.appBarBackground,
        appBar: AppBar(backgroundColor: AppTheme.appBarBackground),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(insetPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: desktopContentWidth,
                ),
                child: Column(
                  children: [
                    Text(
                      "Solve Statistics - $widgetKey",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            shadows: [
                              Shadow(color: AppTheme.logoGreen, blurRadius: 5),
                            ],
                          ),
                    ),
                    const SizedBox(height: padding + 10),
                    StatBoxWidget(
                      title: "All Time",
                      num: "01",
                      neonColor: Colors.pinkAccent,
                      fastest: stats.fastestSolveTimeAll.toStringAsFixed(2),
                      average: stats.avgSolveTimeAll.toStringAsFixed(2),
                      solved: stats.totalSolvedAll.toString(),
                    ),
                    const SizedBox(height: padding + 10),

                    StatBoxWidget(
                      title: "This Week",
                      num: "02",
                      neonColor: Colors.yellowAccent,
                      fastest: stats.fastestSolveTimeThisWeek.toStringAsFixed(
                        2,
                      ),
                      average: stats.avgSolveTimeThisWeek.toStringAsFixed(2),
                      solved: stats.totalSolvedThisWeek.toString(),
                    ),
                    const SizedBox(height: padding + 10),

                    StatBoxWidget(
                      title: "Last Week",
                      num: "03",
                      neonColor: Colors.lightBlueAccent,
                      fastest: stats.fastestSolveTimeLastWeek.toStringAsFixed(
                        2,
                      ),
                      average: stats.avgSolveTimeLastWeek.toStringAsFixed(2),
                      solved: stats.totalSolvedLastWeek.toString(),
                    ),
                    const SizedBox(height: padding + 10),
                    SubsectionTitle(
                      'Only 2-star solves and higher are counted',
                    ),
                    const SizedBox(height: padding + 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
