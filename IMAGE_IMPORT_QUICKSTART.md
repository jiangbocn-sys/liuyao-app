# 六爻排盘图像识别功能 - 快速集成指南

> 5 分钟完成集成

---

## 步骤 1: 添加依赖

`pubspec.yaml` 已更新，运行：

```bash
cd /Users/bobo/projects/liuyao-app
flutter pub get
```

---

## 步骤 2: 配置 API Key

编辑 `lib/screens/image_import_screen.dart`，替换 API Key：

```dart
// 第 23 行
static const String _apiKey = 'YOUR_BAILIAN_API_KEY_HERE';
```

获取 API Key：
1. 登录 [阿里云百炼](https://bailian.aliyun.com/)
2. 创建 API Key
3. 复制粘贴到代码中

---

## 步骤 3: 配置权限

### iOS - `ios/Runner/Info.plist`

在 `<dict>` 内添加：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄排盘图片</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要从相册选择排盘图片</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存排盘图片</string>
```

### Android - `android/app/src/main/AndroidManifest.xml`

在 `<manifest>` 内添加：

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

---

## 步骤 4: 添加入口

在主界面（如 `home_screen.dart`）添加按钮：

```dart
import 'screens/image_import_screen.dart';

// 在合适的位置添加
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

---

## 步骤 5: 运行测试

```bash
flutter run
```

---

## 文件结构

新添加的文件：

```
lib/
├── models/
│   └── image_recognition_result.dart    # 识别结果模型
├── services/
│   └── image_recognition_service.dart   # 识别服务
└── screens/
    └── image_import_screen.dart         # 导入页面

docs/
└── IMAGE_IMPORT_SPEC.md                 # 完整开发文档
```

---

## 功能说明

### 支持的识别内容

| 字段 | 说明 |
|------|------|
| 性别 | 男/女 |
| 占问内容 | 所问事项 |
| 公历/农历时间 | 起卦时间 |
| 四柱干支 | 年柱、月柱、日柱、时柱 |
| 本卦/变卦 | 卦名 |
| 六神 | 青龙、朱雀等 |
| 六亲 | 父母、官鬼等 |
| 地支 | 子、寅、辰等 |
| 旬空 | 空亡地支 |
| 世应 | 世爻和应爻位置 |
| 动爻 | 动爻位置 |
| 神煞 | 驿马、桃花等 |

### 使用流程

1. 点击"拍照导入"
2. 选择拍照或从相册选择
3. 点击"开始识别"
4. 查看识别结果
5. 确认无误后保存

---

## 注意事项

1. **API 费用**: Qwen-VL-Max 按 token 计费，约 ¥0.003-0.006/次
2. **图片质量**: 清晰的排盘图片识别准确率更高
3. **网络要求**: 需要联网调用 API

---

## 后续优化

- [ ] 实现保存到数据库逻辑（`_saveToDatabase` 方法）
- [ ] 添加图片裁剪功能
- [ ] 支持批量导入
- [ ] 添加识别结果编辑功能
- [ ] 使用安全存储保存 API Key

---

有问题随时问我！
