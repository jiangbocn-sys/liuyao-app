# 六爻排盘图像识别导入功能开发文档

> 创建日期：2026-06-27
> 版本：v1.0
> 功能：通过拍照或图片识别，自动导入排盘数据

---

## 一、功能概述

### 目标
用户可以通过以下方式导入已有的六爻排盘：
1. **拍照识别** - 使用手机摄像头拍摄排盘图片
2. **相册选择** - 从手机相册选择排盘图片
3. **图像识别** - 自动识别图片中的排盘信息并解析

### 识别内容
图像中需要识别的字段：

| 字段 | 说明 | 示例 |
|------|------|------|
| 性别 | 求测者性别 | 男/女 |
| 占问内容 | 所问事项 | 问事业/问感情/问财运 |
| 公历时间 | 起卦的公历时间 | 2026-06-27 14:30 |
| 农历时间 | 起卦的农历时间 | 丙午年五月十三日未时 |
| 干支 | 年柱、月柱、日柱、时柱 | 丙午 甲午 己卯 辛未 |
| 本卦 | 主卦名称和卦象 | 乾为天 |
| 变卦 | 变卦名称（如有动爻） | 天风姤 |
| 六神 | 六爻对应的六神 | 青龙、朱雀、勾陈、螣蛇、白虎、玄武 |
| 六亲 | 六爻对应的六亲 | 父母、官鬼、妻财、兄弟、子孙 |
| 神煞 | 神煞信息 | 驿马、桃花、贵人等 |
| 旬空 | 空亡地支 | 戌亥空亡 |
| 世应 | 世爻和应爻位置 | 六爻持世 |

---

## 二、技术方案

### 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                      Flutter App                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │
│  │  拍照/选图   │  │  图像预处理  │  │   结果展示/编辑  │   │
│  │   模块      │  │   模块      │  │     模块        │   │
│  └─────────────┘  └─────────────┘  └─────────────────┘   │
│         │                │                  │           │
│         └────────────────┼──────────────────┘           │
│                          │                              │
│  ┌───────────────────────┴───────────────────────────┐   │
│  │              图像识别服务 (ImageRecognitionService)  │   │
│  │  ┌─────────────────────────────────────────────┐ │   │
│  │  │           多模态 LLM API (Qwen-VL)          │ │   │
│  │  │  - 图像理解                                  │ │   │
│  │  │  - 文字识别 (OCR)                            │ │   │
│  │  │  - 结构化提取                                │ │   │
│  │  └─────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 技术选型

| 组件 | 技术 | 说明 |
|------|------|------|
| 图像获取 | `image_picker` | Flutter 官方图片选择插件 |
| 图像裁剪 | `image_cropper` | 可选，用于裁剪排盘区域 |
| 图像识别 | Qwen-VL-Max | 阿里云百炼多模态大模型 |
| 数据存储 | SQLite | 复用现有数据库 |

---

## 三、数据模型

### 识别结果模型

