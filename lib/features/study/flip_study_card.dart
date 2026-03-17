import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlipStudyCard extends StatelessWidget {
  const FlipStudyCard({
    super.key,
    required this.showBack,
    required this.front,
    required this.back,
    this.elevation = 8,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(32),
  });

  final bool showBack;
  final Widget front;
  final Widget back;
  final double elevation;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 750),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final isUnder = child.key != ValueKey(showBack);
          final rotate = Tween<double>(
            begin: math.pi,
            end: 0.0,
          ).animate(animation);

          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final value =
                  isUnder ? math.min(rotate.value, math.pi / 2) : rotate.value;
              return Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(value),
                child: child,
              );
            },
          );
        },
        child: Material(
          key: ValueKey(showBack),
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          color: Colors.white,
          child: Container(
            width: double.infinity,
            padding: padding,
            child: showBack ? back : front,
          ),
        ),
      ),
    );
  }
}
