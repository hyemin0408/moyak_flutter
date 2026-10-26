import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps the original kiosk's horizontal proportions while using tall displays.
/// Only layout bounds change vertically; text and artwork are never distorted.
class KioskViewport extends StatelessWidget {
  const KioskViewport({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final portrait = bounds.maxHeight >= bounds.maxWidth;
      final height = portrait
          ? math.max(1920.0, bounds.maxHeight * 1080 / bounds.maxWidth)
          : 1920.0;
      return Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1080,
            height: height,
            child: _KioskLayoutData(height: height, child: child),
          ),
        ),
      );
    },
  );
}

class _KioskLayoutData extends InheritedWidget {
  const _KioskLayoutData({required this.height, required super.child});
  final double height;
  @override
  bool updateShouldNotify(_KioskLayoutData oldWidget) =>
      height != oldWidget.height;
}

/// The header stays at the top and the footer at the bottom. Additional height
/// becomes usable space between body elements, not blank bands outside the page.
class KioskCanvas extends StatelessWidget {
  const KioskCanvas({
    super.key,
    required this.children,
    this.centerContent = false,
    this.clipBehavior = Clip.hardEdge,
  });
  final List<Widget> children;
  final bool centerContent;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final height =
        context
            .dependOnInheritedWidgetOfExactType<_KioskLayoutData>()
            ?.height ??
        1920;
    final extra = height - 1920;
    double mapY(double y) {
      if (centerContent) return y + extra / 2;
      if (y <= 204) return y;
      if (y >= 1758) return y + extra;
      return y + extra * (y - 204) / (1758 - 204);
    }

    Widget place(Widget child) {
      if (child is! Positioned || child.top == null || child.height == null) {
        return child;
      }
      final top = mapY(child.top!);
      return Positioned(
        key: child.key,
        left: child.left,
        right: child.right,
        top: top,
        width: child.width,
        height: centerContent
            ? child.height
            : mapY(child.top! + child.height!) - top,
        child: child.child,
      );
    }

    return Stack(
      clipBehavior: clipBehavior,
      children: children.map(place).toList(),
    );
  }
}

/// Increase small labels moderately; slot layout still protects dense headers.
double kioskFontSize(double size) => size <= 18
    ? size + 2
    : size <= 28
    ? size + 4
    : size <= 40
    ? size + 2
    : size;
