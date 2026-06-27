/// 图像识别服务
/// 使用多模态 LLM (Qwen-VL) 识别排盘图片

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/image_recognition_result.dart';

/// 图像识别服务
class ImageRecognitionService {
  /// 百炼 API Key
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
      const totalFields = 18;
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
        return value
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((v) => v > 0)
            .toList();
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
