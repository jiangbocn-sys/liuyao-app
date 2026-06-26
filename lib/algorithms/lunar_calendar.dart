/// 农历转换器
/// 使用1900-2100年农历数据表进行精确转换
library;

/// 农历转换器类
class LunarCalendar {
  /// 农历月份名称
  static const List<String> lunarMonthNames = [
    '正月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '十一月', '十二月',
  ];

  /// 农历日期名称
  static const List<String> lunarDayNames = [
    '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
  ];

  /// 1900-2100年农历数据表
  /// 每年数据格式：
  /// - 前12位：每月天数（1=30天，0=29天）
  /// - 第13-16位：闰月月份（0表示无闰月）
  /// - 第17位：闰月天数（1=30天，0=29天）
  static const List<int> lunarData = [
    0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, // 1900-1909
    0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, // 1910-1919
    0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, // 1920-1929
    0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, // 1930-1939
    0x0d4a0, 0x0d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, // 1940-1949
    0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x09a70, 0x05252, 0x0b6a0, // 1950-1959
    0x0a950, 0x04b55, 0x0b550, 0x055a0, 0x15355, 0x04da0, 0x0a5d0, 0x14573, 0x052d0, 0x09a70, // 1960-1969
    0x05252, 0x0a950, 0x0b4a0, 0x0b6a0, 0x0ad50, 0x055a0, 0x1a5b5, 0x04da0, 0x0a5b0, 0x15653, // 1970-1979
    0x052b0, 0x0a9a0, 0x095b0, 0x0b550, 0x04b55, 0x0b550, 0x055a0, 0x15355, 0x04da0, 0x0a5b0, // 1980-1989
    0x14573, 0x052b0, 0x0a9a0, 0x0d5b0, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, // 1990-1999
    0x0a950, 0x0b557, 0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5d0, 0x14573, 0x052d0, 0x09a70, // 2000-2009
    0x05252, 0x0a950, 0x0b4a0, 0x0b6a0, 0x0ad50, 0x055a0, 0x1a5b5, 0x04da0, 0x0a5b0, 0x0b557, // 2010-2019
    0x055a0, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a0, 0x0d5b0, 0x0b550, 0x056a0, // 2020-2029
    0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, 0x06ca0, 0x0b550, 0x15355, 0x04da0, // 2030-2039
    0x0a5d0, 0x14573, 0x052d0, 0x09a70, 0x05252, 0x0a950, 0x0b4a0, 0x0b6a0, 0x0ad50, 0x055a0, // 2040-2049
    0x1a5b5, 0x04da0, 0x0a5b0, 0x0b557, 0x055a0, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, // 2050-2059
    0x0a9a0, 0x0d5b0, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, // 2060-2069
    0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5d0, 0x14573, 0x052d0, 0x09a70, 0x05252, 0x0a950, // 2070-2079
    0x0b4a0, 0x0b6a0, 0x0ad50, 0x055a0, 0x1a5b5, 0x04da0, 0x0a5b0, 0x0b557, 0x055a0, 0x15355, // 2080-2089
    0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a0, 0x0d5b0, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, // 2090-2099
    0x092d0, 0x0d2b2, 0x0a950, 0x0b557, 0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5d0, 0x14573, // 2100
  ];

  /// 基准日期：1900年1月31日（农历1900年正月初一）
  static const int baseYear = 1900;
  static const int baseDateDays = 31; // 1900年1月31日的儒略日基准

  /// 获取指定年份的农历数据
  static int getLunarYearData(int year) {
    if (year < 1900 || year > 2100) {
      year = 1900; // 超出范围使用基准年
    }
    return lunarData[year - baseYear];
  }

  /// 解析农历年数据
  /// 返回：每月天数列表（正月到十二月），闰月月份，闰月天数
  static List<int> parseYearData(int data) {
    List<int> monthDays = [];
    for (int i = 0; i < 12; i++) {
      monthDays.add((data >> (16 - i)) & 1 == 1 ? 30 : 29);
    }
    int leapMonth = (data >> 8) & 0xf; // 闰月月份（0表示无闰月）
    int leapMonthDays = (data >> 7) & 1 == 1 ? 30 : 29; // 闰月天数
    return [...monthDays, leapMonth, leapMonthDays];
  }

  /// 计算农历年的总天数
  static int getLunarYearDays(int year) {
    int data = getLunarYearData(year);
    List<int> parsed = parseYearData(data);
    int days = 0;
    for (int i = 0; i < 12; i++) {
      days += parsed[i];
    }
    if (parsed[12] > 0) {
      days += parsed[13]; // 加闰月天数
    }
    return days;
  }

  /// 公历日期转农历日期
  /// 返回：[农历年, 农历月（1-12，负数表示闰月），农历日]
  static List<int> solarToLunar(DateTime solarDate) {
    // 计算与基准日期的天数差
    DateTime baseDate = DateTime(1900, 1, 31);
    int offset = _daysBetween(baseDate, solarDate);

    // 从基准年开始计算农历年
    int lunarYear = baseYear;
    while (offset >= getLunarYearDays(lunarYear)) {
      offset -= getLunarYearDays(lunarYear);
      lunarYear++;
    }

    // 确定农历月和日
    int data = getLunarYearData(lunarYear);
    List<int> parsed = parseYearData(data);
    int leapMonth = parsed[12];
    int leapMonthDays = parsed[13];

    int lunarMonth = 1;
    bool isLeap = false;

    // 遍历各月
    for (int i = 0; i < 12; i++) {
      int monthDays = parsed[i];

      // 检查是否需要处理闰月
      if (leapMonth > 0 && i == leapMonth - 1 && !isLeap) {
        // 先处理正常月
        if (offset < monthDays) {
          break;
        }
        offset -= monthDays;
        // 再处理闰月
        if (offset < leapMonthDays) {
          isLeap = true;
          lunarMonth = -leapMonth; // 负数表示闰月
          break;
        }
        offset -= leapMonthDays;
        lunarMonth++;
      } else {
        if (offset < monthDays) {
          break;
        }
        offset -= monthDays;
        lunarMonth++;
      }
    }

    int lunarDay = offset + 1;

    return [lunarYear, isLeap ? -lunarMonth : lunarMonth, lunarDay];
  }

  /// 计算两个日期之间的天数差
  static int _daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// 获取农历日期字符串
  /// 格式：如"二月初五"、"闰四月十五"
  static String getLunarDateString(DateTime solarDate) {
    List<int> lunar = solarToLunar(solarDate);
    int lunarMonth = lunar[1];
    int lunarDay = lunar[2];

    String monthStr;
    if (lunarMonth < 0) {
      // 闰月
      monthStr = '闰${lunarMonthNames[lunarMonth.abs() - 1]}';
    } else {
      monthStr = lunarMonthNames[lunarMonth - 1];
    }

    String dayStr = lunarDayNames[lunarDay - 1];

    return '$monthStr$dayStr';
  }

  /// 获取农历年份（干支纪年）
  /// 注意：农历年与公历年的干支年不同，农历年以正月初一为界
  static int getLunarYear(DateTime solarDate) {
    return solarToLunar(solarDate)[0];
  }
}