import 'package:flutter/material.dart';
import '../models/divination_record.dart';

/// 卦象显示组件
/// 展示本卦卦名，有动爻时显示变卦卦名
class GuaDisplay extends StatelessWidget {
  final DivinationRecord record;

  const GuaDisplay({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final benGua = record.benGua;
    final bianGua = record.bianGua;
    final hasDongYao = record.hasDongYao();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 本卦卦名
          Text(
            benGua.guaName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),

          // 变卦卦名（有动爻时显示）
          if (hasDongYao && bianGua != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    ' → ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    bianGua.guaName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}