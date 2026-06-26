import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// 单枚铜钱组件
/// 两阶段交互：抛铜钱（持续旋转） → 点击停止 → 落地动画 → 显示结果
class CoinWidget extends StatefulWidget {
  final String frontImage;
  final String backImage;
  final bool finalResult;
  final bool startAnimation;
  final bool stopAndShowResult;
  /// 落地动画完成后回调（父组件用来统计停止数量）
  final VoidCallback? onAnimationStopped;

  const CoinWidget({
    super.key,
    required this.frontImage,
    required this.backImage,
    required this.finalResult,
    required this.startAnimation,
    required this.stopAndShowResult,
    this.onAnimationStopped,
  });

  @override
  State<CoinWidget> createState() => _CoinWidgetState();
}

class _CoinWidgetState extends State<CoinWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _switchTimer;

  /// 当前显示的正面图（旋转期间随机切换）
  String _currentImage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _currentImage = widget.frontImage;
  }

  @override
  void dispose() {
    _switchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startRotating() {
    _switchTimer?.cancel();
    _controller.repeat();

    _switchTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted) return;
      if (mounted) {
        setState(() {
          _currentImage = Random().nextBool()
              ? widget.frontImage
              : widget.backImage;
        });
      }
    });
  }

  void _stopRotating() {
    _switchTimer?.cancel();
    _controller.stop();

    // 落地动画：平滑回到正面角度
    _controller
        .animateTo(0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic)
        .then((_) {
      // 动画完成后通知父组件
      widget.onAnimationStopped?.call();
    });

    setState(() {
      _currentImage =
          widget.finalResult ? widget.frontImage : widget.backImage;
    });
  }

  void _resetToIdle() {
    _switchTimer?.cancel();
    _controller.stop();
    _controller.reset();
    _currentImage = widget.frontImage;
  }

  @override
  void didUpdateWidget(CoinWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.startAnimation && !oldWidget.startAnimation) {
      _startRotating();
      return;
    }

    if (widget.stopAndShowResult && !oldWidget.stopAndShowResult) {
      _stopRotating();
      return;
    }

    // 新一轮抛掷：两个信号都变回 false → 重置待机
    if (!widget.startAnimation && !widget.stopAndShowResult &&
        (oldWidget.startAnimation || oldWidget.stopAndShowResult)) {
      _resetToIdle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 2 * pi;
        return Transform(
          transform: Matrix4.rotationY(angle),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            _currentImage,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