```dart
// lib/models/image_recognition_result.dart

import 'divination_record.dart';

/// 图像识别结果
class ImageRecognitionResult {
  /// 是否识别成功
  final bool success;
  
  /// 错误信息（识别失败时）
  final String? errorMessage;
  
  /// 识别到的原始文本（用于调试）
  final String? rawText;
  
  /// 解析后的排盘数据
  final ParsedDivinationData? data;
  
  /// 置信度（0-1）
  final double confidence;
  
  /// 需要人工确认的字段列表
  final List<String>? needsConfirmation;

  ImageRecognitionResult({
    required this.success,
    this.errorMessage,
    this.rawText,
    this.data,
    this.confidence = 0.0,
    this.needsConfirmation,
  });

  factory ImageRecognitionResult.success({
    required ParsedDivinationData data,
    String? rawText,
    double confidence = 0.0,
    List<String>? needsConfirmation,
  }) {
    return ImageRecognitionResult(
      success: true,
      data: data,
      rawText: rawText,
      confidence: confidence,
      needsConfirmation: needsConfirmation,
    );
  }

  factory ImageRecognitionResult.failure(String errorMessage) {
    return ImageRecognitionResult(
      success: false,
      errorMessage: errorMessage,
      confidence: 0.0,
    );
  }
}

/// 解析后的排盘数据
class ParsedDivinationData {
  /// 性别
  final String? gender;
  
  /// 占问内容
  final String? question;
  
  /// 公历时间
  final DateTime? gregorianTime;
  
  /// 农历时间字符串
  final String? lunarTime;
  
  /// 年柱干支
  final String? yearGanZhi;
  
  /// 月柱干支
  final String? monthGanZhi;
  
  /// 日柱干支
  final String? dayGanZhi;
  
  /// 时柱干支
  final String? hourGanZhi;
  
  /// 本卦名称
  final String? benGuaName;
  
  /// 变卦名称（可选）
  final String? bianGuaName;
  
  /// 六神列表（从下往上：初爻到上爻）
  final List<String>? liuShen;
  
  /// 六亲列表（从下往上）
  final List<String>? liuQin;
  
  /// 地支列表（从下往上）
  final List<String>? diZhi;
  
  /// 旬空地支
  final List<String>? xunKong;
  
  /// 世爻位置（1-6）
  final int? shiPosition;
  
  /// 应爻位置（1-6）
  final int? yingPosition;
  
  /// 动爻位置列表（1-6）
  final List<int>? dongYaoPositions;
  
  /// 神煞信息
  final Map<String, List<String>>? shenSha;

  ParsedDivinationData({
    this.gender,
    this.question,
    this.gregorianTime,
    this.lunarTime,
    this.yearGanZhi,
    this.monthGanZhi,
    this.dayGanZhi,
    this.hourGanZhi,
    this.benGuaName,
    this.bianGuaName,
    this.liuShen,
    this.liuQin,
    this.diZhi,
    this.xunKong,
    this.shiPosition,
    this.yingPosition,
    this.dongYaoPositions,
    this.shenSha,
  });

  /// 转换为 DivinationRecord（用于保存到数据库）
  DivinationRecord? toDivinationRecord() {
    // 验证必要字段
    if (benGuaName == null || dayGanZhi == null) {
      return null;
    }
    
    // TODO: 实现转换逻辑
    return null;
  }

  /// 检查哪些字段缺失
  List<String> getMissingFields() {
    final missing = <String>[];
    if (gender == null) missing.add('性别');
    if (gregorianTime == null && lunarTime == null) missing.add('时间');
    if (dayGanZhi == null) missing.add('日柱');
    if (benGuaName == null) missing.add('本卦');
    if (liuShen == null || liuShen!.length != 6) missing.add('六神');
    if (liuQin == null || liuQin!.length != 6) missing.add('六亲');
    if (diZhi == null || diZhi!.length != 6) missing.add('地支');
    return missing;
  }
}
```

---

## 四、服务层

### 图像识别服务

