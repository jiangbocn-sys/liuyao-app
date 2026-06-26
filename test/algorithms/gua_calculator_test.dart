import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_app/models/divination_record.dart';
import 'package:liuyao_app/algorithms/gua_calculator.dart';
import 'package:liuyao_app/algorithms/constants.dart';

void main() {
  group('完整排盘测试', () {
    test('乾为天完整排盘', () {
      // 全部少阳 → 乾为天
      var backCounts = [1, 1, 1, 1, 1, 1];
      var dt = DateTime(2026, 6, 25, 21, 45);

      var record = GuaCalculator.calculate(
        backCounts: backCounts,
        divTime: dt,
        question: '测试乾卦',
      );

      // 验证基本信息
      expect(record.question, '测试乾卦');
      expect(record.startMethod, 'manual');

      // 验证本卦
      expect(record.benGua.guaName, '乾为天');
      expect(record.benGua.gongNum, 0); // 乾宫
      expect(record.benGua.guaWuXing, '金');

      // 验证无变卦（无动爻）
      expect(record.bianGua, null);

      // 验证六爻
      expect(record.yaoLines.length, 6);

      // 验证纳甲（乾卦地支）
      // 乾卦纳支：子寅辰午申戌（从下往上）
      expect(record.yaoLines[0].ganZhi, '子'); // 初爻
      expect(record.yaoLines[1].ganZhi, '寅'); // 二爻
      expect(record.yaoLines[2].ganZhi, '辰'); // 三爻
      expect(record.yaoLines[3].ganZhi, '午'); // 四爻
      expect(record.yaoLines[4].ganZhi, '申'); // 五爻
      expect(record.yaoLines[5].ganZhi, '戌'); // 上爻

      // 验证五行
      expect(record.yaoLines[0].wuXing, '水'); // 子水
      expect(record.yaoLines[1].wuXing, '木'); // 寅木
      expect(record.yaoLines[2].wuXing, '土'); // 辰土
      expect(record.yaoLines[3].wuXing, '火'); // 午火
      expect(record.yaoLines[4].wuXing, '金'); // 申金
      expect(record.yaoLines[5].wuXing, '土'); // 戌土

      // 验证六亲（乾宫属金）
      // 金为"我"
      // 子水 → 金生水 → 子孙
      // 寅木 → 金克木 → 妻财
      // 辰土 → 土生金 → 父母
      // 午火 → 火克金 → 官鬼
      // 申金 → 同我 → 兄弟
      // 戌土 → 土生金 → 父母
      expect(record.yaoLines[0].liuQin, '子孙');
      expect(record.yaoLines[1].liuQin, '妻财');
      expect(record.yaoLines[2].liuQin, '父母');
      expect(record.yaoLines[3].liuQin, '官鬼');
      expect(record.yaoLines[4].liuQin, '兄弟');
      expect(record.yaoLines[5].liuQin, '父母');

      // 验证六亲齐全（乾卦六亲全）
      expect(record.yaoLines.every((y) => y.liuQin?.isNotEmpty == true), true);

      // 验证无伏神（六亲齐全）
      expect(record.yaoLines.every((y) => y.fuShen == null), true);

      // 验证八纯卦世应
      // 八纯卦：世爻6，应爻3
      expect(record.yaoLines[5].isShi, true); // 上爻世
      expect(record.yaoLines[2].isYing, true); // 三爻应
    });

    test('坤为地完整排盘', () {
      // 全部少阴 → 坤为地
      var backCounts = [2, 2, 2, 2, 2, 2];
      var dt = DateTime(2026, 6, 25, 14, 0);

      var record = GuaCalculator.calculate(
        backCounts: backCounts,
        divTime: dt,
        question: '测试坤卦',
      );

      expect(record.benGua.guaName, '坤为地');
      expect(record.benGua.gongNum, 7); // 坤宫
      expect(record.benGua.guaWuXing, '土');

      // 坤卦纳支：未巳卯丑亥酉（从下往上，阴卦逆排）
      expect(record.yaoLines[0].ganZhi, '未');
      expect(record.yaoLines[1].ganZhi, '巳');
      expect(record.yaoLines[2].ganZhi, '卯');
      expect(record.yaoLines[3].ganZhi, '丑');
      expect(record.yaoLines[4].ganZhi, '亥');
      expect(record.yaoLines[5].ganZhi, '酉');
    });

    test('有动爻的排盘', () {
      // 初爻老阳（3背），二爻老阴（0背）
      var backCounts = [3, 0, 1, 2, 1, 2];
      var dt = DateTime(2026, 6, 25, 10, 30);

      var record = GuaCalculator.calculate(
        backCounts: backCounts,
        divTime: dt,
        question: '测试动爻',
      );

      // 验证动爻标记
      expect(record.yaoLines[0].isDong, true); // 初爻老阳
      expect(record.yaoLines[1].isDong, true); // 二爻老阴
      expect(record.yaoLines[2].isDong, false);
      expect(record.yaoLines[3].isDong, false);
      expect(record.yaoLines[4].isDong, false);
      expect(record.yaoLines[5].isDong, false);

      // 验证有变卦
      expect(record.bianGua, isNotNull);

      // 验证动爻数量
      expect(record.dongYaoCount, 2);
      expect(record.hasDongYao(), true);
    });

    test('旬空测试', () {
      var backCounts = [1, 1, 1, 1, 1, 1];
      var dt = DateTime(2024, 1, 15, 12, 0); // 需要检查旬空

      var record = GuaCalculator.calculate(
        backCounts: backCounts,
        divTime: dt,
        question: '测试旬空',
      );

      // 验证旬空字符串
      expect(record.xunKong.length, 2);
    });

    test('神煞测试', () {
      var backCounts = [1, 1, 1, 1, 1, 1];
      var dt = DateTime(2026, 6, 25, 21, 45);

      var record = GuaCalculator.calculate(
        backCounts: backCounts,
        divTime: dt,
        question: '测试神煞',
      );

      // 验证神煞不为空
      expect(record.shensha.tianYi.isNotEmpty, true);
      expect(record.shensha.luShen.isNotEmpty, true);
    });

    test('排盘摘要输出', () {
      var backCounts = [1, 1, 1, 1, 1, 1];
      var dt = DateTime(2026, 6, 25, 21, 45);

      var record = GuaCalculator.calculate(
        backCounts: backCounts,
        divTime: dt,
        question: '测试摘要',
      );

      var summary = GuaCalculator.getSummary(record);
      expect(summary.contains('乾为天'), true);
      expect(summary.contains('乾宫'), true);
      print(summary);
    });
  });

  group('六神配置测试', () {
    test('甲日起青龙', () {
      // 甲日初爻起青龙
      // 按顺序：青龙、朱雀、勾陈、螣蛇、白虎、玄武
      var backCounts = [1, 1, 1, 1, 1, 1];
      var dt = DateTime(2024, 1, 1, 8, 0); // 甲子日

      var record = GuaCalculator.calculate(
        backCounts: backCounts,
        divTime: dt,
        question: '测试六神',
      );

      // 验证日干为甲
      expect(record.dayGz[0], '甲');

      // 验证六神顺序
      expect(record.yaoLines[0].liuShen, '青龙');
      expect(record.yaoLines[1].liuShen, '朱雀');
      expect(record.yaoLines[2].liuShen, '勾陈');
      expect(record.yaoLines[3].liuShen, '螣蛇');
      expect(record.yaoLines[4].liuShen, '白虎');
      expect(record.yaoLines[5].liuShen, '玄武');
    });
  });
}