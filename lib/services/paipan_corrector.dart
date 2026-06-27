/// 排盘校正服务
/// 从OCR识别结果校正计算，生成完整排盘数据

import '../models/divination_record.dart';
import '../models/gua_info.dart';
import '../models/image_recognition_result.dart';
import '../models/shensha_result.dart';
import '../models/yao_line.dart';
import '../algorithms/constants.dart';
import '../algorithms/najia_config.dart';
import '../algorithms/liuqin_config.dart';
import '../algorithms/liushen_config.dart';
import '../algorithms/xunkong_calculator.dart';
import '../algorithms/shiying_config.dart';
import '../algorithms/shensha_calculator.dart';
import '../algorithms/fushen_finder.dart';

/// 排盘校正器
class PaipanCorrector {
  /// 从卦名获取卦信息
  static GuaInfo? getGuaInfoFromName(String guaName) {
    // 查找卦名在64卦列表中的索引
    int gua64Index = gua64Names.indexOf(guaName);
    if (gua64Index == -1) return null;

    // 计算内外卦编号
    int innerGuaId = (gua64Index / 8).floor() + 1;
    int outerGuaId = (gua64Index % 8) + 1;

    return GuaInfo.fromInnerOuter(innerGuaId, outerGuaId);
  }

  /// 从本卦和变卦推算动爻位置
  /// 比较两卦的阴阳差异，找出变化的爻位
  static List<int> calculateDongYaoPositions(GuaInfo benGua, GuaInfo? bianGua) {
    if (bianGua == null) return [];

    // 八卦编号转为三爻阴阳
    List<bool> benInner = _guaToYao(benGua.innerGuaId);
    List<bool> benOuter = _guaToYao(benGua.outerGuaId);
    List<bool> bianInner = _guaToYao(bianGua.innerGuaId);
    List<bool> bianOuter = _guaToYao(bianGua.outerGuaId);

    List<int> dongPositions = [];

    // 比较内卦（初爻、二爻、三爻）
    for (int i = 0; i < 3; i++) {
      if (benInner[i] != bianInner[i]) {
        dongPositions.add(i + 1);
      }
    }

    // 比较外卦（四爻、五爻、上爻）
    for (int i = 0; i < 3; i++) {
      if (benOuter[i] != bianOuter[i]) {
        dongPositions.add(i + 4);
      }
    }

    return dongPositions;
  }

  /// 八卦编号转为三爻阴阳（从下到上）
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

  /// 校正并生成完整排盘数据
  static DivinationRecord? correctAndGenerate(ParsedDivinationData ocrData) {
    // 验证必要字段
    if (ocrData.benGuaName == null || ocrData.dayGanZhi == null) {
      return null;
    }

    // 获取本卦和变卦信息
    GuaInfo? benGua = getGuaInfoFromName(ocrData.benGuaName!);
    if (benGua == null) return null;

    GuaInfo? bianGua = null;
    if (ocrData.bianGuaName != null) {
      bianGua = getGuaInfoFromName(ocrData.bianGuaName!);
    }

    // 推算动爻位置（如果没有OCR识别到）
    List<int> dongPositions = ocrData.dongYaoPositions ?? [];
    if (dongPositions.isEmpty && bianGua != null) {
      dongPositions = calculateDongYaoPositions(benGua, bianGua);
    }

    // 创建六爻数据
    List<YaoLine> yaoLines = _createYaoLinesFromGua(benGua, dongPositions);

    // 纳甲装卦（为各爻分配地支）
    NajiaConfig.assignDiZhi(yaoLines, benGua.innerGuaId, benGua.outerGuaId);

    // 为动爻的变爻分配地支（如有变卦）
    if (bianGua != null) {
      NajiaConfig.assignBianYaoDiZhi(yaoLines, bianGua.innerGuaId, bianGua.outerGuaId);
    }

    // 六亲配置
    String gongWuXing = benGua.guaWuXing ?? '';
    LiuQinConfig.assignLiuQin(yaoLines, gongWuXing);

    // 为变爻配置六亲
    if (bianGua != null) {
      LiuQinConfig.assignBianYaoLiuQin(yaoLines, gongWuXing);
    }

    // 六神配置（根据日干）
    String dayGan = ocrData.dayGanZhi![0];
    LiuShenConfig.assignLiuShen(yaoLines, dayGan);

    // 旬空判断（识别+验证校正）
    XunKongCalculator.assignXunKong(yaoLines, ocrData.dayGanZhi!);

    // 用算法计算正确的旬空
    String calculatedXunKong = XunKongCalculator.getXunKongStr(ocrData.dayGanZhi!);

    // OCR识别的旬空（用于对比验证）
    String? ocrXunKong = ocrData.xunKong?.join('');

    // 校正逻辑：优先使用算法计算结果，OCR识别值作为参考
    // 如果OCR识别值与计算值不同，说明可能有识别错误，使用算法值校正
    String xunKong = calculatedXunKong;
    if (ocrXunKong != null && ocrXunKong.isNotEmpty && ocrXunKong != calculatedXunKong) {
      // OCR识别值与算法值不同，使用算法值校正
      // 可选：记录差异供用户确认
      print('旬空校正: OCR识别=$ocrXunKong, 算法计算=$calculatedXunKong, 使用算法值');
    }

    // 世应定位
    int gongNum = benGua.gongNum ?? 0;
    ShiYingConfig.assignShiYing(yaoLines, benGua, gongNum);

    // 伏神查找（根据宫位和五行）
    FuShenFinder.findFuShen(yaoLines, gongNum, gongWuXing);

    // 神煞计算
    String dayZhi = ocrData.dayGanZhi![1];
    String? yearZhi = ocrData.yearGanZhi?[1];
    String? monthZhi = ocrData.monthGanZhi?[1];

    ShenshaResult shensha = ShenShaCalculator.calculate(
      dayGan: dayGan,
      dayZhi: dayZhi,
      yearZhi: yearZhi ?? '',
      monthZhi: monthZhi ?? '',
    );

    // 生成互卦
    GuaInfo? huGua = _generateHuGua(yaoLines);

    // 组装完整记录
    return DivinationRecord(
      createdAt: DateTime.now(),
      divTime: ocrData.gregorianTime ?? DateTime.now(),
      question: ocrData.question ?? '',
      startMethod: 'image_import',
      querentName: '',
      querentGender: ocrData.gender ?? '',
      yearGz: ocrData.yearGanZhi ?? '',
      monthGz: ocrData.monthGanZhi ?? '',
      dayGz: ocrData.dayGanZhi ?? '',
      hourGz: ocrData.hourGanZhi ?? '',
      xunKong: xunKong,
      benGua: benGua,
      bianGua: bianGua,
      huGua: huGua,
      backCounts: [],  // 图像导入无背面数
      yaoLines: yaoLines,
      shensha: shensha,
    );
  }