```dart
// lib/services/image_recognition_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/image_recognition_result.dart';

/// 图像识别服务
class ImageRecognitionService {
  /// 百炼 API Key（从配置读取）
  final String _apiKey;
  
  /// API 地址
  static const String _apiUrl = 
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation';

  ImageRecognitionService({required String apiKey}) : _apiKey = apiKey;

  /// 识别排盘图片
  /// 
  /// [imagePath] - 图片文件路径
  /// [onProgress] - 进度回调（可选）
  Future<ImageRecognitionResult> recognizePaipan(
    String imagePath, {
    void Function(String stage)? onProgress,
  }) async {
    try {
      onProgress?.call('读取图片...');
      
      // 读取图片并转为 base64
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return ImageRecognitionResult.failure('图片文件不存在');
      }
      
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      onProgress?.call('识别中...');
      
      // 构建提示词
      final prompt = _buildRecognitionPrompt();
      
      // 调用多模态 API
      final response = await _callQwenVL(base64Image, prompt);
      
      onProgress?.call('解析结果...');
      
      // 解析响应
      return _parseResponse(response);
      
    } catch (e) {
      return ImageRecognitionResult.failure('识别失败: $e');
    }
  }

  /// 构建识别提示词
  String _buildRecognitionPrompt() {
    return '''
请仔细识别这张六爻排盘图片，提取以下信息并以 JSON 格式返回：

需要提取的字段：
1. gender: 性别（男/女）
2. question: 占问内容（所问事项）
3. gregorian_time: 公历时间（格式：YYYY-MM-DD HH:mm）
4. lunar_time: 农历时间（如：丙午年五月十三日未时）
5. year_gan_zhi: 年柱干支（如：丙午）
6. month_gan_zhi: 月柱干支（如：甲午）
7. day_gan_zhi: 日柱干支（如：己卯）
8. hour_gan_zhi: 时柱干支（如：辛未）
9. ben_gua: 本卦名称（如：乾为天）
10. bian_gua: 变卦名称（如有动爻，如：天风姤）
11. liu_shen: 六神列表，从下往上（初爻到上爻），如：["青龙","朱雀","勾陈","螣蛇","白虎","玄武"]
12. liu_qin: 六亲列表，从下往上，如：["父母","兄弟","子孙","妻财","官鬼","父母"]
13. di_zhi: 地支列表，从下往上，如：["子","寅","辰","午","申","戌"]
14. xun_kong: 旬空地支列表，如：["戌","亥"]
15. shi_position: 世爻位置（1-6，从初爻开始计数）
16. ying_position: 应爻位置（1-6）
17. dong_yao_positions: 动爻位置列表（如：[1,3] 表示初爻和三爻动）
18. shen_sha: 神煞信息对象，如：{"驿马":["申"],"桃花":["子"],"贵人":["丑","未"]}

重要规则：
- 六爻顺序：初爻(1)在最下，上爻(6)在最上
- 如果某字段无法识别，设为 null
- 确保返回的是标准 JSON 格式
- 卦名使用标准名称，如"乾为天"、"天风姤"等

请只返回 JSON 数据，不要包含其他说明文字。
''';
  }

  /// 调用 Qwen-VL API
  Future<Map<String, dynamic>> _callQwenVL(
    String base64Image,
    String prompt,
  ) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'qwen-vl-max',
        'input': {
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'image': 'data:image/jpeg;base64,$base64Image',
                },
                {
                  'text': prompt,
                },
              ],
            },
          ],
        },
        'parameters': {
          'max_tokens': 2048,
          'temperature': 0.1, // 低温度，提高准确性
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API 请求失败: ${response.statusCode} ${response.body}');
    }

    return jsonDecode(response.body);
  }

  /// 解析 API 响应
  ImageRecognitionResult _parseResponse(Map<String, dynamic> response) {
    try {
      // 提取文本内容
      final choices = response['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        return ImageRecognitionResult.failure('API 返回格式异常');
      }

      final content = choices[0]['message']['content'] as String?;
      if (content == null || content.isEmpty) {
        return ImageRecognitionResult.failure('识别结果为空');
      }

      // 提取 JSON 部分
      final jsonStr = _extractJson(content);
      if (jsonStr == null) {
        return ImageRecognitionResult.failure('无法解析识别结果');
      }

      // 解析 JSON
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // 构建 ParsedDivinationData
      final data = _buildParsedData(json);
      
      // 检查缺失字段
      final missingFields = data.getMissingFields();
      
      // 计算置信度（基于完整度）
      final totalFields = 18;
      final filledFields = totalFields - missingFields.length;
      final confidence = filledFields / totalFields;

      return ImageRecognitionResult.success(
        data: data,
        rawText: content,
        confidence: confidence,
        needsConfirmation: missingFields.isNotEmpty ? missingFields : null,
      );

    } catch (e) {
      return ImageRecognitionResult.failure('解析失败: $e');
    }
  }

  /// 从文本中提取 JSON
  String? _extractJson(String text) {
    // 尝试找到 JSON 代码块
    final codeBlockPattern = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = codeBlockPattern.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim();
    }

    // 尝试找到普通 JSON 对象
    final jsonPattern = RegExp(r'\{[\s\S]*\}');
    final jsonMatch = jsonPattern.firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0);
    }

    // 直接返回文本（可能是纯 JSON）
    if (text.trim().startsWith('{')) {
      return text.trim();
    }

    return null;
  }

  /// 构建解析后的数据
  ParsedDivinationData _buildParsedData(Map<String, dynamic> json) {
    // 解析时间
    DateTime? gregorianTime;
    if (json['gregorian_time'] != null) {
      try {
        gregorianTime = DateTime.parse(json['gregorian_time'] as String);
      } catch (_) {
        // 忽略解析错误
      }
    }

    // 解析列表字段
    List<String>? parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }

    // 解析动爻位置
    List<int>? parseIntList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => int.tryParse(e.toString()) ?? 0).toList();
      }
      return null;
    }

    // 解析神煞
    Map<String, List<String>>? parseShenSha(dynamic value) {
      if (value == null) return null;
      if (value is Map) {
        final result = <String, List<String>>{};
        for (final entry in value.entries) {
          final key = entry.key.toString();
          final val = entry.value;
          if (val is List) {
            result[key] = val.map((e) => e.toString()).toList();
          }
        }
        return result;
      }
      return null;
    }

    return ParsedDivinationData(
      gender: json['gender'] as String?,
      question: json['question'] as String?,
      gregorianTime: gregorianTime,
      lunarTime: json['lunar_time'] as String?,
      yearGanZhi: json['year_gan_zhi'] as String?,
      monthGanZhi: json['month_gan_zhi'] as String?,
      dayGanZhi: json['day_gan_zhi'] as String?,
      hourGanZhi: json['hour_gan_zhi'] as String?,
      benGuaName: json['ben_gua'] as String?,
      bianGuaName: json['bian_gua'] as String?,
      liuShen: parseStringList(json['liu_shen']),
      liuQin: parseStringList(json['liu_qin']),
      diZhi: parseStringList(json['di_zhi']),
      xunKong: parseStringList(json['xun_kong']),
      shiPosition: json['shi_position'] as int?,
      yingPosition: json['ying_position'] as int?,
      dongYaoPositions: parseIntList(json['dong_yao_positions']),
      shenSha: parseShenSha(json['shen_sha']),
    );
  }
}
```

