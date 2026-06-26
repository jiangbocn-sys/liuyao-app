/// 卦生成器
/// 根据六爻阴阳生成本卦、变卦、互卦
library;

import '../models/gua_info.dart';
import '../models/yao_line.dart';
import 'constants.dart';

/// 卦生成器类
class GuaGenerator {
  /// 从六爻数据生成本卦信息
  static GuaInfo generateBenGua(List<YaoLine> yaoLines) {
    // 下卦（内卦）：初爻、二爻、三爻
    int innerId = getBaGuaId(
      yaoLines[0].isYang,
      yaoLines[1].isYang,
      yaoLines[2].isYang,
    );

    // 上卦（外卦）：四爻、五爻、上爻
    int outerId = getBaGuaId(
      yaoLines[3].isYang,
      yaoLines[4].isYang,
      yaoLines[5].isYang,
    );

    return GuaInfo.fromInnerOuter(innerId, outerId);
  }

  /// 从六爻数据生成变卦信息
  /// 动爻阴阳互换
  static GuaInfo? generateBianGua(List<YaoLine> yaoLines) {
    // 检查是否有动爻
    bool hasDong = yaoLines.any((yao) => yao.isDong);
    if (!hasDong) return null;

    // 动爻阴阳互换
    List<bool> bianYangs = yaoLines
        .map((yao) => yao.isDong ? !yao.isYang : yao.isYang)
        .toList();

    // 下卦
    int innerId = getBaGuaId(bianYangs[0], bianYangs[1], bianYangs[2]);
    // 上卦
    int outerId = getBaGuaId(bianYangs[3], bianYangs[4], bianYangs[5]);

    return GuaInfo.fromInnerOuter(innerId, outerId);
  }

  /// 从六爻数据生成互卦信息
  /// 互卦：本卦的二三四爻为下卦，三四五爻为上卦
  static GuaInfo? generateHuGua(List<YaoLine> yaoLines) {
    // 下卦：二爻、三爻、四爻
    int innerId = getBaGuaId(
      yaoLines[1].isYang,
      yaoLines[2].isYang,
      yaoLines[3].isYang,
    );

    // 上卦：三爻、四爻、五爻
    int outerId = getBaGuaId(
      yaoLines[2].isYang,
      yaoLines[3].isYang,
      yaoLines[4].isYang,
    );

    return GuaInfo.fromInnerOuter(innerId, outerId);
  }

  /// 从背面数列表生成完整的卦象结果
  /// 返回：本卦、变卦、互卦信息
  static ({GuaInfo benGua, GuaInfo? bianGua, GuaInfo? huGua}) generateFromBackCounts(List<int> backCounts) {
    // 先创建六爻数据
    List<YaoLine> yaoLines = backCounts
        .asMap()
        .entries
        .map((e) => YaoLine.fromBackCount(e.key + 1, e.value))
        .toList();

    GuaInfo benGua = generateBenGua(yaoLines);
    GuaInfo? bianGua = generateBianGua(yaoLines);
    GuaInfo? huGua = generateHuGua(yaoLines);

    return (benGua: benGua, bianGua: bianGua, huGua: huGua);
  }

  /// 获取八卦编号
  /// 阳爻=1, 阴爻=0, 从下往上排列
  /// code: 000=坤(8), 001=震(4), 010=坎(6), 011=兑(2)
  ///       100=艮(7), 101=离(3), 110=巽(5), 111=乾(1)
  static int getBaGuaIdFromCode(int code) {
    const Map<int, int> codeToId = {
      0: 8, // 坤 ▅▅ ▅▅ ▅▅ ▅▅ ▅▅ ▅▅
      1: 4, // 震 ▅▅ ▅▅ ▅▅ ▅▅ ▅▅▅▅▅
      2: 6, // 坎 ▅▅ ▅▅ ▅▅▅▅▅ ▅▅ ▅▅
      3: 2, // 兑 ▅▅ ▅▅ ▅▅▅▅▅ ▅▅▅▅▅
      4: 7, // 艮 ▅▅▅▅▅ ▅▅ ▅▅ ▅▅ ▅▅
      5: 3, // 离 ▅▅▅▅▅ ▅▅ ▅▅ ▅▅▅▅▅
      6: 5, // 巽 ▅▅▅▅▅ ▅▅▅▅▅ ▅▅ ▅▅
      7: 1, // 乾 ▅▅▅▅▅ ▅▅▅▅▅ ▅▅▅▅▅
    };
    return codeToId[code] ?? 1;
  }

