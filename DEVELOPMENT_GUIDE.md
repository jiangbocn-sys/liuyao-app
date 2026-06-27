# 六爻解卦辅助功能开发文档

## 目标

在 `result_screen.dart` 的解卦笔记栏位上方，添加5个开关：
1. **数字量化** - 显示地支旺衰数值
2. **冲** - 显示六冲关系连线（红色）
3. **合** - 显示六合关系连线（绿色）
4. **生** - 显示五行相生连线（黄色）
5. **克** - 显示五行相克连线（蓝色）

---

## 已完成的基础设施

以下文件已存在，无需重新创建：

### 1. 数字量化模块
**文件**: `lib/algorithms/dizhi_quantification.dart`

```dart
class QuantificationResult {
  final String yaoDiZhi;      // 爻地支
  final String monthZhi;      // 月建地支
  final String dayZhi;        // 日辰地支
  final double monthValue;    // 月建量化值
  final double dayValue;      // 日辰量化值
  final double totalValue;    // 总值
  final bool isRiChong;       // 是否日冲
  final String description;   // 描述
}

class DiZhiQuantification {
  /// 计算单个地支的量化值
  static QuantificationResult calculate(
    String yaoDiZhi, 
    String monthZhi, 
    String dayZhi
  );
  
  /// 批量计算六爻量化值
  static List<QuantificationResult> calculateAll(
    List<String> yaoDiZhiList,
    String monthZhi,
    String dayZhi,
  );
}
```

### 2. 地支关系模块
**文件**: `lib/algorithms/dizhi_relations.dart`

```dart
class YaoRelation {
  final int fromPosition;      // 起点位置(1-6, 0表示月建/日辰)
  final int toPosition;        // 终点位置(1-6)
  final String fromType;       // 'month'|'day'|'yao'|'bian'|'fu'
  final String toType;         // 'yao'|'fu'
  final int relationType;      // 关系类型
  final String description;      // 描述
  final String fromDiZhi;      // 起点地支
  final String toDiZhi;        // 终点地支
  
  // 关系类型常量
  static const int relationChong = 1;    // 冲 - 红色
  static const int relationHe = 2;       // 合 - 绿色
  static const int relationSanHe = 3;    // 三合 - 紫色(暂不用)
  static const int relationBanHe = 4;    // 半合 - 橙色(暂不用)
  static const int relationSheng = 5;    // 生 - 黄色
  static const int relationKe = 6;     // 克 - 蓝色
}

class DiZhiRelations {
  static bool isChong(String zhi1, String zhi2);      // 六冲
  static bool isHe(String zhi1, String zhi2);           // 六合
  static bool isSanHe(String zhi1, String zhi2, String zhi3); // 三合(暂不用)
  static bool isSheng(String fromZhi, String toZhi);  // 五行相生
  static bool isKe(String fromZhi, String toZhi);       // 五行相克
}
```

### 3. 关系连线绘制组件
**文件**: `lib/widgets/yao_relations_painter.dart`

```dart
/// 关系连线容器组件
class YaoRelationsOverlay extends StatelessWidget {
  final List<YaoRelation> relations;    // 关系列表
  final Widget child;                   // 子组件(YaoTable)
  final String monthZhi;                // 月建地支
  final String dayZhi;                  // 日辰地支
  
  const YaoRelationsOverlay({
    super.key,
    required this.relations,
    required this.child,
    required this.monthZhi,
    required this.dayZhi,
  });
}
```

---

## 需要修改的文件

### 文件1: `lib/widgets/yao_table.dart`

**修改目标**: 添加数字量化显示支持

**当前构造函数**:
```dart
const YaoTable({
  super.key,
  required this.yaoLines,
  required this.gongWuXing,
  required this.benGuaName,
  this.bianGuaName,
  this.hasDongYao = false,
});
```

**修改为**:
```dart
const YaoTable({
  super.key,
  required this.yaoLines,
  required this.gongWuXing,
  required this.benGuaName,
  this.bianGuaName,
  this.hasDongYao = false,
  this.showQuantification = false,           // 新增
  this.quantificationResults,                // 新增
});
```

**新增字段**:
```dart
/// 是否显示数字量化
final bool showQuantification;

/// 量化值列表（与yaoLines顺序对应）
final List<QuantificationResult>? quantificationResults;
```