---

## 五、UI 层

### 1. 图像导入页面

```dart
// lib/screens/image_import_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/image_recognition_result.dart';
import '../services/image_recognition_service.dart';

/// 图像导入页面
class ImageImportScreen extends StatefulWidget {
  const ImageImportScreen({super.key});

  @override
  State<ImageImportScreen> createState() => _ImageImportScreenState();
}

class _ImageImportScreenState extends State<ImageImportScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  ImageRecognitionResult? _recognitionResult;
  bool _isRecognizing = false;
  String _progressText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照导入排盘'),
        actions: [
          if (_selectedImage != null)
            TextButton(
              onPressed: _clearImage,
              child: const Text('清除'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图片选择区域
            _buildImageSelector(),
            
            const SizedBox(height: 24),
            
            // 识别按钮
            if (_selectedImage != null && !_isRecognizing)
              ElevatedButton.icon(
                onPressed: _startRecognition,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('开始识别'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            
            // 进度指示
            if (_isRecognizing) _buildProgressIndicator(),
            
            const SizedBox(height: 24),
            
            // 识别结果
            if (_recognitionResult != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  /// 构建图片选择器
  Widget _buildImageSelector() {
    if (_selectedImage != null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.file(
              _selectedImage!,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _clearImage,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '选择排盘图片',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '支持拍照或从相册选择',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('拍照'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('相册'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建进度指示器
  Widget _buildProgressIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_progressText),
          ],
        ),
      ),
    );
  }

  /// 构建结果区域
  Widget _buildResultSection() {
    final result = _recognitionResult!;
    
    if (!result.success) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    '识别失败',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(result.errorMessage ?? '未知错误'),
            ],
          ),
        ),
      );
    }

    final data = result.data!;
    final missingFields = result.needsConfirmation ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 识别成功提示
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      '识别成功',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '置信度: ${(result.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                if (missingFields.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '以下字段需要确认: ${missingFields.join(', ')}',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 识别结果编辑表单
        _buildResultForm(data),

        const SizedBox(height: 24),

        // 保存按钮
        ElevatedButton.icon(
          onPressed: _saveToDatabase,
          icon: const Icon(Icons.save),
          label: const Text('保存到记录'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  /// 构建结果编辑表单
  Widget _buildResultForm(ParsedDivinationData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '识别结果',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 基本信息
            _buildInfoRow('性别', data.gender ?? '未识别'),
            _buildInfoRow('占问', data.question ?? '未识别'),
            _buildInfoRow('公历时间', data.gregorianTime?.toString() ?? '未识别'),
            _buildInfoRow('农历时间', data.lunarTime ?? '未识别'),
            
            const Divider(),
            
            // 干支信息
            _buildInfoRow('年柱', data.yearGanZhi ?? '未识别'),
            _buildInfoRow('月柱', data.monthGanZhi ?? '未识别'),
            _buildInfoRow('日柱', data.dayGanZhi ?? '未识别'),
            _buildInfoRow('时柱', data.hourGanZhi ?? '未识别'),
            
            const Divider(),
            
            // 卦象信息
            _buildInfoRow('本卦', data.benGuaName ?? '未识别'),
            _buildInfoRow('变卦', data.bianGuaName ?? '无'),
            _buildInfoRow('旬空', data.xunKong?.join(', ') ?? '未识别'),
            _buildInfoRow('世爻', '第${data.shiPosition}爻'),
            _buildInfoRow('应爻', '第${data.yingPosition}爻'),
            _buildInfoRow('动爻', data.dongYaoPositions?.map((p) => '第$p爻').join(', ') ?? '无'),
            
            const Divider(),
            
            // 六爻详情
            const Text('六爻详情:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildYaoTable(data),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建六爻表格
  Widget _buildYaoTable(ParsedDivinationData data) {
    final liuShen = data.liuShen ?? List.filled(6, '未识别');
    final liuQin = data.liuQin ?? List.filled(6, '未识别');
    final diZhi = data.diZhi ?? List.filled(6, '未识别');
    
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FixedColumnWidth(60),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
      },
      children: [
        // 表头
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('爻位', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('六神', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('六亲', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('地支', textAlign: TextAlign.center),
            ),
          ],
        ),
        // 六爻数据（从上往下显示）
        for (int i = 5; i >= 0; i--)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _getYaoName(i + 1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: data.shiPosition == i + 1 || 
                               data.yingPosition == i + 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: data.shiPosition == i + 1 
                        ? Colors.red 
                        : data.yingPosition == i + 1 
                            ? Colors.blue 
                            : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(liuShen[i], textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(liuQin[i], textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(diZhi[i], textAlign: TextAlign.center),
              ),
            ],
          ),
      ],
    );
  }

  String _getYaoName(int position) {
    const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
    return names[position - 1];
  }

  // ========== 事件处理 ==========

  /// 拍照
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
        _recognitionResult = null;
      });
    }
  }

  /// 从相册选择
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _recognitionResult = null;
      });
    }
  }

  /// 清除图片
  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _recognitionResult = null;
    });
  }

  /// 开始识别
  Future<void> _startRecognition() async {
    if (_selectedImage == null) return;

    setState(() {
      _isRecognizing = true;
      _progressText = '准备识别...';
    });

    // TODO: 从配置读取 API Key
    final service = ImageRecognitionService(
      apiKey: 'YOUR_API_KEY_HERE',
    );

    final result = await service.recognizePaipan(
      _selectedImage!.path,
      onProgress: (stage) {
        setState(() {
          _progressText = stage;
        });
      },
    );

    setState(() {
      _isRecognizing = false;
      _recognitionResult = result;
    });
  }

  /// 保存到数据库
  Future<void> _saveToDatabase() async {
    // TODO: 实现保存逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存成功')),
    );
    Navigator.pop(context);
  }
}
```

