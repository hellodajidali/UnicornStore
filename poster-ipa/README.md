# 图文海报（Poster）

把一段文字做成图片，直接发微信朋友圈。TrollStore 安装，配置和独角商店一致（同仓库 Actions 出 IPA，无签名）。

## 功能

- **文字生成图片**：编辑文字 → 点「生成」→ 系统分享面板（选微信 或 存储图像）
- **文字样式**：字号、粗细（细/常规/中/粗/特粗）、颜色、对齐、行距
  - **选中文字 = 只改选中的部分**，**不选中 = 改全部文字**
- **文字模板**：把当前画布存成模板（文字 + 样式 + 背景 + 贴图全保存），点一下就套用，套用后还能随便改
- **贴图**：从相册选图，拖到任意位置、双指缩放；也可以点「贴图」用滑块精确调大小/旋转
- **画布**：3:4 / 4:5 / 1:1 / 9:16 / 自动高度，背景纯色或渐变，边距可调
- 自动存草稿（关掉 App 再打开还在）

## 文件结构

```
poster-ipa/
├── project.yml                     # XcodeGen 配置
├── Poster/
│   ├── Info.plist                  # 显示名「图文海报」
│   ├── PosterApp.swift             # 入口
│   ├── Models/Models.swift         # 数据模型 + 富文本编解码 + 颜色/图片工具
│   ├── Services/PosterStore.swift  # 草稿与模板本地存储
│   ├── Services/PosterRenderer.swift # Core Graphics 出图（和预览同一宽度，断行一致）
│   ├── Views/EditorView.swift      # 主界面：画布 + 工具栏
│   ├── Views/RichTextEditor.swift  # UITextView 封装，局部样式核心
│   ├── Views/StickerLayer.swift    # 贴图拖拽/缩放层
│   ├── Views/TemplateListView.swift# 模板列表
│   └── Views/PhotoPickerView.swift # 相册选图 + 分享面板
└── .github/workflows/build-poster.yml
```

## 关键实现点

1. **局部样式**：用 `UITextView` + `NSAttributedString`。有选区改选区，无选区改全文（`targetRange`）。样式同时写 `.font` + 自定义属性 `PosterWeight`（记录 0-4 字重），导出时才不会丢粗细。
2. **出图与预览一致**：`PosterRenderer.render(width: 编辑画布逻辑宽度)`，用同一个宽度、同样的字号画，断行完全一致；`format.scale = 3` 只是放大分辨率。
3. **存盘**：富文本存三份（NSKeyedArchiver 归档 / RTF / 纯文本），读取时依次降级，任何一份坏了文字都还在。
4. **文字溢出**：固定比例画布下文字超长时，顶部出现「导出会缩小到 xx%」，可点「一键适配」把字号实际缩小；导出时也会自动缩放兜底。
5. **分享**：UIImage 直传 `UIActivityViewController`，不写临时文件、不申请相册权限（独角商店踩过的坑）。

## 打包

push 到 main 后 GitHub Actions 自动构建：`.github/workflows/build-poster.yml` → 产物 `Poster-IPA`。
Windows 本机无法编译 Swift，只能走 Actions。