  /// 计算卦在宫中的位置（0-7）
  /// 用于确定世应位置
  /// 0=八纯卦, 1=一世卦, 2=二世卦, 3=三世卦
  /// 4=四世卦, 5=五世卦, 6=游魂卦, 7=归魂卦
  static int getGuaPositionInGong(int gua64Index, int gongNum) {
    // 查找该卦在宫中的位置
    // 八纯卦在宫的第一个位置
    // 其他卦需要根据变爻规律判断

    // 简化实现：根据卦64序号和宫号的关系判断
    // 这需要完整的六十四卦分宫顺序表

    // 八纯卦的索引
    int chunIdx = chunGuaIdx[gongNum] ?? 0;
    if (gua64Index == chunIdx) return 0; // 八纯卦

    // 对于其他卦，需要查分宫表
    // 这里用简化算法：根据卦与八纯卦的爻差异判断
    // 具体实现需要完整的分宫顺序数据

    // 临时返回：需要完善
    return _calculatePositionFromGua(gua64Index, gongNum);
  }

  /// 根据卦象与八纯卦的差异计算宫中位置
  static int _calculatePositionFromGua(int gua64Index, int gongNum) {
    // 获取八纯卦的内外卦编号
    // 乾宫：乾为天 (乾=1)
    // 兑宫：兑为泽 (兑=2)
    // 离宫：离为火 (离=3)
    // 震宫：震为雷 (震=4)
    // 巽宫：巽为风 (巽=5)
    // 坎宫：坎为水 (坎=6)
    // 艮宫：艮为山 (艮=7)
    // 坤宫：坤为地 (坤=8)

    int outerGuaId = (gua64Index ~/ 8) + 1;
    int innerGuaId = (gua64Index % 8) + 1;

    // 八纯卦内外卦相同
    int chunGuaId = gongNum + 1; // 宫0→乾1, 宫1→兑2...

    // 计算爻差异
    int diff = 0;

    // 内卦差异
    if (innerGuaId != chunGuaId) {
      // 内卦变化，计算变爻数
      diff += _countYaoDiff(innerGuaId, chunGuaId);
    }

    // 外卦差异
    if (outerGuaId != chunGuaId) {
      // 外卦变化，计算变爻数
      diff += _countYaoDiff(outerGuaId, chunGuaId);
    }

    // 游魂卦和归魂卦特殊处理
    // 游魂卦：外卦变，内卦三爻变回原样
    // 归魂卦：外卦变，内卦全变回原样

    // 简化返回
    if (diff == 0) return 0; // 八纯卦
    if (diff <= 5) return diff; // 一世到五世
    if (diff == 6) {
      // 检查是否游魂或归魂
      // 游魂卦：上爻不变，下卦三爻变（外卦变+内卦三爻）
      // 归魂卦：外卦变回原样，内卦全变回原样
      return 6; // 临时返回游魂
    }

    return diff % 8;
  }

  /// 计算两个八卦之间的爻差异
  static int _countYaoDiff(int gua1, int gua2) {
    // 将八卦转为三爻二进制
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
    // 编码：坤(8)=000, 震(4)=001, 坎(6)=010, 兑(2)=011
    //       艮(7)=100, 离(3)=101, 巽(5)=110, 乾(1)=111
    int code;
    switch (guaId) {
      case 1: code = 7; break;  // 乾
      case 2: code = 3; break;  // 兑
      case 3: code = 5; break;  // 离
      case 4: code = 1; break;  // 震
      case 5: code = 6; break;  // 巽
      case 6: code = 2; break;  // 坎
      case 7: code = 4; break;  // 艮
      case 8: code = 0; break;  // 坤
      default: code = 0;
    }

    return [
      (code & 1) == 1,  // 初爻
      (code & 2) == 2,  // 二爻
      (code & 4) == 4,  // 三爻
    ];
  }
}