---

## 六、依赖配置

### pubspec.yaml 添加依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 图像选择
  image_picker: ^1.0.7
  
  # HTTP 请求
  http: ^1.2.0
  
  # 图片处理（可选）
  image_cropper: ^5.0.1
  
  # 路径处理
  path_provider: ^2.1.2
  
  # 缓存管理
  cached_network_image: ^3.3.1
```

### iOS 配置

`ios/Runner/Info.plist` 添加相机和相册权限：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄排盘图片</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要从相册选择排盘图片</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存排盘图片</string>
```

### Android 配置

`android/app/src/main/AndroidManifest.xml` 添加权限：

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

---

## 七、集成到现有 App

### 1. 在主界面添加入口

修改 `lib/screens/home_screen.dart`（或主页面）：

```dart
// 在首页添加"拍照导入"按钮
FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImageImportScreen(),
      ),
    );
  },
  icon: const Icon(Icons.camera_alt),
  label: const Text('拍照导入'),
),
```

### 2. API Key 配置

在 `lib/config/app_config.dart` 中添加：

```dart
class AppConfig {
  /// 百炼 API Key
  static const String bailianApiKey = 'YOUR_API_KEY_HERE';
  
  /// 或使用环境变量/安全存储
  static Future<String> getApiKey() async {
    // 从安全存储读取
    // return await SecureStorage.read('bailian_api_key');
    return bailianApiKey;
  }
}
```

---

## 八、测试用例

### 测试场景

| 场景 | 输入 | 期望结果 |
|------|------|----------|
| 标准排盘图 | 清晰的排盘截图 | 正确识别所有字段 |
| 模糊图片 | 低分辨率排盘图 | 提示清晰度不足 |
| 部分信息 | 只有卦象的图片 | 识别可用字段，标记缺失 |
| 非排盘图 | 普通照片 | 识别失败，提示非排盘图片 |
| 手写排盘 | 手写卦象图片 | 尝试识别，可能需人工确认 |

### 示例测试图片

准备以下测试图片：
1. 标准排盘 App 截图
2. 网页排盘截图
3. 纸质排盘照片
4. 手写排盘照片

---

## 九、注意事项

### 1. API 费用
- Qwen-VL-Max 按 token 计费
- 建议设置使用限制或提示用户

### 2. 隐私保护
- 图片上传前可进行压缩
- 敏感信息（如 API Key）使用安全存储

### 3. 离线支持
- 考虑添加离线模式（仅手动输入）
- 网络异常时友好提示

### 4. 识别准确性
- 复杂排盘可能需要人工确认
- 提供编辑功能修正识别结果

---

## 十、后续优化

### Phase 2 计划
1. **本地模型** - 使用 ONNX 模型本地识别，减少 API 依赖
2. **批量导入** - 支持同时识别多张图片
3. **历史对比** - 识别后可与历史记录对比
4. **智能纠错** - 根据六爻规则自动修正识别错误

---

*文档版本：v1.0*
*最后更新：2026-06-27*
