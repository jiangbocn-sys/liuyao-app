import 'package:flutter/material.dart';
import '../models/yao_line.dart';
import '../algorithms/liuqin_config.dart';
import '../algorithms/constants.dart';
import '../algorithms/dizhi_quantification.dart';

/// 六爻详情表格组件
/// 从上爻到初爻显示六神、伏神、六亲、地支、世应、本卦、变卦
class YaoTable extends StatelessWidget {
  final List<YaoLine> yaoLines;
  final String gongWuXing; // 卦宫五行，用于计算伏神六亲
  final String benGuaName; // 本卦名称
  final String? bianGuaName; // 变卦名称（有动爻时）
  final bool hasDongYao; // 是否有动爻

  /// 是否显示数字量化
  final bool showQuantification;

  /// 量化值列表（从初爻到上爻，与yaoLines顺序对应）
  final List<QuantificationResult>? quantificationResults;

  const YaoTable({
    super.key,
    required this.yaoLines,
    required this.gongWuXing,
    required this.benGuaName,
    this.bianGuaName,
    this.hasDongYao = false,
    this.showQuantification = false,
    this.quantificationResults,
  });

  @override
  Widget build(BuildContext context) {
    // 从上爻(位置6)到初爻(位置1)排序
    final sortedLines = yaoLines.toList()
      ..sort((a, b) => b.position.compareTo(a.position));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 表头（包含卦名）
            _buildHeader(),

            // 爻行
            for (var yao in sortedLines)
              _buildYaoRow(yao),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Row(
        children: [
          const _HeaderCell('神', width: 28),
          const _HeaderCell('伏', width: 36),
          const _HeaderCell('六亲', width: 36),
          // 如果显示量化，支列加宽
          _HeaderCell('支', width: showQuantification ? 50 : 36),
          const _HeaderCell('', width: 24),
          // 本卦名称（加黑加粗）- 增加宽度避免换行
          _HeaderCell(benGuaName, width: 80, alignLeft: true, bold: true),
          // 变卦名称（有动爻时显示，加黑加粗）- 增加宽度避免换行
          if (hasDongYao && bianGuaName != null)
            _HeaderCell(bianGuaName!, width: 130, alignLeft: true, bold: true),
        ],
      ),
    );
  }

  Widget _buildYaoRow(YaoLine yao) {
    final isDong = yao.isDong;
    final isShi = yao.isShi == true;
    final isYing = yao.isYing == true;
    final isXunKong = yao.isXunKong == true;

    // 六亲显示完整两个字（如"官鬼")
    final liuQinDisplay = yao.liuQin ?? '';

    // 地支+五行（紧凑显示，不留空）
    final ganZhiDisplay = yao.ganZhi ?? '';
    final zhiWuXing = ganZhiDisplay + (yao.wuXing ?? '');

    // 获取量化值（按位置索引匹配，避免重复地支匹配错误）
    QuantificationResult? quantResult;
    if (showQuantification && quantificationResults != null && quantificationResults!.length >= yao.position) {
      // position 1-6 对应 quantificationResults 索引 0-5
      quantResult = quantificationResults![yao.position - 1];
    }

    // 伏神：显示六亲首字+伏神地支（如伏神是"酉"，六亲是"官鬼"，显示为"官酉")
    String fuShenDisplay = '';
    if (yao.fuShen != null && yao.fuShen!.isNotEmpty) {
      // 根据伏神地支和卦宫五行计算伏神六亲
      String fuShenLiuQin = LiuQinConfig.getLiuQin(gongWuXing, diZhiWuXing[yao.fuShen] ?? '');
      fuShenDisplay = fuShenLiuQin.isNotEmpty ? fuShenLiuQin[0] : ''; // 六亲首字
      fuShenDisplay += yao.fuShen!; // 加上伏神地支
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
      decoration: BoxDecoration(
        color: isDong ? Colors.orange.shade50 : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 六神（取第一个字）
          _YaoCell(
            (yao.liuShen?.isNotEmpty ?? false) ? yao.liuShen![0] : '',
            width: 28,
          ),

          // 伏神（六亲首字+地支）
          _YaoCell(
            fuShenDisplay,
            width: 36,
            color: yao.fuShen != null ? Colors.blue.shade700 : null,
          ),

          // 六亲（完整两个字）
          _YaoCell(liuQinDisplay, width: 36),

          // 地支+五行（支持量化显示）
          _buildZhiCell(zhiWuXing, isXunKong, quantResult),

          // 世应
          _YaoCell(
            isShi ? '世' : (isYing ? '应' : ''),
            width: 24,
            color: isShi ? Colors.red.shade700 : (isYing ? Colors.blue.shade700 : null),
            fontWeight: FontWeight.bold,
          ),

          // 本卦爻象 - 增加宽度避免换行
          _YaoSymbolCell(yao, width: 80),

          // 变卦爻象+六亲+地支五行（有动爻时才显示）- 增加宽度避免换行
          if (hasDongYao)
            _BianYaoCell(yao, width: 130),
        ],
      ),
    );
  }

  /// 构建地支单元格（支持量化显示）
  Widget _buildZhiCell(String zhiWuXing, bool isXunKong, QuantificationResult? quant) {
    // 量化值颜色和文本
    Color? quantColor;
    String? quantText;
    
    if (showQuantification && quant != null) {
      if (quant.isRiChong) {
        quantColor = Colors.orange;
        quantText = '*';
      } else {
        final value = quant.totalValue ?? 0;
        if (value > 0) {
          quantColor = Colors.red;
        } else if (value < 0) {
          quantColor = Colors.blue;
        } else {
          quantColor = Colors.grey;
        }
        quantText = value.toStringAsFixed(1).replaceAll('.0', '');
      }
    }
    
    return SizedBox(
      width: showQuantification ? 50 : 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            zhiWuXing,
            style: TextStyle(
              fontSize: 14,
              color: isXunKong ? Colors.grey : Colors.black87,
              fontStyle: isXunKong ? FontStyle.italic : FontStyle.normal,
            ),
          ),
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
}

