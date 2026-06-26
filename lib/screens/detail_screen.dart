import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/divination_record.dart';
import '../providers/history_provider.dart';
import '../widgets/yao_table.dart';
import '../widgets/shensha_card.dart';
import '../utils/export_helper.dart';

/// 排盘详情页 + 解卦编辑
class DetailScreen extends StatefulWidget {
  final DivinationRecord record;

  const DetailScreen({super.key, required this.record});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late TextEditingController _interpretationController;
  bool _isEditing = false;

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

            // 基本信息
            _buildInfoCard(widget.record),

            const SizedBox(height: 4),

            // 神煞信息（在基本信息下方、卦名上方）
            ShenshaCard(shensha: widget.record.shensha),

            const SizedBox(height: 4),

            // 六爻详情表格（包含卦名）
            YaoTable(
              yaoLines: widget.record.yaoLines,
              gongWuXing: widget.record.benGua.guaWuXing ?? '',
              benGuaName: widget.record.benGua.guaName,
              bianGuaName: widget.record.bianGua?.guaName,
              hasDongYao: widget.record.hasDongYao(),
            ),

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