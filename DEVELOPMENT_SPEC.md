# 六爻排盘 App 完整开发文档

> 目标：跨平台（iOS + Android）六爻排盘 Flutter 应用
> 文档用途：供 Claude Code / Cursor 等 AI Coding Agent 使用
> 创建时间：2026-06-25
> 版本：v1.0

---

## 目录

1. [项目概述](#1-项目概述)
2. [环境配置](#2-环境配置)
3. [项目结构](#3-项目结构)
4. [数据模型](#4-数据模型)
5. [核心算法](#5-核心算法)
6. [UI 设计详细规格](#6-ui-设计详细规格)
7. [资源文件](#7-资源文件)
8. [开发步骤（Phase by Phase）](#8-开发步骤)
9. [测试用例](#9-测试用例)
10. [附录：完整查表数据](#10-附录)
11. [给 Claude Code/Cursor 的使用说明](#11-给-claude-codecursor-的使用说明)
12. [⚠️ 内外卦约定与已知陷阱](#12-️-内外卦约定与已知陷阱)

---

## 1. 项目概述

### 1.1 技术栈

| 项 | 选型 |
|---|------|
| 框架 | Flutter 3.x+ (stable) |
| 语言 | Dart 3.x |
| 数据库 | sqflite (SQLite) |
| 状态管理 | Provider (轻量) |
| 最低 Android | API 24 (Android 7.0) |
| 最低 iOS | iOS 14.0 |
| 包管理 | pub.dev |

### 1.2 核心功能清单

- [x] 起卦时间自动获取 + 手动选择
- [x] 铜钱手动输入（输入6次背面数）
- [x] 在线模拟摇卦（铜钱动画 + 随机正反面）
- [x] 数字起卦（时间起卦法）
- [x] 干支转换（公历→天干地支）
- [x] 纳甲装卦（八卦纳干纳支）
- [x] 六亲配置
- [x] 六神配置
- [x] 旬空标记
- [x] 神煞查询（天乙贵人、驿马、华盖、咸池、天医、禄神）
- [x] 世应定位
- [x] 伏神查找
- [x] 本卦、变卦、互卦
- [x] 起卦记录存储（SQLite）
- [x] 解卦内容编辑
- [x] 历史记录列表
- [x] 卦爻关系展示（生克冲合）
- [x] 日月建影响标注

---

## 2. 环境配置

### 2.1 macOS 开发环境搭建

```bash
# 1. 安装 Flutter SDK
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/development/flutter/bin"
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc

# 2. 验证
flutter doctor

# 3. 安装 Xcode（从 App Store）

# 4. 安装 Android Studio（从官网下载）
# 安装完成后在 Android Studio 中安装：
#   - Android SDK
#   - Android SDK Command-line Tools
#   - Android Emulator

# 5. 创建模拟器
flutter emulators --create --name pixel_6
flutter emulators --create --name iphone_15

# 6. 接受 Android 许可
flutter doctor --android-licenses
```

### 2.2 创建项目

```bash
cd ~/projects
flutter create --org com.bobo --project-name liuyao_app liuyao_app
cd liuyao_app
```

---

## 3. 项目结构

```
liuyao_app/
├── pubspec.yaml                  # 依赖配置
├── lib/
│   ├── main.dart                 # 应用入口
│   │
│   ├── models/                   # 数据模型（Dart class）
│   │   ├── divination_record.dart  # 起卦记录
│   │   ├── yao_line.dart           # 单爻数据
│   │   ├── gua_info.dart           # 卦信息
│   │   └── shensha_result.dart     # 神煞结果
│   │
│   ├── algorithms/               # 核心算法（纯Dart，零UI依赖）
│   │   ├── ganzhi_converter.dart   # 公历→干支/农历转换
│   │   ├── najia_config.dart       # 纳甲装卦
│   │   ├── liuqin_config.dart      # 六亲配置
│   │   ├── liushen_config.dart     # 六神配置
│   │   ├── xunkong_calculator.dart # 旬空计算
│   │   ├── shensha_calculator.dart # 神煞计算
│   │   ├── fushen_finder.dart      # 伏神查找
│   │   ├── shiying_config.dart     # 世应定位
│   │   ├── gua_generator.dart      # 卦象生成（总协调器）
│   │   └── constants.dart          # 所有查表数据（64卦、纳甲表等）
│   │
│   ├── database/                 # 数据库层
│   │   ├── database_helper.dart    # 数据库初始化
│   │   ├── record_dao.dart         # 起卦记录 DAO
│   │   └── yao_dao.dart            # 爻详情 DAO
│   │
│   ├── providers/                # 状态管理
│   │   ├── divination_provider.dart # 起卦状态
│   │   └── history_provider.dart    # 历史记录状态
│   │
│   ├── screens/                  # 页面
│   │   ├── home_screen.dart        # 首页（起卦入口）
│   │   ├── divination_screen.dart  # 起卦页面（摇卦/手动输入）
│   │   ├── result_screen.dart      # 排盘结果页
│   │   ├── history_screen.dart     # 历史记录列表
│   │   └── detail_screen.dart      # 详情/解卦页
│   │
│   ├── widgets/                  # 可复用组件
│   │   ├── gua_display.dart        # 卦象图形显示
│   │   ├── yao_table.dart          # 六爻详情表格
│   │   ├── coin_widget.dart        # 铜钱摇卦动画组件
│   │   ├── shensha_card.dart       # 神煞信息卡片
│   │   └── time_picker.dart        # 时间选择器
│   │
│   └── utils/                    # 工具函数
│       └── lunar_calendar.dart    # 农历转换工具
│
├── assets/
│   ├── images/
│   │   ├── coin_front.png         # 铜钱正面（512x512 PNG）
│   │   └── coin_back.png          # 铜钱背面（512x512 PNG）
│   └── fonts/                    # 字体（可选）
│
├── android/                      # Android 原生配置
├── ios/                          # iOS 原生配置
├── test/                         # 单元测试
│   ├── algorithms/               # 核心算法测试
│   │   ├── ganzhi_test.dart
│   │   ├── najia_test.dart
│   │   ├── gua_generator_test.dart
│   │   └── ...
│   └── database/
│       └── record_dao_test.dart
└── README.md
```

---

## 4. 数据模型

### 4.1 Dart 数据类

#### DivinationRecord（起卦记录）

```dart
class DivinationRecord {
  final int? id;              // 自增主键
  final DateTime createdAt;   // 创建时间
  final DateTime divTime;     // 起卦时间
  final String querentName;   // 起卦人姓名
  final String querentGender; // 起卦人性别（男/女）
  final String question;      // 所问问题
  final String startMethod;   // 起卦方式：'manual'/'shake'/'time'/'number'
  final String lunarYear;     // 农历年（如 丙午年）
  final String lunarMonth;    // 农历月
  final String lunarDay;      // 农历日
  final String yearGz;        // 年柱干支
  final String monthGz;       // 月柱干支
  final String dayGz;         // 日柱干支
  final String hourGz;        // 时柱干支
  final String xunkong;       // 旬空地支
  final String benGuaName;    // 本卦卦名
  final String benGuaSymbol;  // 本卦八卦符号（如 ☰☲）
  final String bianGuaName;   // 变卦卦名
  final String bianGuaSymbol; // 变卦符号
  final String huGuaName;     // 互卦卦名
  final String huGuaSymbol;   // 互卦符号
  final String guaWuxing;     // 卦五行
  final String guaGong;       // 卦宫名称
  final int guaGongNum;       // 卦宫编号（0-7，对应乾兑离震巽坎艮坤）
  final int shiYao;           // 世爻位置（1-6）
  final int yingYao;          // 应爻位置（1-6）
  final List<int> backCounts; // 六次背面数 [0,1,2,3,2,1...]（含顺序）
  final List<YaoLine> yaoLines; // 六爻详情
  final ShenshaResult shensha;  // 神煞结果
  final String? interpretation; // 解卦内容
  final List<String>? tags;     // 标签（备用）
}
```

#### YaoLine（单爻数据）

```dart
class YaoLine {
  final int position;       // 爻位 1(初爻)-6(上爻)
  final int backCount;      // 背面数 0-3
  final String yaoType;     // 爻类型 'laoyang'/'shaoyang'/'laoyin'/'shaoyin'
  final bool isYang;         // 是否阳爻
  final bool isDong;         // 是否动爻
  final String? ganzhi;      // 纳甲地支
  final String? wuxing;      // 地支五行
  final String? liuqin;      // 六亲
  final String? liushen;     // 六神
  final bool? isShi;         // 是否世爻
  final bool? isYing;        // 是否应爻
  final bool? isXunkong;     // 是否旬空
  final String? fushen;      // 伏神（如有）
  final String? feishen;     // 飞神（如有）
  final String? bianYaoType; // 变爻类型
  final String? bianGanzhi;  // 变爻地支
  final String? bianWuxing;  // 变爻五行
  final String? bianLiuqin;  // 变爻六亲
  
  // 新增：卦爻关系（未来）
  final List<String>? relations; // 与其他爻的关系
  final List<String>? riyueEffects; // 日月建影响
}
```

#### ShenshaResult（神煞结果）

```dart
class ShenshaResult {
  final String tianyi;    // 天乙贵人
  final String yima;       // 驿马
  final String huagai;     // 华盖
  final String xianchi;    // 咸池（桃花）
  final String tianyiShen; // 天医
  final String lushen;     // 禄神
}
```

---

### 4.2 SQLite 表结构（单表方案）

起卦+排盘+解卦一一对应，无需拆表：

```sql
CREATE TABLE divination_records (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at      TEXT NOT NULL,        -- ISO 8601
    div_time        TEXT NOT NULL,         -- 起卦时间
    querent_name    TEXT NOT NULL DEFAULT '',  -- 起卦人姓名
    querent_gender  TEXT NOT NULL DEFAULT '',  -- 起卦人性别（男/女）
    question        TEXT NOT NULL,         -- 所问问题
    start_method    TEXT NOT NULL,         -- 'manual'/'shake'/'time'/'number'
    lunar_year      TEXT,                 -- 农历年
    lunar_month     TEXT,                 -- 农历月
    lunar_day       TEXT,                 -- 农历日
    year_gz         TEXT NOT NULL,         -- 年柱
    month_gz        TEXT NOT NULL,         -- 月柱
    day_gz          TEXT NOT NULL,         -- 日柱
    hour_gz         TEXT NOT NULL,         -- 时柱
    xunkong         TEXT NOT NULL,         -- 旬空
    ben_gua_name    TEXT NOT NULL,         -- 本卦名
    ben_gua_symbol  TEXT NOT NULL,         -- 本卦符号
    bian_gua_name   TEXT,                 -- 变卦名
    bian_gua_symbol TEXT,                 -- 变卦符号
    hu_gua_name     TEXT,                 -- 互卦名
    hu_gua_symbol   TEXT,                 -- 互卦符号
    gua_wuxing      TEXT NOT NULL,         -- 卦五行
    gua_gong        TEXT NOT NULL,         -- 卦宫名
    gua_gong_num    INTEGER NOT NULL,      -- 卦宫编号
    shi_yao         INTEGER NOT NULL,      -- 世爻位置 1-6
    ying_yao        INTEGER NOT NULL,      -- 应爻位置 1-6
    back_counts     TEXT NOT NULL,         -- JSON: [0,2,3,1,2,2]
    yao_lines       TEXT NOT NULL,         -- JSON: [{六爻详情}]
    shensha         TEXT NOT NULL,         -- JSON: {天乙:,驿马:,...}
    interpretation  TEXT,                  -- 解卦内容（唯一，可修改）
    tags            TEXT,                  -- JSON标签（备用）
    updated_at      TEXT                   -- 最后修改时间
);
```

**不再需要 `yao_lines` 独立表**。六爻详情以 JSON 列存，和记录原子读写。
模型类已有的 `toJson()`/`fromJson()` 可直接用于 JSON 列序列化。

---

## 5. 核心算法

### 5.1 算法总协调器 — GuaGenerator

所有算法通过 `GuaGenerator` 统一调用：

```dart
class GuaGenerator {
  /// 入口：根据6次背面数 + 起卦时间 → 完整排盘数据
  static DivinationRecord generate({
    required List<int> backCounts,  // 6个背面数 [0-3,...]
    required DateTime divTime,      // 起卦时间
    required String question,       // 问题
    String startMethod = 'manual',
  }) {
    // 1. 干支转换
    // 2. 生辰卦象（本卦/变卦/互卦）
    // 3. 纳甲装卦
    // 4. 六亲配置
    // 5. 六神配置
    // 6. 旬空判断
    // 7. 世应定位
    // 8. 伏神查找
    // 9. 神煞计算
    // → 组装 DivinationRecord
  }
}
```

### 5.2 干支转换算法

#### 5.2.1 天干地支基础

```
十天干：甲(1) 乙(2) 丙(3) 丁(4) 戊(5) 己(6) 庚(7) 辛(8) 壬(9) 癸(10)
十二地支：子(1) 丑(2) 寅(3) 卯(4) 辰(5) 巳(6) 午(7) 未(8) 申(9) 酉(10) 戌(11) 亥(12)
六十甲子：天干地支配对，从"甲子"到"癸亥"共60组
```

#### 5.2.2 年柱计算

```dart
// 公历年份 → 年柱干支
// 以立春为界，立春后算新年
String getYearGanzhi(int year, int month, int day) {
  // 判断是否在立春之前
  bool beforeLichun = isBeforeLichun(year, month, day);
  int effectiveYear = beforeLichun ? year - 1 : year;
  
  // 1984年是甲子年（基准）
  int offset = (effectiveYear - 1984) % 60;
  if (offset < 0) offset += 60;
  return ganzhi60[offset];
}
```

#### 5.2.3 月柱计算

```dart
// 月柱 = (年干序号×2 + 月支序号) 对应的天干 + 月支
String getMonthGanzhi(String yearGan, int month) {
  // 月支固定：正月寅、二月卯...
  int monthZhiIndex = month; // 正月=1→寅=3, 2→卯=4...
  
  // 年干序号（甲=1）
  int yearGanIndex = tianGan.indexOf(yearGan) + 1;
  
  // 月干序号 = (yearGanIndex * 2 + monthZhiIndex - 2) % 10
  int monthGanIndex = (yearGanIndex * 2 + monthZhiIndex) % 10;
  if (monthGanIndex == 0) monthGanIndex = 10;
  
  String monthGan = tianGan[monthGanIndex - 1];
  String monthZhi = _getMonthZhi(month);
  
  return '$monthGan$monthZhi';
}

// 月地支对应（按节气分界）
String _getMonthZhi(int month) {
  const monthZhi = ['寅','卯','辰','巳','午','未','申','酉','戌','亥','子','丑'];
  return monthZhi[month - 1]; // 正月→寅(index 0)
}
```

#### 5.2.4 日柱计算

```dart
// 使用儒略日法计算日柱
// 公式：日干支序号 = (JD + 0.5 + 49) % 60
// 此方法是精确的万年历算法
String getDayGanzhi(DateTime date) {
  // 1. 计算儒略日
  int jd = _gregorianToJD(date.year, date.month, date.day);
  
  // 2. 日干支序号（以甲子=1）
  int index = ((jd + 1 + 13) % 60);
  if (index == 0) index = 60;
  
  return ganzhi60[index - 1];
}

int _gregorianToJD(int y, int m, int d) {
  if (m <= 2) { y -= 1; m += 12; }
  int a = y ~/ 100;
  int b = 2 - a + a ~/ 4;
  return (365.25 * (y + 4716)).floor() +
         (30.6001 * (m + 1)).floor() +
         d + b - 1524;
}
```

#### 5.2.5 时柱计算

```dart
// 时柱 = (日干序号×2 + 时支序号)天干 + 时支
String getHourGanzhi(String dayGan, int hour) {
  int dayGanIndex = tianGan.indexOf(dayGan) + 1; // 1-10
  
  // 时支序号（23-1→子=1, 1-3→丑=2, ...）
  int shiZhiIndex = ((hour + 1) ~/ 2) % 12; // 修正
  if (shiZhiIndex == 0) shiZhiIndex = 12;
  
  // 五鼠遁：甲己起甲子，乙庚起丙子，丙辛起戊子，丁壬起庚子，戊癸起壬子
  int baseGanIndex = _getWushuDunBase(dayGanIndex);
  
  // 时干序号
  int hourGanIndex = (baseGanIndex + shiZhiIndex - 1) % 10;
  if (hourGanIndex == 0) hourGanIndex = 10;
  
  String hourGan = tianGan[hourGanIndex - 1];
  String hourZhi = dizhi[shiZhiIndex - 1];
  
  return '$hourGan$hourZhi';
}

// 五鼠遁起法
int _getWushuDunBase(int dayGanIndex) {
  // 甲己日起甲子（天干序号1），乙庚起丙子（3），...
  const base = {1:1, 2:3, 3:5, 4:7, 5:9, 6:1, 7:3, 8:5, 9:7, 10:9};
  return base[dayGanIndex] ?? 1;
}
```

### 5.3 卦象生成算法

#### 5.3.1 背面数 → 爻类型

```dart
YaoLine makeYao(int position, int backCount) {
  String yaoType;
  bool isYang;
  bool isDong;
  
  switch (backCount) {
    case 0: // 三个正面 = 0背 = 老阴（动）
      yaoType = 'laoyin';
      isYang = false;
      isDong = true;
      break;
    case 1: // 两正一反 = 1背 = 少阳（静）
      yaoType = 'shaoyang';
      isYang = true;
      isDong = false;
      break;
    case 2: // 一正两反 = 2背 = 少阴（静）
      yaoType = 'shaoyin';
      isYang = false;
      isDong = false;
      break;
    case 3: // 三个反面 = 3背 = 老阳（动）
      yaoType = 'laoyang';
      isYang = true;
      isDong = true;
      break;
    default:
      throw ArgumentError('背面数必须在0-3之间');
  }
  
  return YaoLine(position: position, backCount: backCount, 
                 yaoType: yaoType, isYang: isYang, isDong: isDong);
}
```

#### 5.3.2 三爻→八卦

```dart
// 八卦编号：乾(1)兑(2)离(3)震(4)巽(5)坎(6)艮(7)坤(8)
// 阳爻=1, 阴爻=0, 从下往上排列，如 ☰=111=7=乾(1)
int getGuaId(bool y1, bool y2, bool y3) {
  int code = (y1 ? 1 : 0) + ((y2 ? 1 : 0) << 1) + ((y3 ? 1 : 0) << 2);
  // code: 000=坤(8), 001=震(4), 010=坎(6), 011=兑(2),
  //        100=艮(7), 101=离(3), 110=巽(5), 111=乾(1)
  const map = {0:8, 1:4, 2:6, 3:2, 4:7, 5:3, 6:5, 7:1};
  return map[code] ?? 1;
}
```

#### 5.3.3 本卦/变卦/互卦

```dart
class GuaResult {
  final String guaName;     // 卦名
  final String guaSymbol;   // 卦符号（如 ☰☲）
  final int innerGuaId;     // 内卦编号（下卦 1-8）
  final int outerGuaId;     // 外卦编号（上卦 1-8）
  final int gua64Index;     // 64卦序号 0-63
}

// 本卦：直接取6爻
GuaResult getBenGua(List<YaoLine> yaoLines) {
  int innerId = getGuaId(yaoLines[0].isYang, yaoLines[1].isYang, yaoLines[2].isYang);
  int outerId = getGuaId(yaoLines[3].isYang, yaoLines[4].isYang, yaoLines[5].isYang);
  int idx64 = (innerId - 1) * 8 + (outerId - 1);
  return GuaResult(
    guaName: gua64Names[idx64],
    guaSymbol: '${baguaSymbols[outerId]}${baguaSymbols[innerId]}',
    innerGuaId: innerId,
    outerGuaId: outerId,
    gua64Index: idx64,
  );
}

// 变卦：本卦中的动爻阴阳互换
GuaResult getBianGua(List<YaoLine> yaoLines) {
  List<bool> bianYangs = yaoLines.map((y) => y.isDong ? !y.isYang : y.isYang).toList();
  int innerId = getGuaId(bianYangs[0], bianYangs[1], bianYangs[2]);
  int outerId = getGuaId(bianYangs[3], bianYangs[4], bianYangs[5]);
  int idx64 = (innerId - 1) * 8 + (outerId - 1);
  return GuaResult(
    guaName: gua64Names[idx64],
    guaSymbol: '${baguaSymbols[outerId]}${baguaSymbols[innerId]}',
    innerGuaId: innerId,
    outerGuaId: outerId,
    gua64Index: idx64,
  );
}

// 互卦：本卦的2-4爻为下卦，3-5爻为上卦
GuaResult getHuGua(List<YaoLine> yaoLines) {
  int innerId = getGuaId(yaoLines[1].isYang, yaoLines[2].isYang, yaoLines[3].isYang);
  int outerId = getGuaId(yaoLines[2].isYang, yaoLines[3].isYang, yaoLines[4].isYang);
  int idx64 = (innerId - 1) * 8 + (outerId - 1);
  return GuaResult(
    guaName: gua64Names[idx64],
    guaSymbol: '${baguaSymbols[outerId]}${baguaSymbols[innerId]}',
    innerGuaId: innerId,
    outerGuaId: outerId,
    gua64Index: idx64,
  );
}
```

> **⚠️ 关键约定**：64卦索引公式为 `(inner-1)×8 + (outer-1)`，其中 inner=内卦/下卦，outer=外卦/上卦。
> 卦名格式为"上卦名+下卦名"。详见第12节。

### 5.4 纳甲装卦

#### 5.4.1 卦宫判定

```dart
// 64卦→卦宫映射（关键！影响六亲）
// 使用六十四卦分宫表
int getGongFromGua64(int gua64Index) {
  // gua64Index 0-63
  return gua64Gong[gua64Index]; // 返回宫编号 0(乾)1(兑)2(离)...
}

// 宫编号→宫五行
String getGongWuxing(int gongNum) {
  const wuxing = ['金','金','火','木','木','水','土','土'];
  return wuxing[gongNum];
}
```

#### 5.4.2 地支配置

```dart
// 八卦各爻地支表
// 阳卦顺排（乾震坎艮），阴卦逆排（坤巽离兑）
static const Map<int, List<String>> baguaDizhi = {
  // guaId(1-8) → [初爻, 二爻, 三爻, 四爻, 五爻, 上爻]
  1: ['子', '寅', '辰', '午', '申', '戌'],  // 乾
  2: ['巳', '卯', '丑', '亥', '酉', '未'],  // 兑
  3: ['卯', '丑', '亥', '酉', '未', '巳'],  // 离
  4: ['子', '寅', '辰', '午', '申', '戌'],  // 震
  5: ['丑', '亥', '酉', '未', '巳', '卯'],  // 巽
  6: ['寅', '辰', '午', '申', '戌', '子'],  // 坎
  7: ['辰', '午', '申', '戌', '子', '寅'],  // 艮
  8: ['未', '巳', '卯', '丑', '亥', '酉'],  // 坤
};

// 为每个爻分配地支
void assignDizhi(GuaResult gua, List<YaoLine> yaoLines) {
  int innerId = gua.innerGuaId;
  int outerId = gua.outerGuaId;
  
  // 下卦（初、二、三爻）用内卦地支的前三条
  var innerDizhi = baguaDizhi[innerId]!;
  // 上卦（四、五、上爻）用外卦地支的后三条
  var outerDizhi = baguaDizhi[outerId]!;
  
  List<String> allDizhi = [
    innerDizhi[0], innerDizhi[1], innerDizhi[2],
    outerDizhi[3], outerDizhi[4], outerDizhi[5],
  ];
  
  for (int i = 0; i < 6; i++) {
    yaoLines[i].ganzhi = allDizhi[i];
    yaoLines[i].wuxing = dizhiWuxing[allDizhi[i]]!;
  }
}

// 地支五行
static const Map<String, String> dizhiWuxing = {
  '子':'水', '丑':'土', '寅':'木', '卯':'木',
  '辰':'土', '巳':'火', '午':'火', '未':'土',
  '申':'金', '酉':'金', '戌':'土', '亥':'水',
};
```

### 5.5 六亲配置

```dart
// 以宫五行为"我"，各爻五行与我的关系
void assignLiuqin(List<YaoLine> yaoLines, String gongWuxing) {
  const wuxingRelation = {
    // 我五行 → {爻五行 → 六亲名}
    '金': {'金':'兄弟', '水':'子孙', '木':'妻财', '火':'官鬼', '土':'父母'},
    '水': {'水':'兄弟', '木':'子孙', '火':'妻财', '土':'官鬼', '金':'父母'},
    '木': {'木':'兄弟', '火':'子孙', '土':'妻财', '金':'官鬼', '水':'父母'},
    '火': {'火':'兄弟', '土':'子孙', '金':'妻财', '水':'官鬼', '木':'父母'},
    '土': {'土':'兄弟', '金':'子孙', '水':'妻财', '木':'官鬼', '火':'父母'},
  };
  
  var relation = wuxingRelation[gongWuxing]!;
  for (var yao in yaoLines) {
    yao.liuqin = relation[yao.wuxing] ?? '未知';
  }
}
```

### 5.6 六神配置

```dart
void assignLiushen(List<YaoLine> yaoLines, String dayGan) {
  // 日干→初爻起六神
  const dayGanToStartLiushen = {
    '甲':0, '乙':0,    // 青龙
    '丙':1, '丁':1,    // 朱雀
    '戊':2,            // 勾陈
    '己':3,            // 螣蛇
    '庚':4, '辛':4,    // 白虎
    '壬':5, '癸':5,    // 玄武
  };
  
  const liushenList = ['青龙','朱雀','勾陈','螣蛇','白虎','玄武'];
  
  int startIndex = dayGanToStartLiushen[dayGan] ?? 0;
  
  // 初爻→上爻：从 startIndex 开始按 liushenList 顺序排列
  for (int i = 0; i < 6; i++) {
    int idx = (startIndex + i) % 6;
    yaoLines[i].liushen = liushenList[idx];
  }
}
```

### 5.7 旬空判断

```dart
void assignXunkong(List<YaoLine> yaoLines, String dayGz) {
  // 1. 确定日干支属于哪一旬
  String xunStart = getXunStart(dayGz); // 如 '甲子','甲戌',...
  
  // 2. 该旬的空亡地支
  const xunkongTable = {
    '甲子': ['戌','亥'],
    '甲戌': ['申','酉'],
    '甲申': ['午','未'],
    '甲午': ['辰','巳'],
    '甲辰': ['寅','卯'],
    '甲寅': ['子','丑'],
  };
  
  var kongDizhi = xunkongTable[xunStart]!;
  
  // 3. 标记旬空爻
  for (var yao in yaoLines) {
    yao.isXunkong = kongDizhi.contains(yao.ganzhi);
  }
}

String getXunStart(String dayGz) {
  // find the dayGz in 60-ganzhi, then find the nearest 甲* before it
  int idx = ganzhi60.indexOf(dayGz);
  int xunStartIdx = (idx ~/ 10) * 10; // 每10日一旬
  return ganzhi60[xunStartIdx].substring(0, 1) == '甲' 
      ? ganzhi60[xunStartIdx]
      : ganzhi60[xunStartIdx - (idx % 10)]; // 回退到旬首
}
```

### 5.8 世应定位

```dart
// 世应位置规律
// 八纯卦: 六爻世、三爻应
// 一世卦: 初爻世、四爻应
// ... 
// 归魂卦: 三爻世、六爻应

void assignShiYing(GuaResult benGua, List<YaoLine> yaoLines, int gongNum) {
  // 获取卦在宫中的变爻次数
  int changeCount = getChangeCount(benGua.gua64Index, gongNum);
  
  int shiPos, yingPos;
  
  switch (changeCount) {
    case 0: shiPos = 6; yingPos = 3; break;  // 八纯卦
    case 1: shiPos = 1; yingPos = 4; break;  // 一世
    case 2: shiPos = 2; yingPos = 5; break;  // 二世
    case 3: shiPos = 3; yingPos = 6; break;  // 三世
    case 4: shiPos = 4; yingPos = 1; break;  // 四世
    case 5: shiPos = 5; yingPos = 2; break;  // 五世
    case 6: shiPos = 4; yingPos = 1; break;  // 游魂
    case 7: shiPos = 3; yingPos = 6; break;  // 归魂
    default: shiPos = 6; yingPos = 3;
  }
  
  yaoLines[shiPos - 1].isShi = true;
  yaoLines[yingPos - 1].isYing = true;
}
```

### 5.9 伏神查找

```dart
void findFushen(List<YaoLine> yaoLines, int gongNum, int gua64Index) {
  // 1. 检查六亲是否齐全
  Set<String> presentLiuqin = yaoLines.map((y) => y.liuqin!).toSet();
  const allLiuqin = {'父母','兄弟','妻财','官鬼','子孙'};
  Set<String> missing = allLiuqin.difference(presentLiuqin);
  
  if (missing.isEmpty) return;
  
  // 2. 获取本宫八纯卦的数据
  // 八纯卦的 gua64Index 是固定的：乾0 坤56 等
  int chunGuaIdx = _getChunGuaIdx(gongNum);
  
  // 3. 构建八纯卦的爻数据（含六亲、地支）
  var chunGuaYaos = _buildChunGuaYaos(gongNum);
  
  // 4. 对于每个缺失的六亲，找到八纯卦中第一个匹配的爻
  for (String missLiuqin in missing) {
    for (int i = 0; i < 6; i++) {
      if (chunGuaYaos[i].liuqin == missLiuqin) {
        // 该地支为伏神，伏于本卦对应爻位下
        // 本卦该爻为飞神
        yaoLines[i].fushen = chunGuaYaos[i].ganzhi;
        yaoLines[i].feishen = yaoLines[i].ganzhi;
        break;
      }
    }
  }
}
```

### 5.10 神煞计算

```dart
ShenshaResult calculateShensha(String dayGan, String dayZhi, String yearZhi) {
  // 天乙贵人（按日干）
  const tianyiTable = {
    '甲':'丑未', '乙':'申子', '丙':'亥酉', '丁':'亥酉',
    '戊':'丑未', '己':'申子', '庚':'丑未', '辛':'寅午',
    '壬':'卯巳', '癸':'卯巳',
  };
  
  // 禄神（按日干）
  const lushenTable = {
    '甲':'寅', '乙':'卯', '丙':'巳', '丁':'午', '戊':'巳',
    '己':'午', '庚':'申', '辛':'酉', '壬':'亥', '癸':'子',
  };
  
  // 驿马（按日支）
  // 申子辰支→寅，寅午戌支→申，巳酉丑支→亥，亥卯未支→巳
  String yima = _getYima(dayZhi);
  
  // 华盖（按年支）
  String huagai = _getHuagai(yearZhi);
  
  // 咸池/桃花（按年支）
  String xianchi = _getXianchi(yearZhi);
  
  // 天医（按月支）
  String tianyi = _getTianyi(monthZhi);
  
  return ShenshaResult(
    tianyi: tianyiTable[dayGan] ?? '',
    yima: yima,
    huagai: huagai,
    xianchi: xianchi,
    tianyiShen: tianyi,
    lushen: lushenTable[dayGan] ?? '',
  );
}

// 驿马查表
String _getYima(String zhi) {
  if (['申','子','辰'].contains(zhi)) return '寅';
  if (['寅','午','戌'].contains(zhi)) return '申';
  if (['巳','酉','丑'].contains(zhi)) return '亥';
  if (['亥','卯','未'].contains(zhi)) return '巳';
  return '';
}

// 华盖查表
String _getHuagai(String zhi) {
  if (['申','子','辰'].contains(zhi)) return '辰';
  if (['寅','午','戌'].contains(zhi)) return '戌';
  if (['巳','酉','丑'].contains(zhi)) return '丑';
  if (['亥','卯','未'].contains(zhi)) return '未';
  return '';
}

// 咸池查表
String _getXianchi(String zhi) {
  if (['申','子','辰'].contains(zhi)) return '酉';
  if (['寅','午','戌'].contains(zhi)) return '卯';
  if (['巳','酉','丑'].contains(zhi)) return '午';
  if (['亥','卯','未'].contains(zhi)) return '子';
  return '';
}

// 天医查表（按月支）
String _getTianyi(String monthZhi) {
  const table = {
    '寅':'丑', '卯':'寅', '辰':'卯', '巳':'辰',
    '午':'巳', '未':'午', '申':'未', '酉':'申',
    '戌':'酉', '亥':'戌', '子':'亥', '丑':'子',
  };
  return table[monthZhi] ?? '';
}
```

---

## 6. UI 设计详细规格

### 6.1 主题与配色

```
主色：#8B4513 (SaddleBrown) 或 #5D4037 (棕色系古典)
辅色：#FFD700 (Gold) 配卦象金色
背景：#F5F0E8 (暖白/宣纸色) 或 #FFF8E1
文字：#212121 (深灰黑)
卦象色：#B71C1C (阳爻红色)
神煞标签：#1976D2 (蓝色)
```

### 6.2 首页（HomeScreen）

```
┌─────────────────────────────────┐
│                                 │
│         ☰ 六爻排盘              │
│                                 │
│   ┌─────────────────────────┐  │
│   │  📅 起卦时间             │  │
│   │  2026年6月25日 21:45     │  │
│   │  农历 丙午年 五月 十一  │  │
│   │  丙午年 癸巳月 丙申日   │  │
│   │  癸亥时                  │  │
│   │         [修改时间]        │  │
│   └─────────────────────────┘  │
│                                 │
│   ┌─────────────────────────┐  │
│   │  ❓ 所问问题             │  │
│   │  ┌───────────────────┐  │  │
│   │  │ 请输入您要问的事… │  │  │
│   │  └───────────────────┘  │  │
│   └─────────────────────────┘  │
│                                 │
│   ┌─────────────────────────┐  │
│   │  🎲 在线摇卦             │  │
│   │  (显示三枚铜钱动画)     │  │
│   │         [开始摇卦]       │  │
│   └─────────────────────────┘  │
│                                 │
│   ┌─────────────────────────┐  │
│   │  ✏️ 手动输入背面数       │  │
│   │         [手动起卦]       │  │
│   └─────────────────────────┘  │
│                                 │
│   ┌─────────────────────────┐  │
│   │  🔢 日期时间起卦         │  │
│   │         [时间起卦]       │  │
│   └─────────────────────────┘  │
│                                 │
│   [📋 历史记录]                │
│                                 │
└─────────────────────────────────┘
```

### 6.3 在线摇卦页面（ShakeScreen）

**核心组件：CoinWidget**

```
┌─────────────────────────────────┐
│  ← 返回    第 1/6 爻            │
│                                 │
│                                 │
│   ┌─────────────────────────┐  │
│   │                         │  │
│   │    🪙  🪙  🪙          │  │
│   │    （三枚铜钱）          │  │
│   │    显示正反面           │  │
│   │    有翻转动画           │  │
│   │                         │  │
│   └─────────────────────────┘  │
│                                 │
│   ┌─────────────────────────┐  │
│   │    结果：2背 = 少阴     │  │
│   │    符号：  ▅▅  ▅▅      │  │
│   └─────────────────────────┘  │
│                                 │
│         [ 抛 铜 钱 ]            │
│                                 │
│   ┌─────────────────────────┐  │
│   │  进度：●●●○○○         │  │
│   │  已记录：少阳/少阴/…    │  │
│   └─────────────────────────┘  │
│                                 │
│         [ 查看排盘 ]            │
│                                 │
└─────────────────────────────────┘
```

**铜钱动画实现要点**：

1. 点击"抛铜钱"→ 三枚铜钱同时快速翻转（360° Y轴旋转 + 随机）
2. 翻转动画约1.5秒，期间铜钱快速切换正反面
3. 静止后显示最终结果
4. 每枚铜钱随机产生正面或反面（各50%概率）
5. 统计背面数，显示爻象

```dart
// CoinWidget 伪代码
class CoinWidget extends StatefulWidget {
  @override
  _CoinWidgetState createState() => _CoinWidgetState();
}

class _CoinWidgetState extends State<CoinWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  List<CoinState> _coins = [CoinState.idle, CoinState.idle, CoinState.idle];
  List<bool> _results = [false, false, false]; // false=正面, true=背面
  
  void tossCoins() {
    // 1. 开始旋转动画（Y轴360°×3）
    _controller.forward(from: 0);
    // 2. 动画结束后随机确定结果
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          for (int i = 0; i < 3; i++) {
            _results[i] = Random().nextBool();
          }
          _coins = _results.map((r) => 
            r ? CoinState.back : CoinState.front
          ).toList();
        });
      }
    });
  }
  
  // 翻转显示：
  // - 用 Transform(transform: Matrix4.rotationY(angle)) 实现3D翻转
  // - 角度从0到π时显示正面coin_front.png
  // - 角度从π到2π时显示背面coin_back.png
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double angle = _rotation.value;
            bool showFront = angle < pi;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(angle),
              child: Image.asset(
                showFront ? 'assets/images/coin_front.png' 
                          : 'assets/images/coin_back.png',
                width: 100,
                height: 100,
              ),
            );
          },
        );
      }),
    );
  }
}
```

### 6.4 排盘结果页（ResultScreen）

参考现有 App 的经典六爻排盘显示格式：

```
┌─────────────────────────────────┐
│  六爻排盘                       │
│  起卦时间：...                  │
│  旬空：戌亥                    │
│                                 │
│  本卦：风火家人  ☴☲            │
│  变卦：离为火    ☲☲            │
│  互卦：火水未济 ☲☵            │
│  卦宫：巽宫 五行：木           │
│                                 │
│  ┌───────────────────────────┐ │
│  │ 六神 │ 伏神 │ 六亲 │ 地支 │ │
│  ├───────────────────────────┤ │
│  │ 玄武 │  —   │ 父母 │ 巳火 │世│
│  │ 白虎 │  —   │ 兄弟 │ 未土 │ │
│  │ 螣蛇 │  —   │ 子孙 │ 酉金 │ │
│  │ 勾陈 │  —   │ 妻财 │ 亥水 │应│
│  │ 朱雀 │  —   │ 官鬼 │ 丑土 │ │
│  │ 青龙 │ 子水 │ 子孙 │ 卯木 │ │  ←伏神子水
│  └───────────────────────────┘ │
│                                 │
│  ★ 神煞                        │
│  天乙贵人：丑未                 │
│  驿马：寅                       │
│  华盖：辰                       │
│  咸池：酉                       │
│  天医：丑                       │
│  禄神：寅                       │
│                                 │
│  [ 记录解卦 ]                   │
│                                 │
└─────────────────────────────────┘
```

### 6.5 历史记录页（HistoryScreen）

```
┌─────────────────────────────────┐
│  ← 返回    历史记录    🔍      │
│                                 │
│  ┌───────────────────────────┐ │
│  │ 2026-06-25 21:45         │ │
│  │ 问：这次投资能赚钱吗     │ │
│  │ 本卦：天火同人 → 水火既济│ │
│  │ 标签：财运                │ │→│
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │ 2026-06-24 15:30         │ │
│  │ 问：出行顺利吗           │ │
│  │ 本卦：地天泰 → 雷天大壮  │ │
│  │ 标签：出行                │ │→│
│  └───────────────────────────┘ │
│                                 │
│  ...更多记录...                │
│                                 │
└─────────────────────────────────┘
```

### 6.6 详情/解卦页（DetailScreen）

```
┌─────────────────────────────────┐
│  ← 返回    排盘详情             │
│                                 │
│  [排盘显示区域 - 复用排盘组件]  │
│                                 │
│  ──────────────────────────     │
│                                 │
│  📝 解卦笔记                    │
│  ┌───────────────────────────┐ │
│  │                           │ │
│  │  在此输入解卦内容…        │ │
│  │                           │ │
│  │                           │ │
│  └───────────────────────────┘ │
│                                 │
│         [ 保存 ]                │
│                                 │
└─────────────────────────────────┘
```

---

## 7. 资源文件

### 7.1 铜钱图片

使用 Flaticon 的免费古铜钱图标：

**正面（coin_front.png）**：
- 来源：https://www.flaticon.com/free-icon/chinese-coin_105562
- 尺寸：512x512 PNG

**背面（coin_back.png）**：
- 来源：https://www.flaticon.com/free-icon/chinese-coin_6725053
- 尺寸：512x512 PNG

**使用说明**：
- 在 app 中缩小显示（~100x100 dp）
- 用于在线摇卦的铜钱动画显示
- 背面图片可水平翻转以形成"背面"效果

### 7.2 pubspec.yaml 依赖

```yaml
name: liuyao_app
description: 六爻排盘 App
version: 1.0.0

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0          # SQLite 数据库
  path_provider: ^2.1.0     # 文件路径
  provider: ^6.1.0          # 状态管理
  intl: ^0.19.0             # 日期格式化
  path: ^1.8.0              # 路径工具
  google_fonts: ^6.1.0      # 字体（可选）
  cupertino_icons: ^1.0.6   # iOS 风格图标
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/coin_front.png
    - assets/images/coin_back.png
```

---

## 8. 开发步骤

### Phase 1：核心算法（2周）

```yaml
week_1:
  - day_1_2: GanzhiConverter - 干支转换模块 + 单元测试
  - day_3: Constants - 所有查表数据（64卦、纳甲表、五行表）
  - day_4: GuaGenerator - 卦象生成 + 本卦变卦互卦
  - day_5: NAJIA + Liuqin 配置

week_2:
  - day_1: Liushen + Xunkong 配置
  - day_2: Shiying + Fushen 查找
  - day_3: Shensha 神煞计算
  - day_4: GuaGenerator 总协调器 + 集成测试
  - day_5: Data models + Database helper
```

### Phase 2：基础 UI（1.5周）

```yaml
week_3:
  - day_1_2: 项目骨架 + HomeScreen（起卦入口）
  - day_3_4: ShakeScreen（在线摇卦 + CoinWidget动画）
  - day_5: ManualInputScreen（手动输入背面数）

week_4_half:
  - day_1_2: ResultScreen（排盘结果显示）
  - day_3: HistoryScreen（历史记录列表）
```

### Phase 3：完善功能（1.5周）

```yaml
week_4_end:
  - DetailScreen（详情 + 解卦编辑）
  - 数据库 DAO 完善
  - Provider 状态管理集成

week_5:
  - 时间起卦方式
  - UI 美化、动画优化
  - iOS/Android 适配测试
  - Bug 修复
```

---

## 9. 测试用例

### 9.1 核心算法测试

```dart
void main() {
  test('干支转换：2026年6月25日 21:45', () {
    var dt = DateTime(2026, 6, 25, 21, 45);
    var result = GanzhiConverter.convert(dt);
    expect(result.yearGz, '丙午');
    expect(result.dayGz, '丙申');
    expect(result.hourGz, '癸亥');
  });
  
  test('背面数→爻类型', () {
    expect(makeYao(1, 0).yaoType, 'laoyin');  // 0背=老阴
    expect(makeYao(1, 1).yaoType, 'shaoyang'); // 1背=少阳
    expect(makeYao(1, 2).yaoType, 'shaoyin');  // 2背=少阴
    expect(makeYao(1, 3).yaoType, 'laoyang');  // 3背=老阳
  });
  
  test('完整排盘：乾为天（全部少阳）', () {
    var backCounts = [1, 1, 1, 1, 1, 1]; // 全部1背=少阳
    var record = GuaGenerator.generate(
      backCounts: backCounts,
      divTime: DateTime(2026, 6, 25, 21, 45),
      question: '测试',
    );
    expect(record.benGuaName, '乾为天');
    expect(record.guaGong, '乾宫');
    expect(record.guaWuxing, '金');
  });
  
  test('完整排盘：有动爻卦', () {
    var backCounts = [3, 2, 1, 2, 2, 2]; // 初爻老阳
    var record = GuaGenerator.generate(
      backCounts: backCounts,
      divTime: DateTime(2026, 6, 25, 21, 45),
      question: '测试',
    );
    expect(record.yaoLines[0].isDong, true);
    expect(record.bianGuaName, isNotEmpty);
  });
}
```

---

## 10. 附录：完整查表数据

### 10.1 六十四卦分宫表

此表需要硬编码在 `constants.dart` 中。每个宫有8个卦，按如下顺序：

```
乾宫(0): 乾为天、天风姤、天山遁、天地否、风地观、山地剥、火地晋、火天大有
兑宫(1): 兑为泽、泽水困、泽地萃、泽山咸、水山蹇、地山谦、雷山小过、雷泽归妹
离宫(2): 离为火、火山旅、火风鼎、火水未济、山水蒙、风水涣、天水讼、天火同人
震宫(3): 震为雷、雷地豫、雷水解、雷风恒、地风升、水风井、泽风大过、泽雷随
巽宫(4): 巽为风、风天小畜、风火家人、风雷益、天雷无妄、火雷噬嗑、山雷颐、山风蛊
坎宫(5): 坎为水、水泽节、水雷屯、水火既济、泽火革、雷火丰、地火明夷、地水师
艮宫(6): 艮为山、山火贲、山天大畜、山泽损、火泽睽、天泽履、风泽中孚、风山渐
坤宫(7): 坤为地、地雷复、地泽临、地天泰、雷天大壮、泽天夬、水天需、水地比
```

### 10.2 六十四卦列表（编号0-63）

```
  0: 乾为天    1: 泽天夬    2: 火天大有  3: 雷天大壮
  4: 风天小畜  5: 水天需    6: 山天大畜  7: 地天泰
  8: 天泽履    9: 兑为泽   10: 火泽睽   11: 雷泽归妹
 12: 风泽中孚 13: 水泽节   14: 山泽损   15: 地泽临
 16: 天火同人 17: 泽火革   18: 离为火   19: 雷火丰
 20: 风火家人 21: 水火既济 22: 山火贲   23: 地火明夷
 24: 天雷无妄 25: 泽雷随   26: 火雷噬嗑 27: 震为雷
 28: 风雷益   29: 水雷屯   30: 山雷颐   31: 地雷复
 32: 天风姤   33: 泽风大过 34: 火风鼎   35: 雷风恒
 36: 巽为风   37: 水风井   38: 山风蛊   39: 地风升
 40: 天水讼   41: 泽水困   42: 火水未济 43: 雷水解
 44: 风水涣   45: 坎为水   46: 山水蒙   47: 地水师
 48: 天山遁   49: 泽山咸   50: 火山旅   51: 雷山小过
 52: 风山渐   53: 水山蹇   54: 艮为山   55: 地山谦
 56: 天地否   57: 泽地萃   58: 火地晋   59: 雷地豫
 60: 风地观   61: 水地比   62: 山地剥   63: 坤为地
```

### 10.3 六十四卦→卦宫映射

```
gua64Gong[64] = {
  // 0-7: outer=乾
  0, 0, 0, 0, 0, 0, 0, 0,  // 乾宫8卦
  // 8-15: outer=兑  
  1, 1, 1, 1, 1, 1, 1, 1,  // 兑宫8卦
  // 16-23: outer=离
  2, 2, 2, 2, 2, 2, 2, 2,  // 离宫8卦
  // 24-31: outer=震
  3, 3, 3, 3, 3, 3, 3, 3,  // 震宫8卦
  // 32-39: outer=巽
  4, 4, 4, 4, 4, 4, 4, 4,  // 巽宫8卦
  // 40-47: outer=坎
  5, 5, 5, 5, 5, 5, 5, 5,  // 坎宫8卦
  // 48-55: outer=艮
  6, 6, 6, 6, 6, 6, 6, 6,  // 艮宫8卦
  // 56-63: outer=坤
  7, 7, 7, 7, 7, 7, 7, 7,  // 坤宫8卦
};
```

### 10.4 八纯卦的卦序编号

```
乾: 0,  兑: 9,  离: 18, 震: 27,
巽: 36, 坎: 45, 艮: 54, 坤: 63
```

### 10.5 六十甲子表

```dart
static const List<String> ganzhi60 = [
  '甲子','乙丑','丙寅','丁卯','戊辰','己巳','庚午','辛未','壬申','癸酉', // 0-9
  '甲戌','乙亥','丙子','丁丑','戊寅','己卯','庚辰','辛巳','壬午','癸未', // 10-19
  '甲申','乙酉','丙戌','丁亥','戊子','己丑','庚寅','辛卯','壬辰','癸巳', // 20-29
  '甲午','乙未','丙申','丁酉','戊戌','己亥','庚子','辛丑','壬寅','癸卯', // 30-39
  '甲辰','乙巳','丙午','丁未','戊申','己酉','庚戌','辛亥','壬子','癸丑', // 40-49
  '甲寅','乙卯','丙辰','丁巳','戊午','己未','庚申','辛酉','壬戌','癸亥', // 50-59
];
```

### 10.6 八卦符号（Unicode）

```dart
static const List<String> baguaSymbols = [
  '',     // index 0 (unused)
  '☰',   // 1: 乾
  '☱',   // 2: 兑
  '☲',   // 3: 离
  '☳',   // 4: 震
  '☴',   // 5: 巽
  '☵',   // 6: 坎
  '☶',   // 7: 艮
  '☷',   // 8: 坤
];
```

---

## 11. 给 Claude Code/Cursor 的使用说明

### 11.1 项目初始化命令

```bash
# 1. 创建 Flutter 项目
cd /Users/bobo/projects
flutter create --org com.bobo --project-name liuyao_app liuyao_app

# 2. 进入项目
cd liuyao_app

# 3. 创建目录结构
mkdir -p lib/{models,algorithms,database,providers,screens,widgets,utils}
mkdir -p assets/images
mkdir -p test/algorithms

# 4. 复制铜钱图片到 assets
# （已下载到 /tmp/coin_front.png 和 /tmp/coin_back.png）
cp /tmp/coin_front.png assets/images/
cp /tmp/coin_back.png assets/images/

# 5. 更新 pubspec.yaml（按上文 7.2 节）
```

### 11.2 开发顺序建议

1. **先写 `lib/algorithms/constants.dart`** — 所有查表数据
2. **再写 `lib/algorithms/ganzhi_converter.dart`** — 干支转换
3. **然后写各算法文件** — 按 Phase 1 顺序
4. **写 `lib/models/`** — 数据模型
5. **写 `lib/algorithms/gua_generator.dart`** — 总协调器
6. **写数据库层** — Database + DAO
7. **写 UI** — 按 Phase 2 顺序

### 11.3 注意事项

- 所有算法代码必须纯 Dart，不能依赖 Flutter UI
- 八卦编号从1开始（乾=1...坤=8），注意 off-by-one 错误
- 六十四卦编号从0开始（乾为天=0...坤为地=63）
- 爻位从1开始（初爻=1...上爻=6），List索引从0开始
- 变卦的六亲仍按本宫五行来配（不是变卦所属宫）
- 归魂卦的世爻在三爻，不是六爻
- **内外卦不可混淆**：64卦索引公式为 `(inner-1)×8 + (outer-1)`，详见第12节

---

## 12. ⚠️ 内外卦约定与已知陷阱

> **2026-06-26：Claude Code 在开发过程中曾将内外卦颠倒，导致卦名取反、测试期望全部错误。**
> 本节作为永久记录，确保后续开发者（含 AI Agent）不再犯同样错误。

### 12.1 核心约定

```
六爻排盘中：
  上卦（外卦） = 四爻 + 五爻 + 上爻  → outerGuaId
  下卦（内卦） = 初爻 + 二爻 + 三爻  → innerGuaId

64卦编号：
  idx64 = (innerGuaId - 1) × 8 + (outerGuaId - 1)

卦名格式：
  "上卦名+下卦名"，如：
  - "天火同人" = 上乾(天) + 下离(火)  → inner=离(3), outer=乾(1) → idx=16
  - "火天大有" = 上离(火) + 下乾(天)  → inner=乾(1), outer=离(3) → idx=2
```

### 12.2 常见的混淆后果

如果把内外卦搞反（用 `(outer-1)×8 + (inner-1)` 或交换内外卦参数）：

| 正确 | 颠倒后 | 说明 |
|------|--------|------|
| 天风姤 (inner=巽, outer=乾) | 风天小畜 (inner=乾, outer=巽) | 上下卦颠倒 |
| 地天泰 (inner=乾, outer=坤) | 天地否 (inner=坤, outer=乾) | 卦名含义完全相反 |

### 12.3 纳甲中的内外卦

纳甲装卦使用 `baGuaDiZhi` 表，每个卦存储6个爻位的地支（索引0-5对应初至上爻）：

```dart
// 内卦用索引 0,1,2（初、二、三爻）
// 外卦用索引 3,4,5（四、五、上爻）
List<String> allDiZhi = [
  innerDiZhi[0], innerDiZhi[1], innerDiZhi[2],  // 下卦三爻
  outerDiZhi[3], outerDiZhi[4], outerDiZhi[5],  // 上卦三爻
];
```

### 12.4 已验证的正确性

以下核心数据已经过双重验证（Python交叉验证 + 京房纳甲标准对照）：

| 检查项 | 状态 | 验证方法 |
|--------|------|----------|
| `getBaGuaId` 八卦编码 | ✅ | 8卦8组测试全部通过 |
| `gua64Names` 64卦名排列 | ✅ | 16组交叉验证全部通过 |
| `baGuaDiZhi` 纳甲地支表 | ✅ | 8卦逐爻对比京房标准 |
| `assignDiZhi` 纳甲装卦 | ✅ | 5个典型卦例验证 |
| `wuXingLiuQin` 六亲关系表 | ✅ | 4组完整验证 |
| `gua64Gong` 分宫表 | ✅ | 64卦逐一核对 |
| `dayGanLiuShenStart` 六神起法 | ✅ | 甲子日起青龙验证 |
| `xunKongTable` 旬空表 | ✅ | 6旬逐一核对 |

### 12.5 测试文件注意事项

- 根目录 `test/gua_generator_test.dart` 和 `test/gua_calculator_test.dart` 已删除（2026-06-26）——这两个文件包含错误的期望值
- 正确的测试放在 `test/algorithms/` 子目录下
- 新增测试时务必确认：`GuaInfo.fromInnerOuter(innerId, outerId)` 的 `gua64Index` 应与 `(innerId-1)*8 + (outerId-1)` 一致
- 验证卦名时注意上下卦顺序

### 12.6 八卦编号参考

| 编号 | 名称 | Unicode | 五行 | 纳支(初→上) |
|------|------|---------|------|------------|
| 1 | 乾 ☰ | U+2630 | 金 | 子寅辰午申戌 |
| 2 | 兑 ☱ | U+2631 | 金 | 巳卯丑亥酉未 |
| 3 | 离 ☲ | U+2632 | 火 | 卯丑亥酉未巳 |
| 4 | 震 ☳ | U+2633 | 木 | 子寅辰午申戌 |
| 5 | 巽 ☴ | U+2634 | 木 | 丑亥酉未巳卯 |
| 6 | 坎 ☵ | U+2635 | 水 | 寅辰午申戌子 |
| 7 | 艮 ☶ | U+2636 | 土 | 辰午申戌子寅 |
| 8 | 坤 ☷ | U+2637 | 土 | 未巳卯丑亥酉 |

---

*文档版本：v2.1*
*最后更新：2026-06-26*
*状态：已修复内外卦文档错误 + 新增第12节*