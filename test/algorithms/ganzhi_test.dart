import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_app/algorithms/ganzhi_converter.dart';
import 'package:liuyao_app/algorithms/constants.dart';

void main() {
  group('干支转换测试', () {
    test('2026年6月25日 21:45 干支转换', () {
      var dt = DateTime(2026, 6, 25, 21, 45);
      var result = GanZhiConverter.convert(dt);

      // 验证年柱
      expect(result.yearGz, contains('午')); // 2026是丙午年或相近

      // 验证日柱
      expect(result.dayGz.length, 2);
      expect(tianGan.contains(result.dayGan), true);
      expect(diZhi.contains(result.dayZhi), true);

      // 验证时柱（21点属亥时）
      expect(result.hourZhi, '亥');
    });

    test('时辰对应测试', () {
      // 子时 (23-1点)
      expect(GanZhiConverter.getCurrentShiChen(DateTime(2024, 1, 1, 23)), '子');
      expect(GanZhiConverter.getCurrentShiChen(DateTime(2024, 1, 1, 0)), '子');

      // 丑时 (1-3点)
      expect(GanZhiConverter.getCurrentShiChen(DateTime(2024, 1, 1, 1)), '丑');
      expect(GanZhiConverter.getCurrentShiChen(DateTime(2024, 1, 1, 2)), '丑');

      // 亥时 (21-23点)
      expect(GanZhiConverter.getCurrentShiChen(DateTime(2024, 1, 1, 21)), '亥');
      expect(GanZhiConverter.getCurrentShiChen(DateTime(2024, 1, 1, 22)), '亥');
    });

    test('五鼠遁测试', () {
      // 甲日 → 甲子时起
      var dt1 = DateTime(2024, 1, 1, 0); // 甲子日甲子时
      var result1 = GanZhiConverter.convert(dt1);
      expect(result1.dayGan, '甲');
      expect(result1.hourGz, '甲子');

      // 日干为甲时，子时为甲子
      var dt2 = DateTime(2024, 1, 1, 23); // 甲子日子时
      var result2 = GanZhiConverter.convert(dt2);
      expect(result2.hourGz, '甲子');
    });

    test('儒略日计算测试', () {
      // 2024年1月1日是甲子日
      var dt = DateTime(2024, 1, 1);
      var result = GanZhiConverter.convert(dt);
      expect(result.dayGz, '甲子');
    });
  });

  group('六十甲子测试', () {
    test('六十甲子顺序', () {
      expect(ganzhi60[0], '甲子');
      expect(ganzhi60[9], '癸酉');
      expect(ganzhi60[10], '甲戌');
      expect(ganzhi60[59], '癸亥');
    });

    test('干支索引查找', () {
      expect(findGanZhiIndex('甲子'), 0);
      expect(findGanZhiIndex('癸亥'), 59);
      expect(findGanZhiIndex('丙午'), 42);
    });
  });

  group('天干地支测试', () {
    test('天干提取', () {
      expect(getGan('甲子'), '甲');
      expect(getGan('丙午'), '丙');
    });

    test('地支提取', () {
      expect(getZhi('甲子'), '子');
      expect(getZhi('丙午'), '午');
    });

    test('天干索引', () {
      expect(getGanIndex('甲'), 1);
      expect(getGanIndex('癸'), 10);
    });

    test('地支索引', () {
      expect(getZhiIndex('子'), 1);
      expect(getZhiIndex('亥'), 12);
    });
  });
}