  /// 从卦信息创建六爻数据
  static List<YaoLine> _createYaoLinesFromGua(GuaInfo benGua, List<int> dongPositions) {
    // 内卦三爻
    List<bool> innerYao = _guaToYao(benGua.innerGuaId);
    // 外卦三爻
    List<bool> outerYao = _guaToYao(benGua.outerGuaId);

    // 组合六爻（从下到上）
    List<bool> allYao = [
      innerYao[0], // 初爻
      innerYao[1], // 二爻
      innerYao[2], // 三爻
      outerYao[0], // 四爻
      outerYao[1], // 五爻
      outerYao[2], // 上爻
    ];

    // 创建YaoLine列表
    List<YaoLine> yaoLines = [];
    for (int i = 0; i < 6; i++) {
      bool isYang = allYao[i];
      bool isDong = dongPositions.contains(i + 1);

      YaoType yaoType;
      int backCount;
      if (isDong) {
        if (isYang) {
          yaoType = YaoType.laoYang;
          backCount = 3;  // 老阳 = 3背
        } else {
          yaoType = YaoType.laoYin;
          backCount = 0;  // 老阴 = 0背
        }
      } else {
        if (isYang) {
          yaoType = YaoType.shaoYang;
          backCount = 1;  // 少阳 = 1背
        } else {
          yaoType = YaoType.shaoYin;
          backCount = 2;  // 少阴 = 2背
        }
      }

      yaoLines.add(YaoLine(
        position: i + 1,
        backCount: backCount,
        yaoType: yaoType,
        isYang: isYang,
        isDong: isDong,
      ));
    }

    return yaoLines;
  }

  /// 生成互卦
  static GuaInfo? _generateHuGua(List<YaoLine> yaoLines) {
    // 互卦：二三四爻为下卦，三四五爻为上卦
    int innerId = _getYaoId(yaoLines[1].isYang, yaoLines[2].isYang, yaoLines[3].isYang);
    int outerId = _getYaoId(yaoLines[2].isYang, yaoLines[3].isYang, yaoLines[4].isYang);
    return GuaInfo.fromInnerOuter(innerId, outerId);
  }

  /// 从三爻阴阳计算八卦编号
  static int _getYaoId(bool yao1, bool yao2, bool yao3) {
    int code = (yao1 ? 1 : 0) + (yao2 ? 2 : 0) + (yao3 ? 4 : 0);

    const Map<int, int> codeToId = {
      0: 8, // 坤
      1: 4, // 震
      2: 6, // 坎
      3: 2, // 兑
      4: 7, // 艮
      5: 3, // 离
      6: 5, // 巽
      7: 1, // 乾
    };
    return codeToId[code] ?? 1;
  }
}