**修改 `_buildHeader()`**:
- 将"支"列宽度从 36 改为 `showQuantification ? 50 : 36`

**修改 `_buildYaoRow()`**:
1. 在 `zhiWuXing` 定义后，添加量化值查找逻辑：
```dart
// 获取量化值
QuantificationResult? quantResult;
if (showQuantification && quantificationResults != null) {
  quantResult = quantificationResults!.firstWhere(
    (q) => q.yaoDiZhi == yao.ganZhi,
    orElse: () => QuantificationResult(
      yaoDiZhi: yao.ganZhi ?? '',
      monthZhi: '',
      dayZhi: '',
      monthValue: 0,
      dayValue: 0,
      totalValue: 0,
      isRiChong: false,
      description: '',
    ),
  );
}
```

2. 将地支显示从 `_YaoCell` 改为调用 `_buildZhiCell`:
```dart
// 原来:
_YaoCell(
  zhiWuXing,
  width: 36,
  color: isXunKong ? Colors.grey : null,
  isItalic: isXunKong,
),

// 改为:
_buildZhiCell(zhiWuXing, isXunKong, quantResult),
```

**新增方法 `_buildZhiCell()`**:
```dart
/// 构建地支单元格（支持量化显示）
Widget _buildZhiCell(String zhiWuXing, bool isXunKong, QuantificationResult? quant) {
  Color? quantColor;
  String? quantText;
  
  if (showQuantification && quant != null) {
    if (quant.isRiChong) {
      quantColor = Colors.orange;
      quantText = '*';
    } else {
      final value = quant.totalValue;
      if (value > 0) {
        quantColor = Colors.red;
      } else if (value < 0) {
        quantColor = Colors.blue;
      } else {
        quantColor = Colors.grey;
      }
      // 去掉末尾的.0
      quantText = value.toStringAsFixed(1).replaceAll('.0', '');
    }
  }
  
  return SizedBox(
    width: showQuantification ? 50 : 36,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 地支+五行
        Text(
          zhiWuXing,
          style: TextStyle(
            fontSize: 14,
            color: isXunKong ? Colors.grey : Colors.black87,
            fontStyle: isXunKong ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        // 量化值（小一号字体）
        if (showQuantification && quantText != null)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              quantText,
              style: TextStyle(
                fontSize: 10,
                color: quantColor,
                fontWeight: quant?.isRiChong == true ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
      ],
    ),
  );
}
```

---

### 文件2: `lib/screens/result_screen.dart`

**修改目标**: 添加开关面板和关系计算逻辑

**步骤1: 添加导入**
```dart
import '../algorithms/dizhi_quantification.dart';
import '../algorithms/dizhi_relations.dart';
import '../widgets/yao_relations_painter.dart';
```

**步骤2: 添加状态变量**
在 `_ResultScreenState` 类中添加：
```dart
// 开关状态
bool _showQuantification = false;  // 数字量化
bool _showChong = false;             // 冲
bool _showHe = false;                // 合
bool _showSheng = false;           // 生
bool _showKe = false;                // 克
```

**步骤3: 添加辅助方法**

提取地支：
```dart
/// 从干支字符串提取地支（如"丙寅"→"寅"）
String _extractDiZhi(String ganZhi) {
  if (ganZhi.length >= 2) {
    return ganZhi.substring(1);
  }
  return ganZhi;
}
```

计算量化值：
```dart
/// 计算六爻量化值
List<QuantificationResult> _calculateQuantification(DivinationRecord record) {
  final monthZhi = _extractDiZhi(record.monthGz);
  final dayZhi = _extractDiZhi(record.dayGz);
  
  final yaoDiZhiList = record.yaoLines
      .map((y) => y.ganZhi ?? '')
      .where((z) => z.isNotEmpty)
      .toList();
      
  return DiZhiQuantification.calculateAll(yaoDiZhiList, monthZhi, dayZhi);
}
```

