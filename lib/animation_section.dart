import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:animate_do/animate_do.dart';

class AnimatedSection extends StatefulWidget {
  final Widget child;
  final String keyId;
  final Duration duration;

  const AnimatedSection({
    required this.child,
    required this.keyId,
    this.duration = const Duration(milliseconds: 800),
    super.key,
  });

  @override
  _AnimatedSectionState createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<AnimatedSection> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.keyId),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.2 && !_visible) {
          setState(() => _visible = true);
        }
      },
      child: _visible
          ? FadeInUp(
              duration: widget.duration,
              child: widget.child,
            )
          : Opacity(opacity: 0, child: widget.child),
    );
  }
}
