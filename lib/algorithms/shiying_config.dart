/// 世应定位配置
/// 根据卦在宫中的位置确定世爻和应爻
library;

import '../models/gua_info.dart';
import '../models/yao_line.dart';
import 'constants.dart';

/// 世应配置器
class ShiYingConfig {
  /// 计算卦在宫中的位置（0-7）
  /// 0=八纯卦, 1=一世卦, 2=二世卦, 3=三世卦
  /// 4=四世卦, 5=五世卦, 6=游魂卦, 7=归魂卦
  static int getGuaPositionInGong(GuaInfo benGua, int gongNum) {
    // 八纯卦判定
    int chunIdx = chunGuaIdx[gongNum] ?? -1;
    if (benGua.gua64Index == chunIdx) return 0;

    // 获取八纯卦内外卦编号
    int chunGuaId = gongNum + 1;

    // 计算与八纯卦的爻差异
    int innerDiff = _countYaoDiff(benGua.innerGuaId, chunGuaId);
    int outerDiff = _countYaoDiff(benGua.outerGuaId, chunGuaId);

    // 总变爻数
    int totalDiff = innerDiff + outerDiff;

    // 分宫规律：
    // 八纯卦(0): 世爻6, 应爻3
    // 一世卦(1): 内卦初爻变 → 世爻1, 应爻4
    // 二世卦(2): 内卦二爻变 → 世爻2, 应爻5
    // 三世卦(3): 内卦三爻变 → 世爻3, 应爻6
    // 四世卦(4): 外卦初爻变 → 世爻4, 应爻1
    // 五世卦(5): 外卦二爻变 → 世爻5, 应爻2
    // 游魂卦(6): 外卦三爻变+内卦变回 → 世爻4, 应爻1
    // 归魂卦(7): 外卦变回+内卦全变回 → 世爻3, 应爻6

    // 简化算法：根据内外卦差异判定位置
    if (outerDiff == 0) {
      // 外卦不变，只有内卦变
      return innerDiff; // 一世到三世
    } else if (innerDiff == 0) {
      // 内卦不变，只有外卦变
      if (outerDiff <= 3) {
        return outerDiff + 3; // 四世到五世+游魂
      }
    }

    // 游魂卦：外卦三爻变，内卦变化
    // 归魂卦：外卦变回，内卦全变回

    // 特殊情况判定
    // 游魂卦特点：外卦变了，但世爻在四爻
    // 归魂卦特点：内卦回到原样，世爻在三爻

    // 检查是否归魂卦：内卦与八纯卦相同，外卦不同
    if (innerDiff == 0 && outerDiff > 0) {
      return 7; // 归魂卦
    }

    // 检查是否游魂卦
    if (outerDiff == 3 && innerDiff > 0 && innerDiff < 3) {
      return 6; // 游魂卦
    }

    // 默认返回（可能需要更精确的判定）
    return totalDiff % 8;
  }

  /// 计算两个八卦之间的爻差异
  static int _countYaoDiff(int gua1, int gua2) {
    List<bool> yao1 = _guaToYao(gua1);
    List<bool> yao2 = _guaToYao(gua2);

    int diff = 0;
    for (int i = 0; i < 3; i++) {
      if (yao1[i] != yao2[i]) diff++;
    }
    return diff;
  }

  /// 八卦编号转为三爻
  static List<bool> _guaToYao(int guaId) {
    int code;
    switch (guaId) {
      case 1: code = 7; break;  // 乾 111
      case 2: code = 3; break;  // 兑 011
      case 3: code = 5; break;  // 离 101
      case 4: code = 1; break;  // 震 001
      case 5: code = 6; break;  // 巽 110
      case 6: code = 2; break;  // 坎 010
      case 7: code = 4; break;  // 艮 100
      case 8: code = 0; break;  // 坤 000
      default: code = 0;
    }

    return [
      (code & 1) == 1,  // 初爻
      (code & 2) == 2,  // 二爻
      (code & 4) == 4,  // 三爻
    ];
  }

  /// 为六爻配置世应位置
  static void assignShiYing(List<YaoLine> yaoLines, GuaInfo benGua, int gongNum) {
    // 先清除所有世应标记
    for (int i = 0; i < yaoLines.length; i++) {
      yaoLines[i] = yaoLines[i].copyWith(isShi: false, isYing: false);
    }

    // 获取卦在宫中的位置
    int position = getGuaPositionInGong(benGua, gongNum);

    // 获取世应位置
    var (shiPos, yingPos) = getShiYingPos(position);

    // 标记世应
    yaoLines[shiPos - 1] = yaoLines[shiPos - 1].copyWith(isShi: true);
    yaoLines[yingPos - 1] = yaoLines[yingPos - 1].copyWith(isYing: true);
  }

  /// 获取世爻位置说明
  static String getShiYaoExplanation(int position) {
    const Map<int, String> explanations = {
      0: '八纯卦：世爻在六爻，应爻在三爻',
      1: '一世卦：世爻在初爻，应爻在四爻',
      2: '二世卦：世爻在二爻，应爻在五爻',
      3: '三世卦：世爻在三爻，应爻在六爻',
      4: '四世卦：世爻在四爻，应爻在初爻',
      5: '五世卦：世爻在五爻，应爻在二爻',
      6: '游魂卦：世爻在四爻，应爻在初爻',
      7: '归魂卦：世爻在三爻，应爻在六爻',
    };
    return explanations[position] ?? '';
  }

  /// 获取卦位名称
  static String getPositionName(int position) {
    const Map<int, String> names = {
      0: '八纯卦',
      1: '一世卦',
      2: '二世卦',
      3: '三世卦',
      4: '四世卦',
      5: '五世卦',
      6: '游魂卦',
      7: '归魂卦',
    };
    return names[position] ?? '';
  }
}