计算关系（核心逻辑）：
```dart
/// 计算爻关系
List<YaoRelation> _calculateRelations(DivinationRecord record) {
  final relations = <YaoRelation>[];
  final monthZhi = _extractDiZhi(record.monthGz);
  final dayZhi = _extractDiZhi(record.dayGz);
  
  // 1. 月建、日辰对六爻的关系
  for (final yao in record.yaoLines) {
    if (yao.ganZhi == null || yao.ganZhi!.isEmpty) continue;
    final yaoZhi = yao.ganZhi!;
    
    // 月建关系
    if (_showChong && DiZhiRelations.isChong(monthZhi, yaoZhi)) {
      relations.add(YaoRelation(
        fromPosition: 0, toPosition: yao.position,
        fromType: 'month', toType: 'yao',
        relationType: YaoRelation.relationChong,
        description: '月冲',
        fromDiZhi: monthZhi, toDiZhi: yaoZhi,
      ));
    } else if (_showHe && DiZhiRelations.isHe(monthZhi, yaoZhi)) {
      relations.add(YaoRelation(
        fromPosition: 0, toPosition: yao.position,
        fromType: 'month', toType: 'yao',
        relationType: YaoRelation.relationHe,
        description: '月合',
        fromDiZhi: monthZhi, toDiZhi: yaoZhi,
      ));
    } else if (_showSheng && DiZhiRelations.isSheng(monthZhi, yaoZhi)) {
      relations.add(YaoRelation(
        fromPosition: 0, toPosition: yao.position,
        fromType: 'month', toType: 'yao',
        relationType: YaoRelation.relationSheng,
        description: '月生',
        fromDiZhi: monthZhi, toDiZhi: yaoZhi,
      ));
    } else if (_showKe && DiZhiRelations.isKe(monthZhi, yaoZhi)) {
      relations.add(YaoRelation(
        fromPosition: 0, toPosition: yao.position,
        fromType: 'month', toType: 'yao',
        relationType: YaoRelation.relationKe,
        description: '月克',
        fromDiZhi: monthZhi, toDiZhi: yaoZhi,
      ));
    }
    
    // 日辰关系（类似月建，fromType改为'day'）
    if (_showChong && DiZhiRelations.isChong(dayZhi, yaoZhi)) {
      relations.add(YaoRelation(
        fromPosition: 0, toPosition: yao.position,
        fromType: 'day', toType: 'yao',
        relationType: YaoRelation.relationChong,
        description: '日冲',
        fromDiZhi: dayZhi, toDiZhi: yaoZhi,
      ));
    } else if (_showHe && DiZhiRelations.isHe(dayZhi, yaoZhi)) {
      relations.add(YaoRelation(
        fromPosition: 0, toPosition: yao.position,
        fromType: 'day', toType: 'yao',
        relationType: YaoRelation.relationHe,
        description: '日合',
        fromDiZhi: dayZhi, toDiZhi: yaoZhi,
      ));
    } else if (_showSheng && DiZhiRelations.isSheng(dayZhi, yaoZhi)) {
      relations.add(YaoRelation(
        fromPosition: 0, toPosition: yao.position,
        fromType: 'day', toType: 'yao',
        relationType: YaoRelation.relationSheng,
        description: '日生',
        fromDiZhi: dayZhi, toDiZhi: yaoZhi,
      ));
    } else if (_showKe && DiZhiRelations.isKe(dayZhi, yaoZhi)) {
      relations.add(YaoRelation(
        fromPosition: 0, toPosition: yao.position,
        fromType: 'day', toType: 'yao',
        relationType: YaoRelation.relationKe,
        description: '日克',
        fromDiZhi: dayZhi, toDiZhi: yaoZhi,
      ));
    }
  }
  
  // 2. 动爻对静爻（含伏藏）的关系
  final dongYaos = record.yaoLines.where((y) => y.isDong).toList();
  final jingYaos = record.yaoLines.where((y) => !y.isDong).toList();
  
  for (final dongYao in dongYaos) {
    if (dongYao.ganZhi == null || dongYao.ganZhi!.isEmpty) continue;
    final dongZhi = dongYao.ganZhi!;
    
    // 对静爻
    for (final jingYao in jingYaos) {
      if (jingYao.ganZhi == null || jingYao.ganZhi!.isEmpty) continue;
      final jingZhi = jingYao.ganZhi!;
      
      if (_showChong && DiZhiRelations.isChong(dongZhi, jingZhi)) {
        relations.add(YaoRelation(
          fromPosition: dongYao.position, toPosition: jingYao.position,
          fromType: 'yao', toType: 'yao',
          relationType: YaoRelation.relationChong,
          description: '动冲静',
          fromDiZhi: dongZhi, toDiZhi: jingZhi,
        ));
      } else if (_showHe && DiZhiRelations.isHe(dongZhi, jingZhi)) {
        relations.add(YaoRelation(
          fromPosition: dongYao.position, toPosition: jingYao.position,
          fromType: 'yao', toType: 'yao',
          relationType: YaoRelation.relationHe,
          description: '动合静',
          fromDiZhi: dongZhi, toDiZhi: jingZhi,
        ));
      } else if (_showSheng && DiZhiRelations.isSheng(dongZhi, jingZhi)) {
        relations.add(YaoRelation(
          fromPosition: dongYao.position, toPosition: jingYao.position,
          fromType: 'yao', toType: 'yao',
          relationType: YaoRelation.relationSheng,
          description: '动生静',
          fromDiZhi: dongZhi, toDiZhi: jingZhi,
        ));
      } else if (_showKe && DiZhiRelations.isKe(dongZhi, jingZhi)) {
        relations.add(YaoRelation(
          fromPosition: dongYao.position, toPosition: jingYao.position,
          fromType: 'yao', toType: 'yao',
          relationType: YaoRelation.relationKe,
          description: '动克静',
          fromDiZhi: dongZhi, toDiZhi: jingZhi,
        ));
      }
    }
    
    // 对伏神
    for (final yao in record.yaoLines) {
      if (yao.fuShen != null && yao.fuShen!.isNotEmpty) {
        if (_showChong && DiZhiRelations.isChong(dongZhi, yao.fuShen!)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position, toPosition: yao.position,
            fromType: 'yao', toType: 'fu',
            relationType: YaoRelation.relationChong,
            description: '动冲伏',
            fromDiZhi: dongZhi, toDiZhi: yao.fuShen!,
          ));
        } else if (_showHe && DiZhiRelations.isHe(dongZhi, yao.fuShen!)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position, toPosition: yao.position,
            fromType: 'yao', toType: 'fu',
            relationType: YaoRelation.relationHe,
            description: '动合伏',
            fromDiZhi: dongZhi, toDiZhi: yao.fuShen!,
          ));
        } else if (_showSheng && DiZhiRelations.isSheng(dongZhi, yao.fuShen!)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position, toPosition: yao.position,
            fromType: 'yao', toType: 'fu',
            relationType: YaoRelation.relationSheng,
            description: '动生伏',
            fromDiZhi: dongZhi, toDiZhi: yao.fuShen!,
          ));
        } else if (_showKe && DiZhiRelations.isKe(dongZhi, yao.fuShen!)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position, toPosition: yao.position,
            fromType: 'yao', toType: 'fu',
            relationType: YaoRelation.relationKe,
            description: '动克伏',
            fromDiZhi: dongZhi, toDiZhi: yao.fuShen!,
          ));
        }
      }
    }
  }
  
  // 3. 变爻对动爻的关系
  if (record.bianGua != null) {
    for (final dongYao in dongYaos) {
      if (dongYao.bianGanZhi != null && dongYao.bianGanZhi!.isNotEmpty) {
        final bianZhi = dongYao.bianGanZhi!;
        final dongZhi = dongYao.ganZhi ?? '';
        if (dongZhi.isEmpty) continue;
        
        if (_showChong && DiZhiRelations.isChong(bianZhi, dongZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position, toPosition: dongYao.position,
            fromType: 'bian', toType: 'yao',
            relationType: YaoRelation.relationChong,
            description: '变冲动',
            fromDiZhi: bianZhi, toDiZhi: dongZhi,
          ));
        } else if (_showHe && DiZhiRelations.isHe(bianZhi, dongZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position, toPosition: dongYao.position,
            fromType: 'bian', toType: 'yao',
            relationType: YaoRelation.relationHe,
            description: '变合动',
            fromDiZhi: bianZhi, toDiZhi: dongZhi,
          ));
        } else if (_showSheng && DiZhiRelations.isSheng(bianZhi, dongZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position, toPosition: dongYao.position,
            fromType: 'bian', toType: 'yao',
            relationType: YaoRelation.relationSheng,
            description: '变生动',
            fromDiZhi: bianZhi, toDiZhi: dongZhi,
          ));
        } else if (_showKe && DiZhiRelations.isKe(bianZhi, dongZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position, toPosition: dongYao.position,
            fromType: 'bian', toType: 'yao',
            relationType: YaoRelation.relationKe,
            description: '变克动',
            fromDiZhi: bianZhi, toDiZhi: dongZhi,
          ));
        }
      }
    }
  }
  
  return relations;
}
```

