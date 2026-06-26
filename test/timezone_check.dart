import 'package:liuyao_app/algorithms/shouxing_calendar.dart';

void main() {
  var lichun = ShouXingCalendar.getJieQiTime(2026, 2);
  
  print('立春 UTC:    $lichun');
  print('立春 北京时间: ${lichun.add(const Duration(hours: 8))}');
  print('');
  print('标准值:      2026-02-04 04:01 北京时间');
  print('算法值:      ${lichun.add(const Duration(hours: 8)).toString().substring(0,16)} 北京时间');
  print('');
  
  // 差多少分钟
  var expected = DateTime.utc(2026, 2, 3, 20, 1); // 04:01 CST = 20:01 UTC
  var diff = lichun.difference(expected).inMinutes.abs();
  print('偏差: $diff 分钟');
  print('结论: ${diff <= 15 ? "✅ 精度达标" : "❌ 偏差过大"}');
}
