# 🦄 独角商店 - UnicornStore

iPad mini 5 离线商品展示App（iOS 14.8.1 / 巨魔TrollStore）

## 功能

- ✅ 顶部横幅（可编辑文字/图片）
- ✅ 公告栏（自动调整高度，无边框线）
- ✅ 分类管理（全部分类 + 自定义添加/编辑/删除）
- ✅ 商品展示（大图 + 名称 + 价格）
- ✅ 网格布局可调（2~5排自动调整格口大小）
- ✅ 双击图片放大，再双击回退
- ✅ 管理后台（编辑所有内容）
- ✅ 价格显示/隐藏开关
- ✅ 完全离线，数据存本地
- ✅ 支持相册导入图片

## 下载IPA

1. 去 GitHub Actions 页面：https://github.com/hellodajidali/UnicornStore/actions
2. 选择最新的 workflow run
3. 下载 `UnicornStore-IPA` 工件
4. 用 TrollStore 安装即可

## 本地构建（需要Mac + Xcode）

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 生成 Xcode 项目
xcodegen generate --spec project.yml

# 3. 打开 Xcode
open UnicornStore.xcodeproj

# 4. 选择目标: iOS Device (不要选模拟器)
# 5. Build -> Archive 导出 IPA
```

## 管理后台入口

在App主界面右上角点击「管理」按钮进入管理后台。

可以：
- 编辑顶部横幅文字/图片
- 编辑公告内容
- 添加/编辑/删除分类
- 添加/编辑/删除商品
- 调整网格列数（2~5排）
- 显示/隐藏价格
- 导出数据备份

## 技术支持

- SwiftUI (iOS 14+)
- 本地JSON持久化存储
- 无需网络连接
- 适配 iPad mini 5