**步骤4: 修改 build 方法**

在 build 方法开头计算数据：
```dart
@override
Widget build(BuildContext context) {
  final provider = Provider.of<DivinationProvider>(context);
  final record = provider.record;
  
  if (record == null) { /* ... */ }
  
  // 计算量化值
  final quantificationResults = _calculateQuantification(record);
  
  // 计算关系（如果有开关打开）
  final relations = (_showChong || _showHe || _showSheng || _showKe)
      ? _calculateRelations(record)
      : <YaoRelation>[];
      
  // ... 原有代码
}
```

**步骤5: 添加开关面板**

在 `ShenshaCard` 和 `YaoTable` 之间插入：
```dart
// 辅助开关栏
_buildHelperSwitches(),

const SizedBox(height: 4),
```

实现开关面板：
```dart
/// 构建辅助开关栏
Widget _buildHelperSwitches() {
  return Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        children: [
          _buildSwitch(
            label: '数字量化',
            value: _showQuantification,
            onChanged: (v) => setState(() => _showQuantification = v),
            activeColor: Colors.purple,
          ),
          _buildSwitch(
            label: '冲',
            value: _showChong,
            onChanged: (v) => setState(() => _showChong = v),
            activeColor: Colors.red,
          ),
          _buildSwitch(
            label: '合',
            value: _showHe,
            onChanged: (v) => setState(() => _showHe = v),
            activeColor: Colors.green,
          ),
          _buildSwitch(
            label: '生',
            value: _showSheng,
            onChanged: (v) => setState(() => _showSheng = v),
            activeColor: Colors.orange,
          ),
          _buildSwitch(
            label: '克',
            value: _showKe,
            onChanged: (v) => setState(() => _showKe = v),
            activeColor: Colors.blue,
          ),
        ],
      ),
    ),
  );
}

/// 构建单个开关
Widget _buildSwitch({
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
  required Color activeColor,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 36,
        height: 24,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      const SizedBox(width: 2),
      GestureDetector(
        onTap: () => onChanged(!value),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    ],
  );
}
```

