/// 六亲配置
/// 根据宫五行和爻五行配置六亲
library;

import '../models/yao_line.dart';
import 'constants.dart';

/// 六亲配置器
class LiuQinConfig {
  /// 为六爻配置六亲
  /// 以宫五行为"我"，各爻五行与我的关系确定六亲
  static void assignLiuQin(List<YaoLine> yaoLines, String gongWuXing) {
    // 获取五行关系表
    Map<String, String>? relation = wuXingLiuQin[gongWuXing];
    if (relation == null) return;

    // 为每个爻配置六亲
    for (int i = 0; i < yaoLines.length; i++) {
      String? yaoWuXing = yaoLines[i].wuXing;
      if (yaoWuXing != null && yaoWuXing.isNotEmpty) {
        String liuQin = relation[yaoWuXing] ?? '';
        yaoLines[i] = yaoLines[i].copyWith(liuQin: liuQin);
      }
    }
  }

  /// 为所有爻的变爻配置六亲
  /// 变爻的六亲仍按本宫五行来配（不是变卦所属宫）
  static void assignBianYaoLiuQin(List<YaoLine> yaoLines, String gongWuXing) {
    Map<String, String>? relation = wuXingLiuQin[gongWuXing];
    if (relation == null) return;

    for (int i = 0; i < yaoLines.length; i++) {
      String? bianWuXing = yaoLines[i].bianWuXing;
      if (bianWuXing != null && bianWuXing.isNotEmpty) {
        String bianLiuQin = relation[bianWuXing] ?? '';
        yaoLines[i] = yaoLines[i].copyWith(bianLiuQin: bianLiuQin);
      }
    }
  }

  /// 根据五行获取六亲名称
  static String getLiuQin(String gongWuXing, String yaoWuXing) {
    Map<String, String>? relation = wuXingLiuQin[gongWuXing];
    if (relation == null) return '';
    return relation[yaoWuXing] ?? '';
  }

  /// 获取缺失的六亲
  /// 用于伏神查找
  static Set<String> getMissingLiuQin(List<YaoLine> yaoLines) {
    Set<String> present = yaoLines
        .map((yao) => yao.liuQin ?? '')
        .where((lq) => lq.isNotEmpty)
        .toSet();

    Set<String> all = liuQinList.toSet();
    return all.difference(present);
  }

  /// 检查六亲是否齐全
  static bool hasAllLiuQin(List<YaoLine> yaoLines) {
    return getMissingLiuQin(yaoLines).isEmpty;
  }

  /// 五行生克关系说明
  /// 生我 = 父母, 我生 = 子孙, 同我 = 兄弟, 我克 = 妻财, 克我 = 官鬼
  static String getLiuQinExplanation(String liuQin) {
    const Map<String, String> explanations = {
      '父母': '生我者，代表文书、房屋、长辈、保护',
      '兄弟': '同我者，代表竞争、同类、阻隔、分财',
      '子孙': '我生者，代表福气、下属、医药、技能',
      '妻财': '我克者，代表财物、资源、异性、饮食',
      '官鬼': '克我者，代表工作、疾病、压力、忧患',
    };
    return explanations[liuQin] ?? '';
  }

  /// 获取五行生克关系
  /// 生: 木生火, 火生土, 土生金, 金生水, 水生木
  /// 克: 木克土, 土克水, 水克火, 火克金, 金克木
  static String? getShengRelation(String wuXing) {
    const Map<String, String> shengMap = {
      '金': '水',
      '水': '木',
      '木': '火',
      '火': '土',
      '土': '金',
    };
    return shengMap[wuXing];
  }

  static String? getKeRelation(String wuXing) {
    const Map<String, String> keMap = {
      '金': '木',
      '木': '土',
      '土': '水',
      '水': '火',
      '火': '金',
    };
    return keMap[wuXing];
  }
}