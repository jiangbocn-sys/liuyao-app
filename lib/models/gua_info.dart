/// 卦信息模型
library;

import '../algorithms/constants.dart';

/// 卦信息类（本卦、变卦、互卦通用）
class GuaInfo {
  /// 卦名
  final String guaName;

  /// 卦符号（如 ☰☲）
  final String guaSymbol;

  /// 内卦编号（下卦，1-8）
  final int innerGuaId;

  /// 外卦编号（上卦，1-8）
  final int outerGuaId;

  /// 六十四卦序号（0-63）
  final int gua64Index;

  /// 卦宫编号（0-7）
  final int? gongNum;

  /// 卦宫名称
  final String? gongName;

  /// 卦五行
  final String? guaWuXing;

  /// 世爻位置（1-6）
  final int? shiYaoPos;

  /// 应爻位置（1-6）
  final int? yingYaoPos;

  GuaInfo({
    required this.guaName,
    required this.guaSymbol,
    required this.innerGuaId,
    required this.outerGuaId,
    required this.gua64Index,
    this.gongNum,
    this.gongName,
    this.guaWuXing,
    this.shiYaoPos,
    this.yingYaoPos,
  });

  /// 从内外卦编号创建卦信息
  factory GuaInfo.fromInnerOuter(int innerGuaId, int outerGuaId) {
    // 六十四卦索引：按内卦分组，每组按外卦排序
    // idx = (innerGuaId - 1) * 8 + (outerGuaId - 1)
    int gua64Index = (innerGuaId - 1) * 8 + (outerGuaId - 1);
    String guaName = gua64Names[gua64Index];
    String guaSymbol = '${baGuaSymbols[outerGuaId]}${baGuaSymbols[innerGuaId]}';
    int gongNum = gua64Gong[gua64Index];
    String gongName = gongNames[gongNum];
    String guaWuXing = gongWuXing[gongNum];

    return GuaInfo(
      guaName: guaName,
      guaSymbol: guaSymbol,
      innerGuaId: innerGuaId,
      outerGuaId: outerGuaId,
      gua64Index: gua64Index,
      gongNum: gongNum,
      gongName: gongName,
      guaWuXing: guaWuXing,
    );
  }

  /// 内卦名称
  String get innerGuaName => baGuaNames[innerGuaId];

  /// 外卦名称
  String get outerGuaName => baGuaNames[outerGuaId];

  /// 复制并更新部分属性
  GuaInfo copyWith({
    String? guaName,
    String? guaSymbol,
    int? innerGuaId,
    int? outerGuaId,
    int? gua64Index,
    int? gongNum,
    String? gongName,
    String? guaWuXing,
    int? shiYaoPos,
    int? yingYaoPos,
  }) {
    return GuaInfo(
      guaName: guaName ?? this.guaName,
      guaSymbol: guaSymbol ?? this.guaSymbol,
      innerGuaId: innerGuaId ?? this.innerGuaId,
      outerGuaId: outerGuaId ?? this.outerGuaId,
      gua64Index: gua64Index ?? this.gua64Index,
      gongNum: gongNum ?? this.gongNum,
      gongName: gongName ?? this.gongName,
      guaWuXing: guaWuXing ?? this.guaWuXing,
      shiYaoPos: shiYaoPos ?? this.shiYaoPos,
      yingYaoPos: yingYaoPos ?? this.yingYaoPos,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'guaName': guaName,
      'guaSymbol': guaSymbol,
      'innerGuaId': innerGuaId,
      'outerGuaId': outerGuaId,
      'gua64Index': gua64Index,
      'gongNum': gongNum,
      'gongName': gongName,
      'guaWuXing': guaWuXing,
      'shiYaoPos': shiYaoPos,
      'yingYaoPos': yingYaoPos,
    };
  }

  /// 从 JSON Map 创建
  factory GuaInfo.fromJson(Map<String, dynamic> json) {
    return GuaInfo(
      guaName: json['guaName'] as String,
      guaSymbol: json['guaSymbol'] as String,
      innerGuaId: json['innerGuaId'] as int,
      outerGuaId: json['outerGuaId'] as int,
      gua64Index: json['gua64Index'] as int,
      gongNum: json['gongNum'] as int?,
      gongName: json['gongName'] as String?,
      guaWuXing: json['guaWuXing'] as String?,
      shiYaoPos: json['shiYaoPos'] as int?,
      yingYaoPos: json['yingYaoPos'] as int?,
    );
  }

  @override
  String toString() {
    return 'GuaInfo($guaName $guaSymbol, $gongName, $guaWuXing)';
  }
}