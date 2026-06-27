/// OCR排盘识别服务
/// 使用Google ML Kit进行本地文字识别，无需API Key配置

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import '../models/image_recognition_result.dart';
import 'paipan_parser.dart';

/// OCR排盘识别服务
/// 完全本地运行，不需要网络和API Key
class OCRPaipanService {
  /// 中文文字识别器
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

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

      // 检查图片是否存在
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return ImageRecognitionResult.failure('图片文件不存在');
      }

      onProgress?.call('OCR识别中...');

      // 准备图片输入
      final inputImage = InputImage.fromFilePath(imagePath);

      // 执行文字识别
      final recognizedText = await _textRecognizer.processImage(inputImage);

      onProgress?.call('解析排盘数据...');

      // 获取识别的文字
      final rawText = recognizedText.text;

      // Debug: 打印原始OCR文本到日志
      print('========== OCR原始文本 START ==========');
      print(rawText);
      print('========== OCR原始文本 END ==========');

      // Debug: 保存原始文本到文件
      await _saveRawTextToFile(rawText);

      if (rawText.isEmpty) {
        return ImageRecognitionResult.failure('未能识别到任何文字');
      }

      // 解析排盘数据
      final parser = PaipanParser();
      final result = parser.parse(rawText, recognizedText.blocks);

      return result;

    } catch (e) {
      print('OCR识别错误: $e');
      return ImageRecognitionResult.failure('识别失败: $e');
    }
  }

  /// 保存原始OCR文本到文件（用于调试）
  Future<void> _saveRawTextToFile(String rawText) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ocr_raw_text.txt');
      await file.writeAsString(rawText);
      print('OCR原始文本已保存到: ${file.path}');
    } catch (e) {
      print('保存OCR文本失败: $e');
    }
  }

  /// 获取保存的原始OCR文本文件路径
  Future<String?> getRawTextFilePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/ocr_raw_text.txt';
    } catch (e) {
      return null;
    }
  }

  /// 关闭识别器（释放资源）
  void close() {
    _textRecognizer.close();
  }
}