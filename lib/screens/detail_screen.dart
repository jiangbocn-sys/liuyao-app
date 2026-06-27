import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/divination_record.dart';
import '../providers/history_provider.dart';
import '../widgets/yao_table.dart';
import '../widgets/yao_relations_painter.dart';
import '../widgets/shensha_card.dart';
import '../utils/export_helper.dart';
import '../algorithms/dizhi_quantification.dart';
import '../algorithms/dizhi_relations.dart';

/// 排盘详情页 + 解卦编辑
/// 支持数字量化、冲合生克关系显示
class DetailScreen extends StatefulWidget {
  final DivinationRecord record;

  const DetailScreen({super.key, required this.record});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late TextEditingController _interpretationController;
  bool _isEditing = false;

  // 辅助解卦开关状态
  bool _showQuantification = false; // 数字量化
  bool _showChong = false;          // 冲
  bool _showHe = false;             // 合
  bool _showSheng = false;          // 生
  bool _showKe = false;             // 克

  @override
  void initState() {
    super.initState();
    _interpretationController = TextEditingController(
      text: widget.record.interpretation ?? '',
    );
  }

  @override
  void dispose() {
    _interpretationController.dispose();
    super.dispose();
  }

  /// 提取地支（从干支字符串，如"丙寅"提取"寅"）
  String _extractDiZhi(String ganZhi) {
    if (ganZhi.length >= 2) {
      return ganZhi.substring(1);
    }
    return ganZhi;
  }

  /// 计算量化值
  List<QuantificationResult> _calculateQuantification(DivinationRecord record) {
    final monthZhi = _extractDiZhi(record.monthGz);
    final dayZhi = _extractDiZhi(record.dayGz);

    // 提取六爻地支（从初爻到上爻）
    final yaoDiZhiList = record.yaoLines
        .map((y) => y.ganZhi ?? '')
        .where((z) => z.isNotEmpty)
        .toList();

    return DiZhiQuantification.calculateAll(yaoDiZhiList, monthZhi, dayZhi);
  }

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
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'month',
          toType: 'yao',
          relationType: DiZhiRelations.relationChong,
          description: '月冲',
          fromDiZhi: monthZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showHe && DiZhiRelations.isHe(monthZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'month',
          toType: 'yao',
          relationType: DiZhiRelations.relationHe,
          description: '月合',
          fromDiZhi: monthZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showSheng && DiZhiRelations.isSheng(monthZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'month',
          toType: 'yao',
          relationType: DiZhiRelations.relationSheng,
          description: '月生',
          fromDiZhi: monthZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showKe && DiZhiRelations.isKe(monthZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'month',
          toType: 'yao',
          relationType: DiZhiRelations.relationKe,
          description: '月克',
          fromDiZhi: monthZhi,
          toDiZhi: yaoZhi,
        ));
      }

