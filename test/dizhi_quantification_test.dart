import 'package:flutter_test/flutter_test.dart';
import '../lib/algorithms/dizhi_quantification.dart';

void main() {
  group('DiZhiQuantification 地支数字量化测试', () {
    test('月建量化值查询', () {
      // 寅月见寅（本气）应为 2
      expect(DiZhiQuantification.getMonthValue('寅', '寅'), 2);

      // 寅月见申（相冲）应为 -2
      expect(DiZhiQuantification.getMonthValue('寅', '申'), -2);

      // 寅月见亥（六合）应为 0.5
      expect(DiZhiQuantification.getMonthValue('寅', '亥'), 0.5);
    });

    test('日辰量化值查询', () {
      // 寅日见寅应为 2
      expect(DiZhiQuantification.getDayValue('寅', '寅'), 2);

      // 寅日见申（日冲）应为 null
      expect(DiZhiQuantification.getDayValue('寅', '申'), null);
    });

    test('日冲检测', () {
      // 寅日冲申
      expect(DiZhiQuantification.isDayChong('寅', '申'), true);

      // 寅日不冲寅
      expect(DiZhiQuantification.isDayChong('寅', '寅'), false);

      // 子日冲午
      expect(DiZhiQuantification.isDayChong('子', '午'), true);
    });

    test('六冲关系检测', () {
      expect(DiZhiQuantification.isLiuChong('子', '午'), true);
      expect(DiZhiQuantification.isLiuChong('寅', '申'), true);
      expect(DiZhiQuantification.isLiuChong('寅', '寅'), false);
    });

    test('单个爻量化计算 - 正常情况', () {
      // 寅月寅日，寅爻
      final result = DiZhiQuantification.calculate('寅', '寅', '寅');
      expect(result.isRiChong, false);
      expect(result.monthValue, 2);
      expect(result.dayValue, 2);
      expect(result.totalValue, 4);
      expect(result.description, '月2.0 + 日2.0 = 4.0');
    });

    test('单个爻量化计算 - 日冲情况', () {
      // 寅月寅日，申爻（日冲）
      final result = DiZhiQuantification.calculate('申', '寅', '寅');
      expect(result.isRiChong, true);
      expect(result.totalValue, null);
      expect(result.description, contains('日冲'));
    });

    test('批量计算六爻量化值', () {
      // 模拟一个排盘：寅月寅日
      final yaoDiZhiList = ['子', '丑', '寅', '卯', '辰', '巳'];
      final results = DiZhiQuantification.calculateAll(yaoDiZhiList, '寅', '寅');

      expect(results.length, 6);

      // 检查各爻结果
      // 子爻：月建-0.1，日辰0，总量化-0.1
      expect(results[0].yaoDiZhi, '子');
      expect(results[0].monthValue, -0.1);
      expect(results[0].dayValue, 0);
      expect(results[0].totalValue, -0.1);

      // 申爻不在列表中，但如果在，会显示日冲
    });

    test('不同月日组合测试', () {
      // 子月子日，午爻（日月皆冲）
      final result1 = DiZhiQuantification.calculate('午', '子', '子');
      expect(result1.monthValue, -2);
      expect(result1.isRiChong, true); // 子日冲午

      // 午月午日，子爻（日月皆冲）
      final result2 = DiZhiQuantification.calculate('子', '午', '午');
      expect(result2.monthValue, -2);
      expect(result2.isRiChong, true); // 午日冲子
    });

    test('量化值描述测试', () {
      // 寅爻在寅月寅日，月2+日2=4
      final result1 = DiZhiQuantification.calculate('寅', '寅', '寅');
      expect(result1.totalValue, 4);
      expect(result1.description, '月2.0 + 日2.0 = 4.0');

      // 亥爻在寅月寅日，月0.5+日0=0.5
      final result2 = DiZhiQuantification.calculate('亥', '寅', '寅');
      expect(result2.totalValue, 0.5);
      expect(result2.description, '月0.5 + 日0.0 = 0.5');

      // 丑爻在寅月寅日，月-1+日-1=-2
      final result3 = DiZhiQuantification.calculate('丑', '寅', '寅');
      expect(result3.totalValue, -2);
      expect(result3.description, '月-1.0 + 日-1.0 = -2.0');
    });
  });
}