# 六爻排盘 - Bug 跟踪

> 最后更新：2026-06-26

---

## ✅ 已修复：#12 — Claude Code 内外卦混淆导致卦名错误

**发现日期**：2026-06-26

**问题**：Claude Code 在编写代码和测试时，混淆了内外卦（inner/outer）的对应关系，导致：
1. `DEVELOPMENT_SPEC.md` 中伪代码的64卦索引公式写成 `(outer-1)×8+(inner-1)`（正确是 `(inner-1)×8+(outer-1)`）
2. 测试文件 `test/gua_generator_test.dart` 和 `test/gua_calculator_test.dart` 中的期望值全部错误（如期望"风天小畜"实际应为"天风姤"）
3. 纳甲装卦文档中内卦和外卦的地支索引写错

**修复**：
- ✅ 删除了根目录的两个错误测试文件
- ✅ 修正了 `test/algorithms/gua_generator_test.dart` 中的期望值
- ✅ 修正了 `DEVELOPMENT_SPEC.md` 中所有索引公式和纳甲示例代码
- ✅ 在 `DEVELOPMENT_SPEC.md` 新增第12节：内外卦约定与已知陷阱
- ✅ 在 `README.md` 中添加了重要约定说明

**验证**：运行 Python 交叉验证脚本（`/tmp/verify_liuyao.py`），8大类检查全部通过。

**根因**：Claude Code 在处理六爻排盘这种领域知识密集型任务时，未能正确理解"内卦/下卦"与"外卦/上卦"的对应关系及在索引公式中的角色。

---

## 🔴 #11：节气 — 内置表 + 在线更新 + Meeus 兜底

**三步策略**：
1. App 内置 `assets/jieqi_table.json`（1900-2100, 305KB）
2. 年份不够 → 提示用户更新 → 一键下载新表
3. 没网络 → Meeus 算法兜底

**shouxing_calendar.dart 已实现**：
```dart
static Map<int, List<JieQiData>> _table = {};
static int _maxYear = 0;

static Future<void> init() async {
  // 1. 优先加载用户下载的新表（path_provider → Documents）
  // 2. 回退到内置 assets/jieqi_table.json
  // 3. 解析 JSON → _table
}

static bool needsUpdate(int year) => year > _maxYear;
static List<JieQiData> getJieQiList(int year) {
  if (_table.containsKey(year)) return _table[year]!;
  return _meeusCalculate(year);  // Meeus 兜底
}
```

**Meeus 公式保留**（sunLongitude/findJdByAngle 不删）
**表文件已就位**：`assets/jieqi_table.json`（1900-2100, 305KB）
