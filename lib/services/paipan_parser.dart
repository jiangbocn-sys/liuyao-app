/// 排盘文字解析器
/// 从OCR识别的文字中解析排盘数据
///
/// 简化识别策略：
/// 1. 只需识别卦名（本卦、变卦）和日柱干支
/// 2. 其他信息（六爻、六亲、六神、神煞等）通过现有算法自动推算
/// 3. 动爻信息可以从图片中识别或手动指定
///
/// OCR容错处理：
/// - "巳"可能被识别为"已"
/// - "问"可能被识别为"间"
/// - 干支格式可能有多种写法

import '../models/image_recognition_result.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 排盘解析器
class PaipanParser {
  // 常量定义
  static const List<String> _diZhi = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'
  ];

  static const List<String> _tianGan = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'
  ];

  // OCR常见误识别映射
  static const Map<String, String> _ocrCorrectionMap = {
    '已': '巳',  // 巳常被识别为已
    '间': '问',  // 问常被识别为间
    '后': '姤',  // 姤常被识别为后
  };

  // 64卦名称（按八宫排列）
  // 八宫系统：每宫8卦，共64卦，无重复
  static const Map<String, int> _guaIndexMap = {
    // 乾宫 (纯乾卦及变卦)
    '乾为天': 1, '天风姤': 2, '天山遁': 3, '天地否': 4,
    '风地观': 5, '山地剥': 6, '火地晋': 7, '火天大有': 8,
    // 坎宫 (纯坎卦及变卦)
    '坎为水': 9, '水泽节': 10, '水雷屯': 11, '水火既济': 12,
    '泽火革': 13, '雷火丰': 14, '地火明夷': 15, '地水师': 16,
    // 艮宫 (纯艮卦及变卦)
    '艮为山': 17, '山火贲': 18, '山天大畜': 19, '山泽损': 20,
    '火泽睽': 21, '天泽履': 22, '风泽中孚': 23, '风山渐': 24,
    // 震宫 (纯震卦及变卦)
    '震为雷': 25, '雷地豫': 26, '雷水解': 27, '雷风恒': 28,
    '地风升': 29, '水风井': 30, '泽风大过': 31, '泽雷随': 32,
    // 巽宫 (纯巽卦及变卦)
    '巽为风': 33, '风天小畜': 34, '风火家人': 35, '风雷益': 36,
    '天雷无妄': 37, '火雷噬嗑': 38, '山雷颐': 39, '山风蛊': 40,
    // 离宫 (纯离卦及变卦)
    '离为火': 41, '火山旅': 42, '火风鼎': 43, '火水未济': 44,
    '山水蒙': 45, '风水涣': 46, '天水讼': 47, '天火同人': 48,
    // 坤宫 (纯坤卦及变卦)
    '坤为地': 49, '地雷复': 50, '地泽临': 51, '地天泰': 52,
    '雷天大壮': 53, '泽天夬': 54, '水天需': 55, '水地比': 56,
    // 兑宫 (纯兑卦及变卦)
    '兑为泽': 57, '泽山咸': 58, '泽地萃': 59, '泽水困': 60,
    '山水蹇': 61, '地山谦': 62, '雷山小过': 63, '雷泽归妹': 64,
    // 简称（常用单字名）
    '乾': 1, '姤': 2, '遁': 3, '否': 4,
    '观': 5, '剥': 6, '晋': 7, '大有': 8,
    '坎': 9, '节': 10, '屯': 11, '既济': 12,
    '革': 13, '丰': 14, '明夷': 15, '师': 16,
    '艮': 17, '贲': 18, '大畜': 19, '损': 20,
    '睽': 21, '履': 22, '中孚': 23, '渐': 24,
    '震': 25, '豫': 26, '解': 27, '恒': 28,
    '升': 29, '井': 30, '大过': 31, '随': 32,
    '巽': 33, '小畜': 34, '家人': 35, '益': 36,
    '无妄': 37, '噬嗑': 38, '颐': 39, '蛊': 40,
    '离': 41, '旅': 42, '鼎': 43, '未济': 44,
    '蒙': 45, '涣': 46, '讼': 47, '同人': 48,
    '坤': 49, '复': 50, '临': 51, '泰': 52,
    '大壮': 53, '夬': 54, '需': 55, '比': 56,
    '兑': 57, '咸': 58, '萃': 59, '困': 60,
    '蹇': 61, '谦': 62, '小过': 63, '归妹': 64,
    // 其他常见写法/异体字
    '天风后': 2, '天山遯': 3, '天地否闭': 4,
    '地雷复卦': 50, '泽天夬卦': 54,
  };

  /// 解析OCR识别的文字
  ///
  /// [rawText] - OCR识别的全部文字
  /// [blocks] - 文字块信息（包含位置）
  ImageRecognitionResult parse(String rawText, List<TextBlock> blocks) {
    try {
      // 首先对OCR文本进行校正
      String correctedText = _correctOcrErrors(rawText);

      // 核心识别字段
      String? yearGanZhi;
      String? monthGanZhi;
      String? dayGanZhi;  // 最重要，用于排纳甲
      String? hourGanZhi;
      String? benGuaName;
      String? bianGuaName;
      List<int>? dongYaoPositions;
      String? gender;
      String? question;

      // ========== 1. 识别干支信息 ==========

      // 格式0: "干支:乙巳年己丑月 乙酉日己卯时" (易青岚排盘格式)
      final ganZhiPattern0 = RegExp(
        r'干支[:：]\s*([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])年'
        r'\s*([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])月\s*'
        r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])日'
        r'\s*([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])时'
      );
      var match = ganZhiPattern0.firstMatch(correctedText);
      if (match != null) {
        yearGanZhi = _correctGanZhi(match.group(1)!);
        monthGanZhi = _correctGanZhi(match.group(2)!);
        dayGanZhi = _correctGanZhi(match.group(3)!);
        hourGanZhi = _correctGanZhi(match.group(4)!);
      }

      // 格式1: "乙巳年 己丑月 乙酉日 己卯时" (空格分隔)
      if (dayGanZhi == null) {
        final ganZhiPattern1 = RegExp(
          r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])年\s*'
          r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])月\s*'
          r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])日\s*'
          r'([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])时'
        );
        match = ganZhiPattern1.firstMatch(correctedText);
        if (match != null) {
          yearGanZhi = _correctGanZhi(match.group(1)!);
          monthGanZhi = _correctGanZhi(match.group(2)!);
          dayGanZhi = _correctGanZhi(match.group(3)!);
          hourGanZhi = _correctGanZhi(match.group(4)!);
        }
      }

      // 格式2: 单独查找干支组合（带年月日时标记）
      if (dayGanZhi == null) {
        // 查找所有干支组合及其位置（包括"已"作为"巳"的误识别）
        final gzPattern = RegExp(r'[甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已]');

        // 查找带标记的干支
        for (final gzMatch in gzPattern.allMatches(correctedText)) {
          final start = gzMatch.start;
          final end = gzMatch.end;
          // 查找前后文字判断是年月日时
          final beforeStart = start > 10 ? start - 10 : 0;
          final afterEnd = end + 10 < correctedText.length ? end + 10 : correctedText.length;
          final context = correctedText.substring(beforeStart, afterEnd);

          final gz = _correctGanZhi(gzMatch.group(0)!);
          if (context.contains('年') && !context.contains('月') && !context.contains('日')) {
            yearGanZhi = gz;
          } else if (context.contains('月') && !context.contains('年') && !context.contains('日')) {
            monthGanZhi = gz;
          } else if (context.contains('日') && !context.contains('月')) {
            dayGanZhi = gz;
          } else if (context.contains('时') && !context.contains('日')) {
            hourGanZhi = gz;
          }
        }
      }

      // 格式3: 查找"日柱"、"日辰"关键字
      if (dayGanZhi == null) {
        final dayPattern = RegExp(r'(日柱|日辰)[:：\s]*([甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已])');
        match = dayPattern.firstMatch(correctedText);
        if (match != null) {
          dayGanZhi = _correctGanZhi(match.group(2)!);
        }
      }

      // ========== 2. 识别卦名 ==========

      // 直接搜索64卦名称（不依赖关键词）
      // 记录找到的所有卦名及其位置
      final foundGuas = <Map<String, dynamic>>[];
      for (final entry in _guaIndexMap.entries) {
        final guaName = entry.key;
        // 在校正后的文本中搜索
        if (correctedText.contains(guaName)) {
          final index = correctedText.indexOf(guaName);
          foundGuas.add({
            'name': guaName,
            'index': index,
            'value': entry.value,
          });
        }
      }

      // 按位置排序，第一个出现的通常是本卦，后面的是变卦
      foundGuas.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

      // 去除简称（如果全称已存在）
      final fullGuaNames = foundGuas.where((g) => (g['name'] as String).length >= 3).toList();
      if (fullGuaNames.isNotEmpty) {
        benGuaName = fullGuaNames.first['name'] as String;
        if (fullGuaNames.length > 1) {
          bianGuaName = fullGuaNames[1]['name'] as String;
        }
      } else if (foundGuas.isNotEmpty) {
        // 如果只有简称
        benGuaName = foundGuas.first['name'] as String;
        if (foundGuas.length > 1) {
          bianGuaName = foundGuas[1]['name'] as String;
        }
      }

      // ========== 3. 识别动爻 ==========

      // 查找动爻标记（○、动、老阳、老阴、X）
      final dongPositions = <int>[];

      // 方法1: 查找"某爻动"的文字
      final dongPattern1 = RegExp(r'([一二三四五六上初])[爻]\s*[动○X]');
      for (final m in dongPattern1.allMatches(correctedText)) {
        final pos = _convertYaoNameToPosition(m.group(1)!);
        if (pos != null && !dongPositions.contains(pos)) {
          dongPositions.add(pos);
        }
      }

      // 方法2: 查找老阳、老阴标记或X符号
      // 从OCR文本中查找X标记（通常表示动爻）

      if (dongPositions.isNotEmpty) {
        dongYaoPositions = dongPositions;
      }

      // ========== 4. 识别公历时间 ==========

      DateTime? gregorianTime;

      // 格式1: "公历：2026年6月27日 14:30"
      final gregPattern1 = RegExp(
        r'公历[:：\s]*(\d{4})年(\d{1,2})月(\d{1,2})日[^\d]*(\d{1,2})[:时点](\d{1,2})?分?'
      );
      match = gregPattern1.firstMatch(correctedText);
      if (match != null) {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
        gregorianTime = DateTime(year, month, day, hour, minute);
      }

      // 格式2: "公历：2026年6月27日"（无时分）
      if (gregorianTime == null) {
        final gregPattern2 = RegExp(r'公历[:：\s]*(\d{4})年(\d{1,2})月(\d{1,2})日');
        match = gregPattern2.firstMatch(correctedText);
        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          gregorianTime = DateTime(year, month, day);
        }
      }

      // 格式3: "2026-06-27 14:30" 或 "2026/6/27 14:30"
      if (gregorianTime == null) {
        final gregPattern3 = RegExp(
          r'(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})日?[^\d]*(\d{1,2})[:时点](\d{1,2})?'
        );
        match = gregPattern3.firstMatch(correctedText);
        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          final hour = int.parse(match.group(4)!);
          final minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
          gregorianTime = DateTime(year, month, day, hour, minute);
        }
      }

      // 格式4: 直接查找年月日时分格式（无"公历"标记）
      if (gregorianTime == null) {
        final gregPattern4 = RegExp(
          r'(\d{4})年(\d{1,2})月(\d{1,2})日[^\d]*(\d{1,2})[:时点](\d{1,2})?[分]?'
        );
        match = gregPattern4.firstMatch(correctedText);
        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          final hour = int.parse(match.group(4)!);
          final minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
          gregorianTime = DateTime(year, month, day, hour, minute);
        }
      }

      // ========== 5. 识别性别和问事 ==========

      // 性别识别 - 多种格式
      // 格式1: "性别：男" 或 "性别：女"
      final genderPattern1 = RegExp(r'性别[:：]\s*(男|女)');
      match = genderPattern1.firstMatch(correctedText);
      if (match != null) {
        gender = match.group(1);
      }

      // 格式2: "男占" 或 "女占"
      if (gender == null) {
        final genderPattern2 = RegExp(r'(男|女)占');
        match = genderPattern2.firstMatch(correctedText);
        if (match != null) {
          gender = match.group(1);
        }
      }

      // 格式3: "占卜人：男" 或 "求测人：女"
      if (gender == null) {
        final genderPattern3 = RegExp(r'(占卜人|求测人|起卦人)[:：]\s*(男|女)');
        match = genderPattern3.firstMatch(correctedText);
        if (match != null) {
          gender = match.group(2);
        }
      }

      // 格式4: 单独的"男"或"女"字（排除卦象中的乾男、坤女）
      if (gender == null) {
        // 查找"男"字，排除乾男
        if (correctedText.contains('男')) {
          final malePattern = RegExp(r'[^\u4e00-\u9fa5]男[^\u4e00-\u9fa5]|^男|男$');
          if (malePattern.hasMatch(correctedText) && !correctedText.contains('乾男')) {
            gender = '男';
          }
        }
        // 查找"女"字，排除坤女
        if (gender == null && correctedText.contains('女')) {
          final femalePattern = RegExp(r'[^\u4e00-\u9fa5]女[^\u4e00-\u9fa5]|^女|女$');
          if (femalePattern.hasMatch(correctedText) && !correctedText.contains('坤女')) {
            gender = '女';
          }
        }
      }

      // 占问内容 - 改进识别（支持多行内容）
      // 策略：从"占问"关键字开始，到"公历"关键字结束，中间所有内容都作为问念

      // 方法1: 使用"公历"作为结束标记
      final gregKeywordIndex = correctedText.indexOf('公历');

      // 查找占问关键字
      final qKeywords = ['占问', '占间', '问事', '求测', '测事'];
      int? qKeywordStart;
      String? qKeywordFound;
      for (final kw in qKeywords) {
        final idx = correctedText.indexOf(kw);
        if (idx != -1) {
          qKeywordStart = idx;
          qKeywordFound = kw;
          break;
        }
      }

      if (qKeywordStart != null && gregKeywordIndex != -1 && qKeywordStart < gregKeywordIndex) {
        // 从占问关键字到公历关键字之间的内容
        final endIndex = gregKeywordIndex;
        final startIndex = qKeywordStart + (qKeywordFound?.length ?? 2);
        // 查找冒号或空格后的位置
        final afterKeyword = correctedText.substring(startIndex, endIndex);
        // 去除开头的冒号和空格
        final contentStart = afterKeyword.indexOfFirstNonDelimiter();
        if (contentStart != -1) {
          question = correctedText.substring(startIndex + contentStart, endIndex).trim();
        } else {
          question = afterKeyword.trim();
        }
      }

      // 方法2: 如果没有公历标记，使用换行作为结束（但允许多行）
      if (question == null && qKeywordStart != null) {
        // 查找占问后的内容，直到遇到明显的分隔标记（如干支、卦名等）
        final startIndex = qKeywordStart + (qKeywordFound?.length ?? 2);
        String afterKeyword = correctedText.substring(startIndex);

        // 去除开头的冒号和空格
        int contentStart = 0;
        while (contentStart < afterKeyword.length &&
               (afterKeyword[contentStart] == ':' ||
                afterKeyword[contentStart] == '：' ||
                afterKeyword[contentStart] == ' ' ||
                afterKeyword[contentStart] == '\t')) {
          contentStart++;
        }

        if (contentStart < afterKeyword.length) {
          afterKeyword = afterKeyword.substring(contentStart);

          // 查找结束位置（遇到干支、卦名等关键字）
          final endMarkers = ['年柱', '月柱', '日柱', '时柱', '干支', '本卦', '变卦'];
          int endPos = afterKeyword.length;
          for (final marker in endMarkers) {
            final idx = afterKeyword.indexOf(marker);
            if (idx != -1 && idx < endPos) {
              endPos = idx;
            }
          }

          // 也查找干支格式作为结束标记
          final gzPattern = RegExp(r'[甲乙丙丁戊己庚辛壬癸][子丑寅卯辰巳午未申酉戌亥已]年');
          final gzMatch = gzPattern.firstMatch(afterKeyword);
          if (gzMatch != null && gzMatch.start < endPos) {
            endPos = gzMatch.start;
          }

          question = afterKeyword.substring(0, endPos).trim();
        }
      }

      // 方法3: 原有的简单正则匹配作为后备
      if (question == null) {
        final qPatternFallback = RegExp(r'(占问|占间|问事|求测|测事)[:：]\s*(.{2,100}?)[\n\r]');
        match = qPatternFallback.firstMatch(correctedText);
        if (match != null) {
          question = match.group(2)?.trim();
        }
      }

      // ========== 6. 识别旬空（日空） ==========

      List<String>? xunKong;
      // 格式: "日空:午、末" 或 "旬空:午、末"
      final xunKongPattern = RegExp(r'(日空|旬空)[:：]\s*([子丑寅卯辰巳午未申酉戌亥、，]+)');
      match = xunKongPattern.firstMatch(correctedText);
      if (match != null) {
        final xunKongText = match.group(2)!;
        // 提取地支
        xunKong = [];
        for (final zhi in _diZhi) {
          if (xunKongText.contains(zhi)) {
            xunKong.add(zhi);
          }
        }
      }

      // ========== 构建结果 ==========

      final data = ParsedDivinationData(
        gender: gender,
        question: question,
        gregorianTime: gregorianTime,
        lunarTime: null,  // 农历时间通常与干支一起标注，暂不识别
        yearGanZhi: yearGanZhi,
        monthGanZhi: monthGanZhi,
        dayGanZhi: dayGanZhi,
        hourGanZhi: hourGanZhi,
        benGuaName: benGuaName,
        bianGuaName: bianGuaName,
        dongYaoPositions: dongYaoPositions,
        // 旬空从OCR识别，如果没有识别到则由算法计算
        xunKong: xunKong,
        // 六爻数据将由校正计算自动生成
        liuShen: null,  // 将由LiuShenConfig根据日干计算
        liuQin: null,   // 将由LiuQinConfig根据卦宫五行和地支计算
        diZhi: null,    // 将由NajiaConfig根据卦和爻位计算
        shiPosition: null,  // 将由ShiYingConfig根据卦计算
        yingPosition: null, // 将由ShiYingConfig根据卦计算
        shenSha: null,      // 将由ShenshaCalculator根据干支计算
      );

      // 计算置信度（基于核心字段是否识别成功）
      final coreFields = [
        dayGanZhi != null,
        benGuaName != null,
        gregorianTime != null,
        question != null,
        gender != null,
      ];
      final filledCount = coreFields.where((v) => v).length;
      final confidence = filledCount / coreFields.length;

      // 检查缺失的核心字段
      final missingFields = <String>[];
      if (dayGanZhi == null) missingFields.add('日柱干支');
      if (benGuaName == null) missingFields.add('本卦卦名');
      if (gregorianTime == null) missingFields.add('公历时间');
      if (question == null) missingFields.add('占问内容');
      if (gender == null) missingFields.add('性别');

      return ImageRecognitionResult.success(
        data: data,
        rawText: rawText,
        confidence: confidence,
        needsConfirmation: missingFields.isNotEmpty ? missingFields : null,
      );

    } catch (e) {
      return ImageRecognitionResult.failure('解析失败: $e');
    }
  }

  /// 将爻名称转换为位置数字
  int? _convertYaoNameToPosition(String name) {
    switch (name) {
      case '初':
        return 1;
      case '一':
        return 1;
      case '二':
        return 2;
      case '三':
        return 3;
      case '四':
        return 4;
      case '五':
        return 5;
      case '六':
        return 6;
      case '上':
        return 6;
      default:
        return null;
    }
  }

  /// 获取所有支持的卦名列表（用于显示）
  static List<String> getSupportedGuaNames() {
    return _guaIndexMap.keys.toList();
  }

  /// 校正OCR常见误识别
  String _correctOcrErrors(String text) {
    String corrected = text;
    for (final entry in _ocrCorrectionMap.entries) {
      corrected = corrected.replaceAll(entry.key, entry.value);
    }
    return corrected;
  }

  /// 校正单个干支中的误识别（如"已"→"巳")
  String _correctGanZhi(String ganZhi) {
    if (ganZhi.length != 2) return ganZhi;
    final gan = ganZhi[0];
    final zhi = ganZhi[1];
    // 校正地支中的误识别（已→巳）
    if (zhi == '已') return '$gan巳';
    return ganZhi;
  }
}

/// String扩展方法
extension StringExtension on String {
  /// 查找第一个非分隔符字符的索引
  /// 分隔符包括：冒号（中英文）、空格、制表符
  int indexOfFirstNonDelimiter() {
    for (int i = 0; i < length; i++) {
      final char = this[i];
      if (char != ':' && char != '：' && char != ' ' && char != '\t') {
        return i;
      }
    }
    return -1;  // 全部都是分隔符
  }
}