**步骤6: 修改 YaoTable 调用**

将原有的 `YaoTable` 包装在 `YaoRelationsOverlay` 中：
```dart
// 原来:
YaoTable(
  yaoLines: record.yaoLines,
  gongWuXing: record.benGua.guaWuXing ?? '',
  benGuaName: record.benGua.guaName,
  bianGuaName: record.bianGua?.guaName,
  hasDongYao: record.hasDongYao(),
),

// 改为:
YaoRelationsOverlay(
  relations: relations,
  monthZhi: _extractDiZhi(record.monthGz),
  dayZhi: _extractDiZhi(record.dayGz),
  child: YaoTable(
    yaoLines: record.yaoLines,
    gongWuXing: record.benGua.guaWuXing ?? '',
    benGuaName: record.benGua.guaName,
    bianGuaName: record.bianGua?.guaName,
    hasDongYao: record.hasDongYao(),
    showQuantification: _showQuantification,
    quantificationResults: quantificationResults,
  ),
),
```

---

## 颜色对照表

| 功能 | 颜色 | 用途 |
|------|------|------|
| 冲 | 红色 (`Colors.red`) | 六冲关系连线 |
| 合 | 绿色 (`Colors.green`) | 六合关系连线 |
| 生 | 黄色/橙色 (`Colors.orange`) | 五行相生连线 |
| 克 | 蓝色 (`Colors.blue`) | 五行相克连线 |
| 数字量化正数 | 红色 | 旺 |
| 数字量化负数 | 蓝色 | 衰 |
| 数字量化0 | 灰色 | 平 |
| 日冲 | 橙色+`*` | 特殊标记 |

---

## 测试要点

1. **数字量化**：
   - 打开开关后，地支右侧显示数值
   - 正数红色、负数蓝色、0灰色
   - 日冲显示 `*`

2. **关系连线**：
   - 月建/日辰 → 爻（从顶部指向爻）
   - 动爻 → 静爻（水平弧线）
   - 变爻 → 动爻（垂直方向）
   - 多条线不重叠（使用 index 分散弧度）

3. **开关交互**：
   - 开关状态变化实时更新
   - 关闭开关时对应内容隐藏
