import 'package:flutter/material.dart';
import '../models/divination_record.dart';
import '../database/record_dao.dart';

/// 历史记录状态管理 Provider
class HistoryProvider extends ChangeNotifier {
  final RecordDao _dao = RecordDao();

  /// 所有记录列表
  List<DivinationRecord> _records = [];

  /// 当前选中的记录ID列表（用于批量操作）
  final Set<int> _selectedIds = {};

  /// 搜索关键词
  String _searchKeyword = '';

  /// 是否正在加载
  bool _isLoading = false;

  /// 获取记录列表
  List<DivinationRecord> get records => _records;

  /// 获取选中的记录
  List<int> get selectedIds => _selectedIds.toList();

  /// 获取搜索关键词
  String get searchKeyword => _searchKeyword;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 是否有选中记录
  bool hasSelection() => _selectedIds.isNotEmpty;

  /// 是否全选
  bool isAllSelected() {
    if (_records.isEmpty) return false;
    return _selectedIds.length == _records.length;
  }

  /// 检查记录是否选中
  bool isSelected(int id) => _selectedIds.contains(id);

  /// 加载所有记录
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await _dao.getAll();
      _selectedIds.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索记录
  Future<void> search(String keyword) async {
    _searchKeyword = keyword;
    _isLoading = true;
    notifyListeners();

    try {
      if (keyword.isEmpty) {
        _records = await _dao.getAll();
      } else {
        _records = await _dao.search(keyword);
      }
      _selectedIds.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 选择/取消选择记录
  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  /// 全选/取消全选
  void toggleSelectAll() {
    if (isAllSelected()) {
      _selectedIds.clear();
    } else {
      _selectedIds.clear();
      for (var record in _records) {
        if (record.id != null) {
          _selectedIds.add(record.id!);
        }
      }
    }
    notifyListeners();
  }

  /// 清除选择
  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// 保存新记录
  Future<int> saveRecord(DivinationRecord record) async {
    final id = await _dao.insert(record);
    await loadAll();
    return id;
  }

  /// 更新解卦内容
  Future<void> updateInterpretation(int id, String interpretation) async {
    await _dao.updateInterpretation(id, interpretation);
    await loadAll();
  }

  /// 删除单条记录
  Future<void> deleteRecord(int id) async {
    await _dao.delete(id);
    _selectedIds.remove(id);
    await loadAll();
  }

  /// 删除选中的记录
  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    await _dao.deleteMultiple(_selectedIds.toList());
    _selectedIds.clear();
    await loadAll();
  }

  /// 获取选中记录的列表
  List<DivinationRecord> getSelectedRecords() {
    return _records.where((r) => r.id != null && _selectedIds.contains(r.id!)).toList();
  }
}