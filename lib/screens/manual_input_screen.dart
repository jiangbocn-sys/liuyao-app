import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/divination_provider.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _errorMessage = null;
    });

    String text = _controller.text.trim();

    // 检查是否为空
    if (text.isEmpty) {
      setState(() {
        _errorMessage = '请输入6个背面数';
      });
      return;
    }

    // 解析输入（可以是连续6个数字，如"210132"，或用逗号/空格分隔）
    List<int> backCounts = [];

    // 尝试解析为连续数字
    if (text.length == 6 && RegExp(r'^[0-3]{6}$').hasMatch(text)) {
      for (int i = 0; i < 6; i++) {
        backCounts.add(int.parse(text[i]));
      }
    } else {
      // 尝试解析为分隔的数字
      List<String> parts = text.split(RegExp(r'[,\s]+'));
      parts = parts.where((p) => p.isNotEmpty).toList();

      if (parts.length != 6) {
        setState(() {
          _errorMessage = '需要输入6个数字（初爻到上爻），每个数字为0-3';
        });
        return;
      }

      for (int i = 0; i < 6; i++) {
        int? value = int.tryParse(parts[i]);
        if (value == null || value < 0 || value > 3) {
          setState(() {
            _errorMessage = '第${i + 1}个数字必须是0-3';
          });
          return;
        }
        backCounts.add(value);
      }
    }

    // 验证通过，执行排盘
    final provider = Provider.of<DivinationProvider>(context, listen: false);
    provider.setBackCounts(backCounts);
    provider.calculate();

    // 跳转到结果页
    Navigator.pushNamed(context, '/result');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手动输入背面数'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '背面数含义',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '每次掷三枚铜钱，统计背面数量：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildRuleRow('0背', '三个正面', '老阴（动爻）', '×'),
                    _buildRuleRow('1背', '两正一反', '少阳（静爻）', '—'),
                    _buildRuleRow('2背', '一正两反', '少阴（静爻）', '- -'),
                    _buildRuleRow('3背', '三个反面', '老阳（动爻）', '○'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 输入区域
            const Text(
              '请输入6个背面数（从初爻到上爻）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '示例：210132 或 2,1,0,1,3,2',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 单个输入框
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '输入6个数字（每个0-3）',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _controller.clear(),
                ),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 16),

            // 错误提示
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 排盘按钮
            ElevatedButton(
              onPressed: _validateAndSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                '开始排盘',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String back, String coins, String type, String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(back, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$coins → $type'),
          ),
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              symbol,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4037),
              ),
            ),
          ),
        ],
      ),
    );
  }
}