      // 日辰关系
      if (_showChong && DiZhiRelations.isChong(dayZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'day',
          toType: 'yao',
          relationType: DiZhiRelations.relationChong,
          description: '日冲',
          fromDiZhi: dayZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showHe && DiZhiRelations.isHe(dayZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'day',
          toType: 'yao',
          relationType: DiZhiRelations.relationHe,
          description: '日合',
          fromDiZhi: dayZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showSheng && DiZhiRelations.isSheng(dayZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'day',
          toType: 'yao',
          relationType: DiZhiRelations.relationSheng,
          description: '日生',
          fromDiZhi: dayZhi,
          toDiZhi: yaoZhi,
        ));
      } else if (_showKe && DiZhiRelations.isKe(dayZhi, yaoZhi)) {
        relations.add(YaoRelation(
          fromPosition: 0,
          toPosition: yao.position,
          fromType: 'day',
          toType: 'yao',
          relationType: DiZhiRelations.relationKe,
          description: '日克',
          fromDiZhi: dayZhi,
          toDiZhi: yaoZhi,
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
            fromPosition: dongYao.position,
            toPosition: jingYao.position,
            fromType: 'yao',
            toType: 'yao',
            relationType: DiZhiRelations.relationChong,
            description: '动冲静',
            fromDiZhi: dongZhi,
            toDiZhi: jingZhi,
          ));
        } else if (_showHe && DiZhiRelations.isHe(dongZhi, jingZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position,
            toPosition: jingYao.position,
            fromType: 'yao',
            toType: 'yao',
            relationType: DiZhiRelations.relationHe,
            description: '动合静',
            fromDiZhi: dongZhi,
            toDiZhi: jingZhi,
          ));
        } else if (_showSheng && DiZhiRelations.isSheng(dongZhi, jingZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position,
            toPosition: jingYao.position,
            fromType: 'yao',
            toType: 'yao',
            relationType: DiZhiRelations.relationSheng,
            description: '动生静',
            fromDiZhi: dongZhi,
            toDiZhi: jingZhi,
          ));
        } else if (_showKe && DiZhiRelations.isKe(dongZhi, jingZhi)) {
          relations.add(YaoRelation(
            fromPosition: dongYao.position,
            toPosition: jingYao.position,
            fromType: 'yao',
            toType: 'yao',
            relationType: DiZhiRelations.relationKe,
            description: '动克静',
            fromDiZhi: dongZhi,
            toDiZhi: jingZhi,
          ));
        }
      }

      // 对伏神（如果有）- 只考虑冲合，不考虑生克
      for (final yao in record.yaoLines) {
        if (yao.fuShen != null && yao.fuShen!.isNotEmpty) {
          if (_showChong && DiZhiRelations.isChong(dongZhi, yao.fuShen!)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: yao.position,
              fromType: 'yao',
              toType: 'fu',
              relationType: DiZhiRelations.relationChong,
              description: '动冲伏',
              fromDiZhi: dongZhi,
              toDiZhi: yao.fuShen!,
            ));
          } else if (_showHe && DiZhiRelations.isHe(dongZhi, yao.fuShen!)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: yao.position,
              fromType: 'yao',
              toType: 'fu',
              relationType: DiZhiRelations.relationHe,
              description: '动合伏',
              fromDiZhi: dongZhi,
              toDiZhi: yao.fuShen!,
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
              fromPosition: dongYao.position,
              toPosition: dongYao.position,
              fromType: 'bian',
              toType: 'yao',
              relationType: DiZhiRelations.relationChong,
              description: '变冲动',
              fromDiZhi: bianZhi,
              toDiZhi: dongZhi,
            ));
          } else if (_showHe && DiZhiRelations.isHe(bianZhi, dongZhi)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: dongYao.position,
              fromType: 'bian',
              toType: 'yao',
              relationType: DiZhiRelations.relationHe,
              description: '变合动',
              fromDiZhi: bianZhi,
              toDiZhi: dongZhi,
            ));
          } else if (_showSheng && DiZhiRelations.isSheng(bianZhi, dongZhi)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: dongYao.position,
              fromType: 'bian',
              toType: 'yao',
              relationType: DiZhiRelations.relationSheng,
              description: '变生动',
              fromDiZhi: bianZhi,
              toDiZhi: dongZhi,
            ));
          } else if (_showKe && DiZhiRelations.isKe(bianZhi, dongZhi)) {
            relations.add(YaoRelation(
              fromPosition: dongYao.position,
              toPosition: dongYao.position,
              fromType: 'bian',
              toType: 'yao',
              relationType: DiZhiRelations.relationKe,
              description: '变克动',
              fromDiZhi: bianZhi,
              toDiZhi: dongZhi,
            ));
          }
        }
      }
    }

    return relations;
  }

  void _saveInterpretation() {
    final provider = Provider.of<HistoryProvider>(context, listen: false);
    if (widget.record.id != null) {
      provider.updateInterpretation(
        widget.record.id!,
        _interpretationController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('解卦已保存')),
      );
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _exportRecord() async {
    final markdown = ExportHelper.exportToMarkdown(widget.record);
    final dir = await getTemporaryDirectory();
    final fileName = ExportHelper.getFileName(widget.record);
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(markdown);
    await Share.shareXFiles([XFile(file.path)], subject: '六爻排盘记录');
  }

  void _deleteRecord() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定删除这条记录吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<HistoryProvider>(context, listen: false);
              if (widget.record.id != null) {
                provider.deleteRecord(widget.record.id!);
              }
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回历史页
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('记录已删除')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 计算量化值
    final quantificationResults = _calculateQuantification(widget.record);

    // 计算关系
    final relations = (_showChong || _showHe || _showSheng || _showKe)
        ? _calculateRelations(widget.record)
        : <YaoRelation>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('排盘详情'),
        actions: [
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportRecord,
            tooltip: '导出',
          ),
          // 删除按钮
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRecord,
            tooltip: '删除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 起卦人信息（如有）
            if (widget.record.querentName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '起卦人：${widget.record.querentName}${widget.record.querentGender.isNotEmpty ? " (${widget.record.querentGender})" : ""}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),

            // 六爻详情表格（带关系连线）
            YaoRelationsOverlay(
              relations: relations,
              monthZhi: _extractDiZhi(widget.record.monthGz),
              dayZhi: _extractDiZhi(widget.record.dayGz),
              showQuantification: _showQuantification,
              infoCard: _buildInfoCard(widget.record),
              shenshaCard: ShenshaCard(shensha: widget.record.shensha),
              child: YaoTable(
                yaoLines: widget.record.yaoLines,
                gongWuXing: widget.record.benGua.guaWuXing ?? '',
                benGuaName: widget.record.benGua.guaName,
                bianGuaName: widget.record.bianGua?.guaName,
                hasDongYao: widget.record.hasDongYao(),
                showQuantification: _showQuantification,
                quantificationResults: quantificationResults,
              ),
            ),

            const SizedBox(height: 4),

            // 辅助开关栏（移到YaoTable下方）
            _buildHelperSwitches(),

            const SizedBox(height: 10),

            // 解卦编辑区
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          '解卦笔记',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: _saveInterpretation,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('保存', style: TextStyle(fontSize: 12)),
                          )
                        else
                          TextButton(
                            onPressed: () => setState(() => _isEditing = true),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('编辑', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_isEditing)
                      TextField(
                        controller: _interpretationController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '请输入解卦内容...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(10),
                        ),
                        style: const TextStyle(fontSize: 13),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          _interpretationController.text.isEmpty
                              ? '（点击编辑输入解卦内容）'
                              : _interpretationController.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: _interpretationController.text.isEmpty
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  /// 构建单个开关（使用小勾选方框）
  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: activeColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DivinationRecord record) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息（紧凑一行显示）
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.formattedDivTime,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // 干支（一行，放大加粗）
            Text(
              '${record.yearGz}年 ${record.monthGz}月 ${record.dayGz}日 ${record.hourGz}时',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 4),

            // 旬空和卦宫（一行）
            Text(
              '旬空：${record.xunKong}  卦宫：${record.benGua.gongName}(${record.benGua.guaWuXing})',
              style: const TextStyle(fontSize: 12),
            ),

            // 问题（如有）
            if (record.question.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '问：${record.question}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}