import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Wraps an image so it drifts *inside* its own frame as the list scrolls.
/// Works for vertical lists and horizontal carousels.
///
/// Usage:
///   ParallaxItem(
///     axis: Axis.vertical,
///     background: Image.asset(...),
///     child: <card content>,
///   )
class ParallaxItem extends StatelessWidget {
  const ParallaxItem({
    super.key,
    required this.background,
    required this.child,
    this.axis = Axis.vertical,
    this.borderRadius,
  });

  final Widget background;
  final Widget child;
  final Axis axis;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bgKey = GlobalKey();
    final content = Stack(
      fit: StackFit.expand,
      children: [
        _ParallaxFlow(
          axis: axis,
          backgroundKey: bgKey,
          child: SizedBox(key: bgKey, child: background),
        ),
        child,
      ],
    );
    return borderRadius == null
        ? content
        : ClipRRect(borderRadius: borderRadius!, child: content);
  }
}

class _ParallaxFlow extends StatelessWidget {
  const _ParallaxFlow({
    required this.child,
    required this.backgroundKey,
    required this.axis,
  });

  final Widget child;
  final GlobalKey backgroundKey;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return child; // not inside a scroll view
    return Flow(
      delegate: _ParallaxFlowDelegate(
        scrollable: scrollable,
        itemContext: context,
        backgroundKey: backgroundKey,
        axis: axis,
      ),
      children: [child],
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.backgroundKey,
    required this.axis,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final GlobalKey backgroundKey;
  final Axis axis;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints c) =>
      axis == Axis.vertical
          ? BoxConstraints.tightFor(width: c.maxWidth)
          : BoxConstraints.tightFor(height: c.maxHeight);

  @override
  void paintChildren(FlowPaintingContext context) {
    final scrollBox = scrollable.context.findRenderObject() as RenderBox?;
    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final bgBox = backgroundKey.currentContext?.findRenderObject() as RenderBox?;
    if (scrollBox == null || itemBox == null || bgBox == null) {
      context.paintChild(0);
      return;
    }

    final itemOffset = itemBox.localToGlobal(
      itemBox.size.center(Offset.zero),
      ancestor: scrollBox,
    );
    final viewport = scrollable.position.viewportDimension;
    final itemSize = itemBox.size;
    final bgSize = bgBox.size;

    if (axis == Axis.vertical) {
      final f = (itemOffset.dy / viewport).clamp(0.0, 1.0);
      final rect = Alignment(0, f * 2 - 1)
          .inscribe(bgSize, Offset.zero & itemSize);
      context.paintChild(0,
          transform: Transform.translate(offset: Offset(0, rect.top))
              .transform);
    } else {
      final f = (itemOffset.dx / viewport).clamp(0.0, 1.0);
      final rect = Alignment(f * 2 - 1, 0)
          .inscribe(bgSize, Offset.zero & itemSize);
      context.paintChild(0,
          transform: Transform.translate(offset: Offset(rect.left, 0))
              .transform);
    }
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate old) =>
      old.scrollable != scrollable ||
      old.itemContext != itemContext ||
      old.backgroundKey != backgroundKey ||
      old.axis != axis;
}
