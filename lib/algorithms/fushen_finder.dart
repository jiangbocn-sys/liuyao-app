/// 伏神查找器
/// 当卦中缺少某一六亲时，在本宫八纯卦中查找伏神
library;

import '../models/yao_line.dart';
import 'liuqin_config.dart';
import 'najia_config.dart';
import 'constants.dart';

/// 伏神查找器
class FuShenFinder {
  /// 为六爻查找伏神
  /// 当卦中六亲不齐全时，在本宫八纯卦中查找缺失六亲对应的爻
  static void findFuShen(List<YaoLine> yaoLines, int gongNum, String gongWuXing) {
    // 获取缺失的六亲
    Set<String> missing = LiuQinConfig.getMissingLiuQin(yaoLines);
    if (missing.isEmpty) return;

    // 获取本宫八纯卦的爻数据
    int chunGuaId = gongNum + 1;
    List<String> chunDiZhi = baGuaDiZhi[chunGuaId] ?? [];

    // 为八纯卦的每个爻计算六亲
    Map<int, String> chunLiuQin = {};
    for (int i = 0; i < 6; i++) {
      String zhi = chunDiZhi[i];
      String wuXing = diZhiWuXing[zhi] ?? '';
      String liuQin = LiuQinConfig.getLiuQin(gongWuXing, wuXing);
      chunLiuQin[i] = liuQin;
    }

    // 对于每个缺失的六亲，找到八纯卦中第一个匹配的爻
    for (String missLiuQin in missing) {
      for (int i = 0; i < 6; i++) {
        if (chunLiuQin[i] == missLiuQin) {
          // 该地支为伏神，伏于本卦对应爻位下
          // 本卦该爻为飞神
          String fuZhi = chunDiZhi[i];

          // 检查是否已有伏神（可能多个六亲缺失，伏于同一爻）
          if (yaoLines[i].fuShen == null || yaoLines[i].fuShen!.isEmpty) {
            yaoLines[i] = yaoLines[i].copyWith(
              fuShen: fuZhi,
              feiShen: yaoLines[i].ganZhi ?? '',
            );
          }
          break; // 找到第一个匹配即可
        }
      }
    }
  }

  /// 获取伏神五行
  static String getFuShenWuXing(String fuZhi) {
    return diZhiWuXing[fuZhi] ?? '';
  }

  /// 获取伏神六亲
  static String getFuShenLiuQin(String fuZhi, String gongWuXing) {
    String fuWuXing = diZhiWuXing[fuZhi] ?? '';
    return LiuQinConfig.getLiuQin(gongWuXing, fuWuXing);
  }

  /// 分析伏神与飞神的关系
  /// 飞来生伏、飞来克伏、伏去生飞、伏去克飞、飞伏比和
  static String analyzeFuShenRelation(String feiShen, String fuShen) {
    String feiWuXing = diZhiWuXing[feiShen] ?? '';
    String fuWuXing = diZhiWuXing[fuShen] ?? '';

    if (feiWuXing.isEmpty || fuWuXing.isEmpty) return '';

    // 五行生克关系
    // 飞生伏：飞神五行生伏神五行
    // 飞克伏：飞神五行克伏神五行
    // 伏生飞：伏神五行生飞神五行
    // 伏克飞：伏神五行克飞神五行
    // 比和：飞伏五行相同

    if (feiWuXing == fuWuXing) return '飞伏比和';

    // 检查飞是否生伏
    if (_isSheng(feiWuXing, fuWuXing)) return '飞来生伏';
    // 检查飞是否克伏
    if (_isKe(feiWuXing, fuWuXing)) return '飞来克伏';
    // 检查伏是否生飞
    if (_isSheng(fuWuXing, feiWuXing)) return '伏去生飞';
    // 检查伏是否克飞
    if (_isKe(fuWuXing, feiWuXing)) return '伏去克飞';

    return '';
  }

  /// 判断五行相生
  static bool _isSheng(String wuXing1, String wuXing2) {
    // 金生水, 水生木, 木生火, 火生土, 土生金
    const Map<String, String> shengMap = {
      '金': '水',
      '水': '木',
      '木': '火',
      '火': '土',
      '土': '金',
    };
    return shengMap[wuXing1] == wuXing2;
  }

  /// 判断五行相克
  static bool _isKe(String wuXing1, String wuXing2) {
    // 金克木, 木克土, 土克水, 水克火, 火克金
    const Map<String, String> keMap = {
      '金': '木',
      '木': '土',
      '土': '水',
      '水': '火',
      '火': '金',
    };
    return keMap[wuXing1] == wuXing2;
  }
}