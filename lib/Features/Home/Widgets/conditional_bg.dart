import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

class ConditionalBg extends StatefulWidget {
  const ConditionalBg({super.key});

  @override
  State<ConditionalBg> createState() => _ConditionalBgState();
}

class _ConditionalBgState extends State<ConditionalBg> with RouteAware {
  bool _show = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    setState(() => _show = true);
  }

  @override
  void didPopNext() {
    setState(() => _show = true);
  }

  @override
  void didPushNext() {
    setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: settingsStore!,
      builder: (context, prefs, _) {
        if (prefs.bgMatrixOn && _show) {
          return MatrixBackgroundWidget();
        }
        return SizedBox.shrink();
      },
    );
  }
}
