/// 地支数字量化表
/// 基于易青岚八字地支相互作用（月令与日支）的数字量化矩阵
class DiZhiQuantification {
  /// 列顺序：子、丑、寅、卯、辰、巳、午、未、申、酉、戌、亥
  static const List<String> columns = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  /// 月建行顺序：寅、卯、辰、巳、午、未、申、酉、戌、亥、子、丑
  static const List<String> monthRows = ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];

  /// 日辰行顺序：寅、卯、辰、巳、午、未、申、酉、戌、亥、子、丑
  static const List<String> dayRows = ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];

  /// 月建数字量化表
  /// 行：月支（寅月、卯月...丑月）
  /// 列：爻地支（子、丑...亥）
  static const Map<String, Map<String, double>> monthTable = {
    '寅': {'子': -0.1, '丑': -1, '寅': 2, '卯': 1, '辰': -1, '巳': 1, '午': 1, '未': -1, '申': -2, '酉': -0.1, '戌': -1, '亥': 0.5},
    '卯': {'子': -0.1, '丑': -1, '寅': 1, '卯': 2, '辰': -1, '巳': 1, '午': 1, '未': -1, '申': -0.1, '酉': -2, '戌': -0.5, '亥': -0.1},
    '辰': {'子': -1, '丑': 1, '寅': 0.5, '卯': 0.5, '辰': 2, '巳': -0.1, '午': -0.1, '未': 1, '申': 1, '酉': 2, '戌': -2, '亥': -1},
    '巳': {'子': -0.1, '丑': 1, '寅': -0.1, '卯': -0.1, '辰': 1, '巳': 2, '午': 1, '未': 1, '申': -0.5, '酉': -1, '戌': 1, '亥': -2},
    '午': {'子': -2, '丑': 1, '寅': -0.1, '卯': -0.1, '辰': 1, '巳': 1, '午': 2, '未': 2, '申': -1, '酉': -1, '戌': 1, '亥': -0.1},
    '未': {'子': -1, '丑': -2, '寅': -0.1, '卯': -0.1, '辰': 1, '巳': 0.5, '午': 0.5, '未': 2, '申': 1, '酉': 1, '戌': 1, '亥': -1},
    '申': {'子': 0.1, '丑': -0.1, '寅': -2, '卯': -1, '辰': -0.1, '巳': 0.5, '午': -0.1, '未': -0.1, '申': 2, '酉': 1, '戌': -0.1, '亥': 1},
    '酉': {'子': 1, '丑': -0.1, '寅': -1, '卯': -2, '辰': 0.5, '巳': -0.1, '午': -0.1, '未': -0.1, '申': 1, '酉': 2, '戌': -0.1, '亥': 1},
    '戌': {'子': -1, '丑': 1, '寅': -0.1, '卯': 0.5, '辰': -2, '巳': -0.1, '午': -0.1, '未': 1, '申': 1, '酉': 1, '戌': 2, '亥': -1},
    '亥': {'子': 1, '丑': -0.1, '寅': 2, '卯': 1, '辰': -0.1, '巳': -2, '午': -1, '未': -0.1, '申': -0.1, '酉': -0.1, '戌': -0.1, '亥': 2},
    '子': {'子': 2, '丑': 0.5, '寅': 1, '卯': 1, '辰': -0.1, '巳': -1, '午': -2, '未': -0.1, '申': -0.1, '酉': -0.1, '戌': -0.1, '亥': 1},
    '丑': {'子': -0.5, '丑': 2, '寅': -0.1, '卯': -0.1, '辰': 1, '巳': -0.1, '午': -0.1, '未': -2, '申': 1, '酉': 1, '戌': 1, '亥': -1},
  };

  /// 日辰数字量化表
  /// 行：日支（寅日、卯日...丑日）
  /// 列：爻地支（子、丑...亥）
  /// 值为 "日冲" 表示六冲关系，不参与计算
  static const Map<String, Map<String, Object>> dayTable = {
    '寅': {'子': 0, '丑': -1, '寅': 2, '卯': 1, '辰': -1, '巳': 1, '午': 1, '未': -1, '申': '日冲', '酉': 0, '戌': -1, '亥': 0},
    '卯': {'子': 0, '丑': -1, '寅': 1, '卯': 2, '辰': -1, '巳': 1, '午': 1, '未': -1, '申': 0, '酉': '日冲', '戌': -1, '亥': 0},
    '辰': {'子': -1, '丑': 1, '寅': 0, '卯': 0, '辰': 2, '巳': 0, '午': 0, '未': 1, '申': 1, '酉': 2, '戌': '日冲', '亥': -1},
    '巳': {'子': 0, '丑': 1, '寅': 0, '卯': 0, '辰': 1, '巳': 2, '午': 1, '未': 1, '申': -1, '酉': -1, '戌': 1, '亥': '日冲'},
    '午': {'子': '日冲', '丑': 1, '寅': 0, '卯': 0, '辰': 1, '巳': 1, '午': 2, '未': 2, '申': -1, '酉': -1, '戌': 1, '亥': 0},
    '未': {'子': -1, '丑': '日冲', '寅': 0, '卯': 0, '辰': 1, '巳': 0, '午': 0, '未': 2, '申': 1, '酉': 1, '戌': 1, '亥': -1},
    '申': {'子': 1, '丑': 0, '寅': '日冲', '卯': -1, '辰': 0, '巳': 0, '午': 0, '未': 0, '申': 2, '酉': 1, '戌': 0, '亥': 1},
    '酉': {'子': 1, '丑': 0, '寅': -1, '卯': '日冲', '辰': 0, '巳': 0, '午': 0, '未': 0, '申': 1, '酉': 2, '戌': 0, '亥': 1},
    '戌': {'子': -1, '丑': 1, '寅': 0, '卯': 0, '辰': '日冲', '巳': 0, '午': 0, '未': 1, '申': 1, '酉': 1, '戌': 2, '亥': -1},
    '亥': {'子': 1, '丑': 0, '寅': 2, '卯': 1, '辰': 0, '巳': '日冲', '午': -1, '未': 0, '申': 0, '酉': 0, '戌': 0, '亥': 2},
    '子': {'子': 2, '丑': 0, '寅': 1, '卯': 1, '辰': 0, '巳': -1, '午': '日冲', '未': 0, '申': 0, '酉': 0, '戌': 0, '亥': 1},
    '丑': {'子': -1, '丑': 2, '寅': 0, '卯': 0, '辰': 1, '巳': 0, '午': 0, '未': '日冲', '申': 1, '酉': 1, '戌': 1, '亥': -1},
  };

  /// 六冲关系对照表
  static const Map<String, String> liuChong = {
    '子': '午', '午': '子',
    '丑': '未', '未': '丑',
    '寅': '申', '申': '寅',
    '卯': '酉', '酉': '卯',
    '辰': '戌', '戌': '辰',
    '巳': '亥', '亥': '巳',
  };

  /// 检查两个地支是否六冲
  static bool isLiuChong(String diZhi1, String diZhi2) {
    return liuChong[diZhi1] == diZhi2;
  }

  /// 获取月建量化值
  /// @param monthZhi 月建地支（如：寅、卯等）
  /// @param yaoDiZhi 爻的地支
  /// @return 量化值，如果找不到返回 0
  static double getMonthValue(String monthZhi, String yaoDiZhi) {
    return monthTable[monthZhi]?[yaoDiZhi] ?? 0;
  }

  /// 获取日辰量化值
  /// @param dayZhi 日辰地支（如：寅、卯等）
  /// @param yaoDiZhi 爻的地支
  /// @return 量化值（double），或 null 表示日冲
  static double? getDayValue(String dayZhi, String yaoDiZhi) {
    final value = dayTable[dayZhi]?[yaoDiZhi];
    if (value == null) return null;
    if (value is String && value == '日冲') return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  /// 检查是否为日冲
  static bool isDayChong(String dayZhi, String yaoDiZhi) {
    final value = dayTable[dayZhi]?[yaoDiZhi];
    if (value is String && value == '日冲') return true;
    return false;
  }

  /// 计算爻地支的总量化值
  /// @param yaoDiZhi 爻的地支
  /// @param monthZhi 月建地支
  /// @param dayZhi 日辰地支
  /// @return QuantificationResult 包含总量化值和是否日冲的信息
  static QuantificationResult calculate(String yaoDiZhi, String monthZhi, String dayZhi) {
    final monthValue = getMonthValue(monthZhi, yaoDiZhi);
    final isRiChong = isDayChong(dayZhi, yaoDiZhi);

    // 日冲时不计算，返回特殊结果
    if (isRiChong) {
      return QuantificationResult(
        yaoDiZhi: yaoDiZhi,
        monthZhi: monthZhi,
        dayZhi: dayZhi,
        monthValue: monthValue,
        dayValue: null,
        totalValue: null,
        isRiChong: true,
        description: '日冲（${dayZhi}冲${yaoDiZhi}）',
      );
    }

    final dayValue = getDayValue(dayZhi, yaoDiZhi) ?? 0;
    final totalValue = monthValue + dayValue;

    return QuantificationResult(
      yaoDiZhi: yaoDiZhi,
      monthZhi: monthZhi,
      dayZhi: dayZhi,
      monthValue: monthValue,
      dayValue: dayValue,
      totalValue: totalValue,
      isRiChong: false,
      description: _generateDescription(monthValue, dayValue, totalValue),
    );
  }

  /// 根据量化值生成描述（只显示数值，不判断旺衰）
  static String _generateDescription(double monthValue, double dayValue, double totalValue) {
    return '月${monthValue.toString()} + 日${dayValue.toString()} = ${totalValue.toString()}';
  }

  /// 批量计算六爻的地支量化值
  /// @param yaoDiZhiList 六爻地支列表（从初爻到上爻）
  /// @param monthZhi 月建地支
  /// @param dayZhi 日辰地支
  /// @return 六爻量化结果列表
  static List<QuantificationResult> calculateAll(
    List<String> yaoDiZhiList,
    String monthZhi,
    String dayZhi,
  ) {
    return yaoDiZhiList.map((yaoDiZhi) => calculate(yaoDiZhi, monthZhi, dayZhi)).toList();
  }
}

/// 量化计算结果
class QuantificationResult {
  /// 爻的地支
  final String yaoDiZhi;

  /// 月建地支
  final String monthZhi;

  /// 日辰地支
  final String dayZhi;

  /// 月建量化值
  final double monthValue;

  /// 日辰量化值（null 表示日冲）
  final double? dayValue;

  /// 总量化值（null 表示日冲，不计算）
  final double? totalValue;

  /// 是否日冲
  final bool isRiChong;

  /// 描述文字
  final String description;

  QuantificationResult({
    required this.yaoDiZhi,
    required this.monthZhi,
    required this.dayZhi,
    required this.monthValue,
    required this.dayValue,
    required this.totalValue,
    required this.isRiChong,
    required this.description,
  });

  @override
  String toString() {
    if (isRiChong) {
      return '$yaoDiZhi: $description';
    }
    return '$yaoDiZhi: $description';
  }
}