import 'package:flutter/material.dart';
import '../models/divination_record.dart';
import '../algorithms/gua_calculator.dart';

/// 起卦状态管理 Provider
class DivinationProvider extends ChangeNotifier {
  /// 起卦时间
  DateTime _divTime = DateTime.now();

  /// 所问问题
  String _question = '';

  /// 起卦方式
  String _startMethod = 'manual';

  /// 起卦人姓名
  String _querentName = '';

  /// 起卦人性别
  String _querentGender = '';

  /// 背面数列表
  List<int> _backCounts = [];

  /// 排盘结果
  DivinationRecord? _record;

  /// 获取起卦时间
  DateTime get divTime => _divTime;

  /// 获取问题
  String get question => _question;

  /// 获取起卦方式
  String get startMethod => _startMethod;

  /// 获取起卦人姓名
  String get querentName => _querentName;

  /// 获取起卦人性别
  String get querentGender => _querentGender;

  /// 获取背面数
  List<int> get backCounts => _backCounts;

  /// 获取排盘结果
  DivinationRecord? get record => _record;

  /// 设置起卦时间
  void setDivinationTime(DateTime time) {
    _divTime = time;
    notifyListeners();
  }

  /// 设置问题
  void setQuestion(String question) {
    _question = question;
    notifyListeners();
  }

  /// 设置起卦方式
  void setStartMethod(String method) {
    _startMethod = method;
    notifyListeners();
  }

  /// 设置起卦人姓名
  void setQuerentName(String name) {
    _querentName = name;
    notifyListeners();
  }

  /// 设置起卦人性别
  void setQuerentGender(String gender) {
    _querentGender = gender;
    notifyListeners();
  }

  /// 设置背面数
  void setBackCounts(List<int> counts) {
    if (counts.length != 6) {
      throw ArgumentError('背面数必须是6个');
    }
    for (int count in counts) {
      if (count < 0 || count > 3) {
        throw ArgumentError('背面数必须在0-3之间');
      }
    }
    _backCounts = counts;
    notifyListeners();
  }

  /// 执行排盘计算
  void calculate() {
    if (_backCounts.length != 6) {
      throw StateError('请先设置背面数');
    }
    if (_question.isEmpty) {
      _question = '未填写问题';
    }

    _record = GuaCalculator.calculate(
      backCounts: _backCounts,
      divTime: _divTime,
      question: _question,
      startMethod: _startMethod,
      querentName: _querentName,
      querentGender: _querentGender,
    );

    notifyListeners();
  }

  /// 直接设置排盘记录（用于图像导入校正）
  void setRecord(DivinationRecord record) {
    _record = record;
    _divTime = record.divTime;
    _question = record.question;
    _startMethod = record.startMethod;
    _querentName = record.querentName;
    _querentGender = record.querentGender;
    notifyListeners();
  }

  /// 清除当前排盘（重新开始）
  void clear() {
    _backCounts = [];
    _record = null;
    _question = '';
    _querentName = '';
    _querentGender = '';
    notifyListeners();
  }

  /// 更新解卦内容
  void updateInterpretation(String interpretation) {
    if (_record != null) {
      _record = _record!.copyWith(interpretation: interpretation);
      notifyListeners();
    }
  }
}