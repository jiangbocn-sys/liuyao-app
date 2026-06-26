import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_app/models/yao_line.dart';
import 'package:liuyao_app/models/gua_info.dart';
import 'package:liuyao_app/algorithms/gua_generator.dart';
import 'package:liuyao_app/algorithms/constants.dart';

void main() {
  group('爻生成测试', () {
    test('背面数→爻类型转换', () {
      // 0背 = 老阴（动）
      var yao0 = YaoLine.fromBackCount(1, 0);
      expect(yao0.yaoType, YaoType.laoYin);
      expect(yao0.isYang, false);
      expect(yao0.isDong, true);

      // 1背 = 少阳（静）
      var yao1 = YaoLine.fromBackCount(1, 1);
      expect(yao1.yaoType, YaoType.shaoYang);
      expect(yao1.isYang, true);
      expect(yao1.isDong, false);

      // 2背 = 少阴（静）
      var yao2 = YaoLine.fromBackCount(1, 2);
      expect(yao2.yaoType, YaoType.shaoYin);
      expect(yao2.isYang, false);
      expect(yao2.isDong, false);

      // 3背 = 老阳（动）
      var yao3 = YaoLine.fromBackCount(1, 3);
      expect(yao3.yaoType, YaoType.laoYang);
      expect(yao3.isYang, true);
      expect(yao3.isDong, true);
    });

    test('爻位名称', () {
      expect(YaoLine.fromBackCount(1, 1).positionName, '初爻');
      expect(YaoLine.fromBackCount(2, 1).positionName, '二爻');
      expect(YaoLine.fromBackCount(6, 1).positionName, '上爻');
    });
  });

  group('卦生成测试', () {
    test('三爻→八卦编号', () {
      // 正确的映射（从下往上，y1=初爻，y2=二爻，y3=三爻）：
      // code = y1 + y2*2 + y3*4
      // 000=坤(8), 001=震(4), 010=坎(6), 011=兑(2)
      // 100=艮(7), 101=离(3), 110=巽(5), 111=乾(1)

      // 乾卦：三爻皆阳 (111=7)
      expect(getBaGuaId(true, true, true), 1);

      // 坤卦：三爻皆阴 (000=0)
      expect(getBaGuaId(false, false, false), 8);

      // 震卦：初爻阳，二三爻阴 (001=1)
      expect(getBaGuaId(true, false, false), 4);

      // 兑卦：初爻阳，二爻阳，三爻阴 (011=3)
      expect(getBaGuaId(true, true, false), 2);

      // 离卦：初爻阳，二爻阴，三爻阳 (101=5)
      expect(getBaGuaId(true, false, true), 3);

      // 坎卦：初爻阴，二爻阳，三爻阴 (010=2)
      expect(getBaGuaId(false, true, false), 6);

      // 艮卦：初爻阴，二爻阴，三爻阳 (100=4)
      expect(getBaGuaId(false, false, true), 7);

      // 巽卦：初爻阴，二爻阳，三爻阳 (110=6)
      expect(getBaGuaId(false, true, true), 5);
    });

    test('乾为天卦生成', () {
      // 全部少阳（1背）→ 全阳爻 → 乾为天
      var backCounts = [1, 1, 1, 1, 1, 1];
      var result = GuaGenerator.generateFromBackCounts(backCounts);

      expect(result.benGua.guaName, '乾为天');
      expect(result.benGua.guaSymbol, '☰☰');
      expect(result.benGua.gongNum, 0); // 乾宫
      expect(result.benGua.guaWuXing, '金');
    });

    test('坤为地卦生成', () {
      // 全部少阴（2背）→ 全阴爻 → 坤为地
      var backCounts = [2, 2, 2, 2, 2, 2];
      var result = GuaGenerator.generateFromBackCounts(backCounts);

      expect(result.benGua.guaName, '坤为地');
      expect(result.benGua.guaSymbol, '☷☷');
      expect(result.benGua.gongNum, 7); // 坤宫
      expect(result.benGua.guaWuXing, '土');
    });

    test('变卦生成', () {
      // 初爻老阳（3背），其余少阳（1背）
      // 本卦：乾为天（上乾下乾）
      // 变卦：初爻变阴 → 下卦乾(111)初爻变阴 → 下卦巽(110)
      // 上卦乾不变 → 变卦：上乾(1)下巽(5) → 天风姤
      // 注意：卦名格式为"上卦名+下卦名"，所以是"天风姤"而非"风天小畜"
      var backCounts = [3, 1, 1, 1, 1, 1];
      var result = GuaGenerator.generateFromBackCounts(backCounts);

      expect(result.benGua.guaName, '乾为天');
      expect(result.bianGua?.guaName, '天风姤');
      // 验证内外卦：inner=巽(5), outer=乾(1)
      expect(result.bianGua?.innerGuaId, 5);
      expect(result.bianGua?.outerGuaId, 1);
    });

    test('无动爻时无变卦', () {
      var backCounts = [1, 2, 1, 2, 1, 2]; // 无动爻
      var result = GuaGenerator.generateFromBackCounts(backCounts);

      expect(result.bianGua, null);
    });
  });

  group('GuaInfo测试', () {
    test('从内外卦创建', () {
      var gua = GuaInfo.fromInnerOuter(1, 1); // 内乾外乾
      expect(gua.guaName, '乾为天');
      expect(gua.guaSymbol, '☰☰');
      expect(gua.gua64Index, 0);
    });

    test('卦索引计算', () {
      // ⚠️ 关键公式：idx = (innerGuaId - 1) * 8 + (outerGuaId - 1)
      // innerGuaId = 内卦/下卦, outerGuaId = 外卦/上卦
      // 64卦按内卦分8组，每组内按外卦排列
      expect(GuaInfo.fromInnerOuter(1, 1).gua64Index, 0);   // 乾为天 (inner=乾, outer=乾)
      expect(GuaInfo.fromInnerOuter(8, 8).gua64Index, 63);  // 坤为地 (inner=坤, outer=坤)
      expect(GuaInfo.fromInnerOuter(1, 8).gua64Index, 7);   // 地天泰 (inner=乾, outer=坤)
      expect(GuaInfo.fromInnerOuter(8, 1).gua64Index, 56);  // 天地否 (inner=坤, outer=乾)
    });
  });
}