/// 旬空计算器
/// 根据日干支判断旬空地支
library;

import '../models/yao_line.dart';
import 'constants.dart';

/// 旬空计算器
class XunKongCalculator {
  /// 获取日干支所在的旬首
  /// 六十甲子按旬分组：甲子旬(0-9), 甲戌旬(10-19), 甲申旬(20-29), ...
  static String getXunStart(String dayGz) {
    int idx = ganzhi60.indexOf(dayGz);
    if (idx < 0) return '';

    // 每旬10日，旬首索引 = idx / 10 * 10
    int xunStartIdx = (idx ~/ 10) * 10;
    return ganzhi60[xunStartIdx];
  }

  /// 获取旬空地支
  /// 甲子旬空戌亥, 甲戌旬空申酉, 甲申旬空午未
  /// 甲午旬空辰巳, 甲辰旬空寅卯, 甲寅旬空子丑
  static List<String> getXunKongDiZhi(String dayGz) {
    String xunStart = getXunStart(dayGz);
    if (xunStart.isEmpty) return [];

    return xunKongTable[xunStart] ?? [];
  }

  /// 获取旬空地支字符串（如"戌亥"）
  static String getXunKongStr(String dayGz) {
    List<String> kongList = getXunKongDiZhi(dayGz);
    return kongList.join('');
  }

  /// 判断地支是否旬空
  static bool isXunKong(String zhi, String dayGz) {
    List<String> kongList = getXunKongDiZhi(dayGz);
    return kongList.contains(zhi);
  }

  /// 为六爻标记旬空
  static void assignXunKong(List<YaoLine> yaoLines, String dayGz) {
    List<String> kongList = getXunKongDiZhi(dayGz);

    for (int i = 0; i < yaoLines.length; i++) {
      String? ganZhi = yaoLines[i].ganZhi;
      bool isKong = false;
      if (ganZhi != null && ganZhi.isNotEmpty) {
        isKong = kongList.contains(ganZhi);
      }
      yaoLines[i] = yaoLines[i].copyWith(isXunKong: isKong);
    }
  }

  /// 获取旬名
  static String getXunName(String dayGz) {
    String xunStart = getXunStart(dayGz);
    return xunStart; // 如 "甲子", "甲戌" 等
  }

  /// 六旬列表
  static List<String> getAllXun() {
    return xunStartList;
  }

  /// 获取旬的干支范围
  static List<String> getXunGanZhiList(String xunStart) {
    int idx = ganzhi60.indexOf(xunStart);
    if (idx < 0) return [];

    return ganzhi60.sublist(idx, idx + 10);
  }
}