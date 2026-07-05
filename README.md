# 🌫️ 雾化胖东来 - iOS App

iPad mini 5 离线商品展示App（iOS 14.8.1 / 巨魔TrollStore）

## 功能

- ✅ 商店名称可编辑（文字、字体大小、颜色）
- ✅ 公告栏（可编辑文字、字体大小、颜色，无图标）
- ✅ 分类管理（全部分类 + 自定义添加/编辑/删除，每分类独立字体/颜色设置）
- ✅ 商品展示（大图 + 名称 + 价格）
- ✅ 网格布局可调（2~5排自动调整格口大小）
- ✅ 双击商品图片放大，再双击缩小/关闭
- ✅ 管理后台（编辑所有内容）
- ✅ 整体主题色可自定义
- ✅ 价格显示/隐藏开关
- ✅ 导出数据备份（分享 JSON 文件）
- ✅ 完全离线，数据存本地
- ✅ 支持相册导入图片

## 下载IPA

1. 去 GitHub Actions 页面：https://github.com/hellodajidali/UnicornStore/actions
2. 选择最新的 workflow run
3. 下载 `雾化胖东来-IPA` 工件
4. 用 TrollStore 安装即可

## 本地构建（需要Mac + Xcode）

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 生成 Xcode 项目
xcodegen generate --spec project.yml

# 3. 打开 Xcode（项目名：雾化胖东来.xcodeproj）
open 雾化胖东来.xcodeproj

# 4. 选择目标: iOS Device (不要选模拟器)
# 5. Build -> Archive 导出 IPA
```

## 管理后台入口

在App主界面右上角点击「管理」按钮进入管理后台。

可以：
- 编辑商店名称（文字、字体大小、颜色）
- 编辑公告内容（字体大小、颜色）
- 添加/编辑/删除分类（每分类独立字体大小/颜色）
- 添加/编辑/删除商品
- 调整网格列数（2~5排）
- 显示/隐藏价格
- 自定义整体主题色
- 导出数据备份（分享文件）

## 技术支持

- SwiftUI (iOS 14+)
- 本地JSON持久化存储
- 无需网络连接
- 适配 iPad mini 5
