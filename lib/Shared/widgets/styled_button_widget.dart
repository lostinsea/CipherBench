import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class StyledButtonWidget extends ConsumerStatefulWidget {
  final String value;
  final String? fittedLabel;
  final Icon? valueIcon;
  final Color txtColor;
  final Color bgColor;
  final double endAlpha;
  final double marginHorizontal;
  final double marginVertical;
  final double paddingHorizontal;
  final double paddingVertical;
  final Function onPressed;
  final double height;
  final bool addTextShadow;
  final int animDuration;

  const StyledButtonWidget({
    super.key,

    this.value = "",
    this.fittedLabel,
    this.valueIcon,
    this.onPressed = _defaultOnPressed,
    this.endAlpha = 75,
    this.marginHorizontal = 0,
    this.marginVertical = 0,
    this.paddingHorizontal = 5.0,
    this.paddingVertical = 5.0,
    this.txtColor = Colors.white,
    this.bgColor = AppTheme.logoGreen,
    this.height = -1,
    this.addTextShadow = false,
    this.animDuration = 200,
  });

  @override
  ConsumerState<StyledButtonWidget> createState() => _StyledButtonWidgetState();

  static void _defaultOnPressed() {
    return;
  }
}

class _StyledButtonWidgetState extends ConsumerState<StyledButtonWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _alphaAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: widget.animDuration),
      vsync: this,
    );
    _alphaAnimation = Tween(begin: 50.0, end: widget.endAlpha).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    _animationController.forward();
    widget.onPressed();
    Future.delayed(Duration(milliseconds: widget.animDuration), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = Text(
      widget.fittedLabel ?? widget.value,
      style: TextStyle(
        color: widget.txtColor,
        fontSize: 15,
        shadows: widget.addTextShadow
            ? [Shadow(color: widget.bgColor, blurRadius: 10)]
            : [],
      ),
      textAlign: TextAlign.center,
      maxLines: widget.fittedLabel == null ? null : 2,
      softWrap: widget.fittedLabel == null,
      semanticsLabel: widget.fittedLabel == null ? null : widget.value,
    );
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(
            vertical: widget.marginVertical,
            horizontal: widget.marginHorizontal,
          ),
          child: InkWell(
            onTap: _onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: widget.paddingVertical,
                horizontal: widget.paddingHorizontal,
              ),
              height: widget.height != -1 ? widget.height : null,
              decoration: BoxDecoration(
                color: widget.bgColor.withAlpha(
                  (_alphaAnimation.value).toInt(),
                ),
                border: Border.all(color: widget.bgColor, width: 1),
              ),
              child: Center(
                child:
                    widget.valueIcon ??
                    (widget.fittedLabel == null
                        ? label
                        : FittedBox(fit: BoxFit.scaleDown, child: label)),
              ),
            ),
          ),
        );
      },
    );
  }
}
