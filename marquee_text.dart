import 'package:dengai/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final VoidCallback onScrollComplete;
  final double scrollVelocity; // 像素/秒
  final TextStyle? style;

  const MarqueeText({
    required this.text,
    required this.onScrollComplete,
    this.scrollVelocity = 50.0,
    this.style,
    Key? key,
  }) : super(key: key);

  @override
  _MarqueeTextState createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _containerWidth = 0;
  double _textWidth = 0;
  bool _needsScroll = false;
  final GlobalKey _mq = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
    )..addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.scrollVelocity != widget.scrollVelocity) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initAnimation());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onScrollComplete();
      _controller.reset();
      if (_needsScroll) _controller.forward();
    }
  }

  void _initAnimation() {
    if (_containerWidth <= 0 || _textWidth <= 0) return;

    _needsScroll = _textWidth > _containerWidth;

    if (_needsScroll) {
      // 计算滚动距离：文本宽度
      final totalDistance = _textWidth;
      final durationSeconds = totalDistance / widget.scrollVelocity;
      _controller.duration = Duration(seconds: durationSeconds.toInt());
      if (!_controller.isAnimating) _controller.forward();
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30.h,
      decoration: BoxDecoration(
        color: const Color.fromARGB(158, 0, 0, 0),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 8.w,
          ),
          Image.asset(
            Assets.imagesVideoLoudspeaker,
            width: 16.w,
            height: 16.w,
          ),
          SizedBox(
            width: 8.w,
          ),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.0, 0.1], // 调整渐变的范围
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textStyle =
                      widget.style ?? DefaultTextStyle.of(context).style;
                  final textPainter = TextPainter(
                    text: TextSpan(text: widget.text, style: textStyle),
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                  )..layout();

                  return SizedBox(
                    key: _mq,
                    width: constraints.maxWidth,
                    child: ClipRect(
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          if (textPainter.width > constraints.maxWidth)
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    // 从组件右侧进入，滚动到完全离开组件左侧
                                    _containerWidth -
                                        _controller.value * _textWidth,
                                    0,
                                  ),
                                  child: child,
                                );
                              },
                              child: Text(
                                widget.text,
                                style: textStyle,
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                              ),
                            )
                          else
                            Text(
                              widget.text,
                              style: textStyle,
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final textStyle = widget.style ?? DefaultTextStyle.of(context).style;
      final textPainter = TextPainter(
        text: TextSpan(text: widget.text, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      setState(() {
        _textWidth = textPainter.width;
        _containerWidth = _mq.currentContext?.size?.width ?? 0;
        _initAnimation();
      });
    });
  }
}
