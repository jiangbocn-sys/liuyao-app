import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_app/algorithms/shouxing_calendar.dart';
import 'package:liuyao_app/algorithms/ganzhi_converter.dart';
import 'package:liuyao_app/algorithms/constants.dart';

void main() {
  group('寿星万年历节气测试', () {
    setUpAll(() async {
      // 初始化节气表
      await ShouXingCalendar.init();
    });

    test('2026年立春时间', () async {
      DateTime lichun = ShouXingCalendar.getLichunTime(2026);
      // 立春应在 2026年2月
      expect(lichun.year, 2026);
      expect(lichun.month, 2);
      expect(lichun.day >= 1 && lichun.day <= 10, true);
      print('2026年立春: $lichun');
    });

    test('2026年节气列表', () {
      List<JieQiData> list = ShouXingCalendar.getJieQiList(2026);
      expect(list.length, 24);

      // 检查节气顺序
      expect(list[0].name, '小寒');
      expect(list[2].name, '立春');
      expect(list[11].name, '夏至');
      expect(list[23].name, '冬至');

      // 打印节气时间
      for (var jq in list) {
        print('${jq.name}: ${jq.time} → ${jq.monthZhi}月');
      }
    });

    test('2026年6月25日月支', () {
      DateTime dt = DateTime(2026, 6, 25, 21, 45);
      int monthZhiIdx = ShouXingCalendar.getMonthZhiIndex(dt);
      // 6月25日应在午月（芒种~小暑之间）
      expect(monthZhiIdx, 7); // 午=7
      String monthZhi = diZhi[monthZhiIdx - 1];
      expect(monthZhi, '午');
      print('2026年6月25日 → ${monthZhi}月');
    });

    test('立春前后年柱判定', () {
      DateTime lichun = ShouXingCalendar.getLichunTime(2026);

      // 立春前一小时
      DateTime beforeLichun = lichun.subtract(Duration(hours: 1));
      bool isBefore = ShouXingCalendar.isBeforeLichun(beforeLichun);
      expect(isBefore, true);

      // 立春后一小时
      DateTime afterLichun = lichun.add(Duration(hours: 1));
      bool isAfter = ShouXingCalendar.isBeforeLichun(afterLichun);
      expect(isAfter, false);

      print('立春前: $beforeLichun → beforeLichun=$isBefore');
      print('立春后: $afterLichun → beforeLichun=$isAfter');
    });

    test('表覆盖范围检查', () {
      // 检查内置表范围（1900-2100）
      expect(ShouXingCalendar.needsUpdate(1800), true);
      expect(ShouXingCalendar.needsUpdate(2026), false);
      expect(ShouXingCalendar.needsUpdate(2200), true);
    });
  });

  group('干支转换测试（使用节气）', () {
    setUpAll(() async {
      await ShouXingCalendar.init();
    });

    test('2026年6月25日 21:45 干支转换', () {
      DateTime dt = DateTime(2026, 6, 25, 21, 45);
      GanZhiResult result = GanZhiConverter.convert(dt);

      expect(result.yearGz, '丙午');
      print('干支: ${result.yearGz}年 ${result.monthGz}月 ${result.dayGz}日 ${result.hourGz}时');
      print('月支应为午，实际: ${result.monthZhi}');
    });

    test('2025年12月干支（立春前）', () {
      DateTime dt = DateTime(2025, 12, 25, 12, 0);
      GanZhiResult result = GanZhiConverter.convert(dt);

      print('2025年12月25日: ${result.yearGz}年 ${result.monthGz}月');
      print('年支: ${result.yearZhi}, 月支: ${result.monthZhi}');
      expect(result.yearGz, '乙巳');
    });

    test('儒略日转换', () {
      DateTime dt = DateTime(2024, 1, 1, 0, 0);
      double jd = ShouXingCalendar.dateTimeToJD(dt);
      DateTime back = ShouXingCalendar.jdToDateTime(jd);

      expect(back.year, dt.year);
      expect(back.month, dt.month);
      expect(back.day >= dt.day - 1 && back.day <= dt.day + 1, true);

      print('JD转换: $dt → $jd → $back');
    });
  });
}