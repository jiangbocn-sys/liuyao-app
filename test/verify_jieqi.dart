import 'package:liuyao_app/algorithms/shouxing_calendar.dart';

void main() {
  print('=== 立春验证 ===');
  var lichun = ShouXingCalendar.getJieQiTime(2026, 2);
  print('立春 2026: $lichun (UTC)');
  print('立春 2026 CST: ${lichun.add(const Duration(hours: 8))}');
  print('预期: 2026-02-04 04:03 CST');
  
  print('\n=== 关键节气 2026 ===');
  var list = ShouXingCalendar.getJieQiList(2026);
  for (var jq in list) {
    var cst = jq.time.add(const Duration(hours: 8));
    print('${jq.name.padRight(4)} $cst  月支=${jq.monthZhi}');
  }
}
