import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

const _windowsStatsContentWidth = 480.0;
const _windowsScrollbarClearance = 24.0 + windowsScreenInset;

class StatsPage extends StatefulWidget {
  final String widgetKey;
  final QuoteStats stats;

  const StatsPage({super.key, required this.widgetKey, required this.stats});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final header = Text(
      "Solve Statistics - ${widget.widgetKey}",
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        shadows: [Shadow(color: AppTheme.logoGreen, blurRadius: 5)],
      ),
    );
    const footer = SubsectionTitle('Only 2-star solves and higher are counted');
    final scrollView = SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: insetPadding,
          horizontal:
              insetPadding + (isWindows ? _windowsScrollbarClearance : 0),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWindows
                  ? _windowsStatsContentWidth
                  : desktopContentWidth,
            ),
            child: Column(
              children: [
                if (!isWindows) ...[
                  header,
                  const SizedBox(height: padding + 10),
                ],
                StatBoxWidget(
                  title: "All Time",
                  num: "01",
                  neonColor: Colors.pinkAccent,
                  fastest: widget.stats.fastestSolveTimeAll.toStringAsFixed(2),
                  average: widget.stats.avgSolveTimeAll.toStringAsFixed(2),
                  solved: widget.stats.totalSolvedAll.toString(),
                ),
                const SizedBox(height: padding + 10),

                StatBoxWidget(
                  title: "This Week",
                  num: "02",
                  neonColor: Colors.yellowAccent,
                  fastest: widget.stats.fastestSolveTimeThisWeek
                      .toStringAsFixed(2),
                  average: widget.stats.avgSolveTimeThisWeek.toStringAsFixed(2),
                  solved: widget.stats.totalSolvedThisWeek.toString(),
                ),
                const SizedBox(height: padding + 10),

                StatBoxWidget(
                  title: "Last Week",
                  num: "03",
                  neonColor: Colors.lightBlueAccent,
                  fastest: widget.stats.fastestSolveTimeLastWeek
                      .toStringAsFixed(2),
                  average: widget.stats.avgSolveTimeLastWeek.toStringAsFixed(2),
                  solved: widget.stats.totalSolvedLastWeek.toString(),
                ),
                if (!isWindows) ...[
                  const SizedBox(height: padding + 10),
                  footer,
                  const SizedBox(height: padding + 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: AppTheme.appBarBackground,
        appBar: AppBar(backgroundColor: AppTheme.appBarBackground),
        body: isWindows
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: windowsScreenInset,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: insetPadding,
                        bottom: padding + 10,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: desktopContentWidth,
                          ),
                          child: header,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth:
                                _windowsStatsContentWidth +
                                2 * (insetPadding + _windowsScrollbarClearance),
                          ),
                          child: SizedBox(
                            height: double.infinity,
                            child: ScrollbarTheme(
                              data: const ScrollbarThemeData(
                                thumbColor: WidgetStatePropertyAll(
                                  AppTheme.logoGreen,
                                ),
                                trackColor: WidgetStatePropertyAll(
                                  Color(0xFF152A35),
                                ),
                                trackBorderColor: WidgetStatePropertyAll(
                                  Colors.white38,
                                ),
                                thickness: WidgetStatePropertyAll(6),
                                radius: Radius.circular(3),
                              ),
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                interactive: true,
                                child: scrollView,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: padding + 10,
                        bottom: insetPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: desktopContentWidth,
                          ),
                          child: footer,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : scrollView,
      ),
    );
  }
}
