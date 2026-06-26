import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/divination_record.dart';
import '../providers/divination_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/yao_table.dart';
import '../widgets/shensha_card.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late TextEditingController _interpretationController;
  bool _isEditing = false;
  int? _savedRecordId; // 跟踪已保存记录的ID，避免重复保存

  @override
  void initState() {
    super.initState();
    _interpretationController = TextEditingController();
  }

  @override
  void dispose() {
    _interpretationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DivinationProvider>(context);
    final record = provider.record;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('排盘结果')),
        body: const Center(
          child: Text('无排盘数据，请先进行起卦'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('排盘结果'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveRecord(record),
            tooltip: '保存记录',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 起卦人信息（如有）
            if (record.querentName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '起卦人：${record.querentName}${record.querentGender.isNotEmpty ? " (${record.querentGender})" : ""}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),

            // 基本信息（日期、干支、问题）
            _buildInfoCard(record),

            const SizedBox(height: 4),

            // 神煞信息（在基本信息下方、卦名上方）
            ShenshaCard(shensha: record.shensha),

            const SizedBox(height: 4),

            // 六爻详情表格（包含卦名）
            YaoTable(
              yaoLines: record.yaoLines,
              gongWuXing: record.benGua.guaWuXing ?? '',
              benGuaName: record.benGua.guaName,
              bianGuaName: record.bianGua?.guaName,
              hasDongYao: record.hasDongYao(),
            ),

            const SizedBox(height: 10),

            // 解卦输入区
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
                            onPressed: () => _finishEditing(record),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('完成', style: TextStyle(fontSize: 12)),
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

  /// 保存记录（如果已保存过则更新，否则新建）
  void _saveRecord(DivinationRecord record) async {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    try {
      if (_savedRecordId != null) {
        // 已保存过，更新解卦内容
        await historyProvider.updateInterpretation(
          _savedRecordId!,
          _interpretationController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已更新解卦内容')),
        );
      } else {
        // 首次保存，创建新记录
        final recordWithInterpretation = record.copyWith(
          interpretation: _interpretationController.text,
        );
        _savedRecordId = await historyProvider.saveRecord(recordWithInterpretation);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存到历史记录')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  /// 完成编辑（如果已保存过则自动更新）
  void _finishEditing(DivinationRecord record) {
    setState(() => _isEditing = false);

    // 如果已保存过，自动更新解卦内容
    if (_savedRecordId != null && _interpretationController.text.isNotEmpty) {
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      historyProvider.updateInterpretation(
        _savedRecordId!,
        _interpretationController.text,
      );
    }
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