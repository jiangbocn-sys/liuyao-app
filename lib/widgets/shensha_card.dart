import 'package:flutter/material.dart';
import '../models/shensha_result.dart';

/// 神煞信息卡片组件
/// 两排显示10项神煞（一行5个）
class ShenshaCard extends StatelessWidget {
  final ShenshaResult shensha;

  const ShenshaCard({super.key, required this.shensha});

  @override
  Widget build(BuildContext context) {
    if (shensha.isEmpty()) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow([
              _item('天乙', shensha.tianYi),
              _item('驿马', shensha.yiMa),
              _item('咸池', shensha.xianChi),
              _item('禄神', shensha.luShen),
              _item('华盖', shensha.huaGai),
            ]),
            const SizedBox(height: 4),
            _buildRow([
              _item('天医', shensha.tianYiShen),
              _item('文昌', shensha.wenChang),
              _item('将星', shensha.jiangXing),
              _item('羊刃', shensha.yangRen),
              _item('天喜', shensha.tianXi),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<_ShenshaItem> items) {
    return Row(
      children: items.map((item) {
        if (item.value.isEmpty) return const SizedBox.shrink();
        return Expanded(
          child: Text(
            '${item.name}：${item.value}',
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  _ShenshaItem _item(String name, String value) => _ShenshaItem(name, value);
}

class _ShenshaItem {
  final String name;
  final String value;
  const _ShenshaItem(this.name, this.value);
}