/// 表头单元格
class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final bool alignLeft;
  final bool bold;

  const _HeaderCell(this.text, {required this.width, this.alignLeft = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: bold ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: bold ? const Color(0xFF8B4513) : const Color(0xFF5D4037),
        ),
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
      ),
    );
  }
}

/// 爻行单元格
class _YaoCell extends StatelessWidget {
  final String text;
  final double width;
  final Color? color;
  final FontWeight fontWeight;

  const _YaoCell(
    this.text, {
    required this.width,
    this.color,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: color ?? Colors.black87,
          fontWeight: fontWeight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 爻象符号单元格（紧凑显示）
class _YaoSymbolCell extends StatelessWidget {
  final YaoLine yao;
  final double width;

  const _YaoSymbolCell(this.yao, {required this.width});

  @override
  Widget build(BuildContext context) {
    final symbol = yao.yaoTypeSymbol;
    final isDong = yao.isDong;

    return SizedBox(
      width: width,
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: 13,
          color: isDong ? Colors.orange.shade700 : const Color(0xFF8B4513),
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

/// 变卦爻象单元格（显示所有爻的爻象+六亲+地支五行）
class _BianYaoCell extends StatelessWidget {
  final YaoLine yao;
  final double width;

  const _BianYaoCell(this.yao, {required this.width});

  @override
  Widget build(BuildContext context) {
    // 检查是否有变卦信息
    if (yao.bianYaoType == null && yao.bianGanZhi == null) {
      return SizedBox(width: width, child: const Text(''));
    }

    // 变卦爻象符号
    String symbol;
    if (yao.bianYaoType == YaoType.laoYang) {
      symbol = '▅▅▅▅▅○';
    } else if (yao.bianYaoType == YaoType.laoYin) {
      symbol = '▅▅　▅▅×';
    } else if (yao.bianYaoType == YaoType.shaoYang) {
      symbol = '▅▅▅▅▅';
    } else if (yao.bianYaoType == YaoType.shaoYin) {
      symbol = '▅▅　▅▅';
    } else {
      symbol = '';
    }

    // 变卦六亲+地支五行（如"兄寅木"）
    String bianInfo = '';
    if (yao.bianLiuQin != null && yao.bianLiuQin!.isNotEmpty) {
      bianInfo = yao.bianLiuQin!;
      if (yao.bianGanZhi != null) {
        bianInfo += yao.bianGanZhi!;
        if (yao.bianWuXing != null) {
          bianInfo += yao.bianWuXing!;
        }
      }
    } else if (yao.bianGanZhi != null) {
      bianInfo = yao.bianGanZhi!;
      if (yao.bianWuXing != null) {
        bianInfo += yao.bianWuXing!;
      }
    }

    return SizedBox(
      width: width,
      child: Row(
        children: [
          // 爻象符号
          Text(
            symbol,
            style: TextStyle(
              fontSize: 13,
              color: yao.isDong ? Colors.orange.shade700 : const Color(0xFF8B4513),
              fontWeight: FontWeight.bold,
            ),
          ),
          // 六亲+地支五行 - 减少间隙
          if (bianInfo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 1),
              child: Text(
                bianInfo,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}