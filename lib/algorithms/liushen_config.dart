/// 六神配置
/// 根据日干配置六神
library;

import '../models/yao_line.dart';
import 'constants.dart';

/// 六神配置器
class LiuShenConfig {
  /// 为六爻配置六神
  /// 按日干确定初爻起神，自下而上顺序排列
  static void assignLiuShen(List<YaoLine> yaoLines, String dayGan) {
    // 获取日干对应的六神起点索引
    int startIndex = dayGanLiuShenStart[dayGan] ?? 0;

    // 初爻→上爻：从 startIndex 开始按 liuShenList 顺序排列
    for (int i = 0; i < 6; i++) {
      int idx = (startIndex + i) % 6;
      String liuShen = liuShenList[idx];
      yaoLines[i] = yaoLines[i].copyWith(liuShen: liuShen);
    }
  }

  /// 获取日干对应的六神起点
  static String getStartLiuShen(String dayGan) {
    int startIndex = dayGanLiuShenStart[dayGan] ?? 0;
    return liuShenList[startIndex];
  }

  /// 获取指定爻位的六神
  static String getYaoLiuShen(String dayGan, int yaoPosition) {
    int startIndex = dayGanLiuShenStart[dayGan] ?? 0;
    int idx = (startIndex + yaoPosition - 1) % 6;
    return liuShenList[idx];
  }

  /// 六神含义说明
  static String getLiuShenExplanation(String liuShen) {
    const Map<String, String> explanations = {
      '青龙': '喜庆、贵助、体面、仁慈',
      '朱雀': '口舌、文书、争论、消息',
      '勾陈': '拖延、田产、牢狱、固执',
      '螣蛇': '疑虑、惊吓、虚惊、怪异',
      '白虎': '血光、疾病、压力、风险',
      '玄武': '欺瞒、隐情、暧昧、盗贼',
    };
    return explanations[liuShen] ?? '';
  }

  /// 六神五行属性
  static String getLiuShenWuXing(String liuShen) {
    const Map<String, String> wuXingMap = {
      '青龙': '木',
      '朱雀': '火',
      '勾陈': '土',
      '螣蛇': '土',
      '白虎': '金',
      '玄武': '水',
    };
    return wuXingMap[liuShen] ?? '';
  }
}