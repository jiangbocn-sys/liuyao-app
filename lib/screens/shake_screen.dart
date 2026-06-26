import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../providers/divination_provider.dart';
import '../widgets/coin_widget.dart';

/// 摇卦阶段
enum _Phase { idle, rotating, showing, complete }

/// 摇卦页面
/// 支持两种模式（页面内开关切换）：
///   - 手动模式：点击抛铜钱→旋转→点击停止→看结果
///   - 手摇模式：摇动手机→铜钱旋转→静止1秒→自动显示结果
class ShakeScreen extends StatefulWidget {
  const ShakeScreen({super.key});

  @override
  State<ShakeScreen> createState() => _ShakeScreenState();
}

class _ShakeScreenState extends State<ShakeScreen> {
  static const _fronts = [
    'assets/images/jq01.png', 'assets/images/kx01.png',
    'assets/images/ql01.jpg', 'assets/images/sz01.png', 'assets/images/yz01.png',
  ];
  static const _backs = ['assets/images/back01.png', 'assets/images/back02.png'];
  static const _yaoNames = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];

  // --- 状态 ---
  _Phase _phase = _Phase.idle;
  int _currentThrow = 1;
  final List<int> _backCounts = [];
  int _currentBackCount = 0;
  late List<_Coin> _coins;
  bool _handShake = false;

  // --- 手摇模式传感器 ---
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _accelMagnitude = 9.8;
  Timer? _stillTimer;
  bool _isHandShaking = false;

  @override
  void initState() {
    super.initState();
    _initCoins();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _stillTimer?.cancel();
    super.dispose();
  }

  void _initCoins() {
    final fronts = List<String>.from(_fronts)..shuffle();
    _coins = fronts.take(3).map((f) {
      return _Coin(front: f, back: _backs[Random().nextInt(_backs.length)], isHeads: true);
    }).toList();
  }

  void _toggleHandShake(bool on) {
    setState(() {
      _handShake = on;
      _stillTimer?.cancel();
      _isHandShaking = false;
    });
    if (on) {
      _startSensors();
    } else {
      _accelSub?.cancel();
      _accelSub = null;
    }
  }

  // ============== 手摇传感器 ==============

  void _startSensors() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen((event) {
      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _accelMagnitude = _accelMagnitude * 0.7 + mag * 0.3;
      final diff = (mag - _accelMagnitude).abs();

      if (!_isHandShaking && _phase == _Phase.idle && diff > 12) {
        _isHandShaking = true;
        _stillTimer?.cancel();
        _throw();
      } else if (_isHandShaking && _phase == _Phase.rotating && diff < 2) {
        if (_stillTimer == null || !_stillTimer!.isActive) {
          _stillTimer = Timer(const Duration(seconds: 1), () {
            if (mounted) {
              _stop();
            }
          });
        }
      } else if (_isHandShaking && _phase == _Phase.rotating && diff >= 2) {
        _stillTimer?.cancel();
      }
    });
  }

  // ============== 阶段操作 ==============

  void _throw() {
    final rng = Random();
    setState(() {
      for (final c in _coins) {
        c.isHeads = rng.nextBool();
        c.animating = true;
        c.stopping = false;
      }
      _phase = _Phase.rotating;
    });
  }

  void _stop() {
    _stillTimer?.cancel();
    _isHandShaking = false;
    setState(() {
      for (final c in _coins) {
        c.stopping = true;
      }
      _phase = _Phase.showing;
      _currentBackCount = _coins.where((c) => !c.isHeads).length;
      _backCounts.add(_currentBackCount);
    });
  }

  void _next() {
    _stillTimer?.cancel();
    _isHandShaking = false;
    if (_currentThrow < 6) {
      setState(() {
        _currentThrow++;
        for (final c in _coins) {
          c.isHeads = true;
          c.animating = false;
          c.stopping = false;
        }
        _phase = _Phase.idle;
      });
    } else {
      setState(() => _phase = _Phase.complete);
    }
  }

  void _finish() {
    _accelSub?.cancel();
    final provider = Provider.of<DivinationProvider>(context, listen: false);
    provider.setBackCounts(_backCounts);
    provider.calculate();
    Navigator.pushReplacementNamed(context, '/result');
  }

  // ============== 辅助 ==============

  static String _yaoType(int n) => switch (n) {
    0 => '老阴（动爻）', 1 => '少阳（静爻）', 2 => '少阴（静爻）', 3 => '老阳（动爻）', _ => '',
  };
  static String _yaoSymbol(int n) => switch (n) {
    0 => '▅▅　▅▅×', 1 => '▅▅▅▅▅', 2 => '▅▅　▅▅', 3 => '▅▅▅▅▅○', _ => '',
  };
  static bool _isDong(int n) => n == 0 || n == 3;

  // ============== UI ==============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('第 $_currentThrow/6 爻'),
        actions: [
          // AppBar 右侧手摇开关
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('手摇', style: TextStyle(fontSize: 13)),
              Switch(
                value: _handShake,
                onChanged: _toggleHandShake,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _CoinTray(coins: _coins, phase: _phase),
                    const SizedBox(height: 12),
                    if (_phase == _Phase.rotating && _handShake)
                      _HintBanner('🔄 停止摇动后自动揭晓'),
                    if (_phase == _Phase.rotating && !_handShake)
                      _HintBanner('旋转中，点击下方按钮停止'),
                    if (_phase == _Phase.idle && _handShake)
                      _HintBanner('📳 请摇动手机'),
                    if (_phase == _Phase.showing)
                      _ResultCard(name: _yaoNames[_currentThrow - 1], backCount: _currentBackCount),
                  ],
                ),
              ),
            ),
            if (!_handShake)
              _BottomBar(phase: _phase, onThrow: _throw, onStop: _stop, onNext: _next, onFinish: _finish),
            if (_handShake && _phase == _Phase.complete)
              _BottomBar(phase: _Phase.complete, onThrow: () {}, onStop: () {}, onNext: () {}, onFinish: _finish),
            _ProgressPanel(backCounts: _backCounts),
          ],
        ),
      ),
    );
  }
}

