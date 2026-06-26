import 'package:flutter/material.dart';
import '../models/yao_line.dart';
import '../algorithms/liuqin_config.dart';
import '../algorithms/constants.dart';

/// 六爻详情表格组件
/// 从上爻到初爻显示六神、伏神、六亲、地支、世应、本卦、变卦
class YaoTable extends StatelessWidget {
  final List<YaoLine> yaoLines;
  final String gongWuXing; // 卦宫五行，用于计算伏神六亲
  final String benGuaName; // 本卦名称
  final String? bianGuaName; // 变卦名称（有动爻时）
  final bool hasDongYao; // 是否有动爻

  const YaoTable({
    super.key,
    required this.yaoLines,
    required this.gongWuXing,
    required this.benGuaName,
    this.bianGuaName,
    this.hasDongYao = false,
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
          const _HeaderCell('支', width: 36),
          const _HeaderCell('', width: 24),
          // 本卦名称（加黑加粗）
          _HeaderCell(benGuaName, width: 68, alignLeft: true, bold: true),
          // 变卦名称（有动爻时显示，加黑加粗）
          if (hasDongYao && bianGuaName != null)
            _HeaderCell(bianGuaName!, width: 120, alignLeft: true, bold: true),
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

          // 地支+五行（紧凑，不留空）
          _YaoCell(
            zhiWuXing,
            width: 36,
            color: isXunKong ? Colors.grey : null,
            isItalic: isXunKong,
          ),

          // 世应
          _YaoCell(
            isShi ? '世' : (isYing ? '应' : ''),
            width: 24,
            color: isShi ? Colors.red.shade700 : (isYing ? Colors.blue.shade700 : null),
            fontWeight: FontWeight.bold,
          ),

          // 本卦爻象
          _YaoSymbolCell(yao, width: 68),

          // 变卦爻象+六亲+地支五行（有动爻时才显示）
          if (hasDongYao)
            _BianYaoCell(yao, width: 120),
        ],
      ),
    );
  }

  String _getBianSymbol(YaoLine yao) {
    if (!yao.isDong) return '';
    // 动爻变卦：阳变阴，阴变阳
    if (yao.isYang) {
      return '▅▅　▅▅'; // 老阳变少阴
    } else {
      return '▅▅▅▅▅'; // 老阴变少阳
    }
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
  final bool isBold;
  final bool isItalic;
  final FontWeight fontWeight;
  final bool alignLeft;

  const _YaoCell(
    this.text, {
    required this.width,
    this.color,
    this.isBold = false,
    this.isItalic = false,
    this.fontWeight = FontWeight.normal,
    this.alignLeft = false,
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
          fontWeight: isBold ? FontWeight.bold : fontWeight,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        ),
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
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
          fontSize: 14,
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
              fontSize: 14,
              color: yao.isDong ? Colors.orange.shade700 : const Color(0xFF8B4513),
              fontWeight: FontWeight.bold,
            ),
          ),
          // 六亲+地支五行
          if (bianInfo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                bianInfo,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}