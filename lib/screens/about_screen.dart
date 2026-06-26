import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 应用说明页面
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使用说明'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 应用介绍
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, size: 24, color: const Color(0xFF8B4513)),
                        const SizedBox(width: 8),
                        const Text(
                          '六爻排盘',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '本应用采用传统纳甲筮法，支持摇卦和手动输入两种起卦方式，自动计算六爻、六亲、六神、伏神、神煞等信息。',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 使用方法
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, size: 24, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '使用方法',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildStep(1, '设置起卦时间', '点击"修改时间"选择起卦的日期和时辰，系统会自动计算对应的干支。'),
                    const SizedBox(height: 12),

                    _buildStep(2, '填写起卦人信息', '可填写姓名和性别（可选），方便日后查阅。'),
                    const SizedBox(height: 12),

                    _buildStep(3, '输入所问问题', '填写您想要咨询的问题（可选）。'),
                    const SizedBox(height: 12),

                    _buildStep(4, '选择起卦方式', '• 在线摇卦：模拟抛掷三枚铜钱，共六次\n• 手动输入：直接输入六次抛掷的背面数'),
                    const SizedBox(height: 12),

                    _buildStep(5, '查看排盘结果', '排盘完成后可查看本卦、变卦、六爻详情等信息，并可保存到历史记录。'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 背面数说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 24, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '背面数含义',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '每次掷三枚铜钱，统计背面（反面）数量：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildRuleRow('0背', '三个正面', '老阴（动爻）'),
                    _buildRuleRow('1背', '两正一反', '少阳（静爻）'),
                    _buildRuleRow('2背', '一正两反', '少阴（静爻）'),
                    _buildRuleRow('3背', '三个反面', '老阳（动爻）'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 联系方式
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.feedback, size: 24, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '问题反馈',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '使用中如有问题或建议，欢迎联系反馈：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat, size: 20, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            '微信号：FlyingKool',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: 'FlyingKool'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制微信号')),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('复制', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleRow(String back, String coins, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              back,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$coins → $type'),
          ),
        ],
      ),
    );
  }
}