// ============== 铜钱数据 ==============

class _Coin {
  final String front;
  final String back;
  bool isHeads;
  bool animating = false;
  bool stopping = false;
  _Coin({required this.front, required this.back, this.isHeads = true});
}

// ============== 子组件 ==============

class _CoinTray extends StatelessWidget {
  final List<_Coin> coins;
  final _Phase phase;
  const _CoinTray({required this.coins, required this.phase});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final c in coins)
              CoinWidget(
                frontImage: c.front,
                backImage: c.back,
                finalResult: c.isHeads,
                startAnimation: c.animating,
                stopAndShowResult: c.stopping,
              ),
          ],
        ),
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  final String text;
  const _HintBanner(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.orange.shade800)),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String name;
  final int backCount;
  const _ResultCard({required this.name, required this.backCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('$name：$backCount背',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B4513))),
          const SizedBox(height: 6),
          Text(_ShakeScreenState._yaoType(backCount), style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 6),
          Text(_ShakeScreenState._yaoSymbol(backCount),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final _Phase phase;
  final VoidCallback onThrow, onStop, onNext, onFinish;
  const _BottomBar({required this.phase, required this.onThrow, required this.onStop, required this.onNext, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: switch (phase) {
        _Phase.idle => _btn('🎲 抛铜钱', Icons.casino, onThrow),
        _Phase.rotating => _btn('👀 看结果', Icons.remove_red_eye, onStop, color: Colors.orange.shade700),
        _Phase.showing => _btn('➡ 下一爻', Icons.arrow_forward, onNext),
        _Phase.complete => _btn('📋 查看排盘', Icons.auto_awesome, onFinish, color: Colors.green.shade700),
      },
    );
  }

  Widget _btn(String label, IconData icon, VoidCallback onTap, {Color? color}) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color != null ? Colors.white : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final List<int> backCounts;
  const _ProgressPanel({required this.backCounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('摇卦进度', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final done = i < backCounts.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? const Color(0xFF8B4513) : Colors.grey.shade300,
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                        style: TextStyle(fontSize: 11, color: done ? Colors.white : Colors.grey.shade600)),
                    ),
                  );
                }),
              ),
              if (backCounts.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (int i = backCounts.length - 1; i >= 0; i--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(width: 36, child: Text(_ShakeScreenState._yaoNames[i], style: const TextStyle(fontSize: 13))),
                        Expanded(
                          child: Row(
                            children: [
                              Text(_ShakeScreenState._yaoType(backCounts[i]),
                                style: TextStyle(fontSize: 13,
                                  color: _ShakeScreenState._isDong(backCounts[i]) ? Colors.orange.shade700 : null,
                                  fontWeight: _ShakeScreenState._isDong(backCounts[i]) ? FontWeight.bold : null)),
                              const SizedBox(width: 6),
                              Text('${backCounts[i]}背',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(_ShakeScreenState._yaoSymbol(backCounts[i]),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8B4513))),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
