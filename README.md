# cns_collector

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Release](https://img.shields.io/badge/release-v1.00-blue)](https://github.com/hmj238751-ui/cns_collector/releases)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)]()

每周从微信收集 10-20 篇 CNS 论文，发链接 → 自动提取元数据 → 下载 PDF → 重命名 → 打包 ZIP 到桌面。已经稳定运行数十次。你只需要点一下下载按钮。

---

## 🎯 主要功能

- **微信文章解析** — 用 scrapling 动态浏览器渲染 JS 页面，curl 拿不到的内容全部提取
- **多路径元数据提取** — DOI 扫描 → 期刊截图 OCR → 英文引文标题 → Crossref API，四层兜底
- **智能下载** — 缓存检查 → OA 文章 curl 全自动 → 付费文章 Chrome 半自动 → Cell 认输
- **反爬策略矩阵** — 各出版商不同策略：Cloudflare 绕过、TLS 指纹、验证码规避
- **统一重命名** — `YYYY-Journal-Title.pdf` 格式，自动去非法字符
- **一键打包** — 全部 PDF 压成 `SMOOTH_YYYYMMDD.zip` 输出到桌面
- **批量并行** — 十几篇文章一次性发链接，全部并行处理
- **持久记忆** — 自动记住你的下载偏好、命名习惯、常用出版商

---

## 📊 工作流

```
  微信链接 / DOI / 期刊链接
         │
         ▼
  ┌──────────────────────────────┐
  │  Phase 0: 提取元数据         │
  │  DOI 扫描 → OCR 截图 → Crossref│
  └──────────────┬───────────────┘
                 ▼
  ┌──────────────────────────────┐
  │  Phase 1: 下载 PDF           │
  │  缓存 → curl (全自动) → Chrome│
  └──────────────┬───────────────┘
                 ▼
  ┌──────────────────────────────┐
  │  Phase 2: 重命名 & 打包      │
  │  YYYY-Journal-Title.pdf → ZIP│
  └──────────────────────────────┘
```

---

## 🎯 Skill 触发词

在 Claude Code 中，以下任意方式均可触发本 skill：

| 触发方式 | 示例 |
|---------|------|
| **微信链接** | `https://mp.weixin.qq.com/s/...` |
| **期刊文章链接** | `nature.com/articles/...` `cell.com/cell/...` `science.org/doi/...` `biorxiv.org/content/...` |
| **DOI** | `10.1038/s41586-026-10476-w` |
| **命令** | `/cns_collector url1 url2` |
| **汇总类** | `汇总` `汇总这几篇` `加入今天的汇总` `帮我汇总一下` |
| **下载类** | `帮我下载这篇` `把这个也打包` `一起打包` |
| **收集类** | `收集这几篇论文` `整理这些文章` `帮我整理一下` |
| **下载确认** | `ok了` `下载好了` `完成了` `好了` `下好了` |

> 单独发一个微信链接或说一个"汇总"就能触发，不需要完整命令。

---

## 🔧 环境配置

### 前置条件

| 组件 | 检查命令 |
|------|---------|
| Claude Code | `claude --help` |
| scrapling 0.2.99+ | `scrapling --help` |
| Homebrew Python 3.12 | `/opt/homebrew/opt/python@3.12/bin/python3.12` |
| Google Chrome | `/Applications/Google Chrome.app` |
| Playwright | `playwright install chromium` |
| Swift 5.9+ (OCR) | `swift --version` |
| curl | `curl --version` |

### 首次配置

```bash
# 1. 安装 scrapling（微信页面渲染引擎）
/opt/homebrew/opt/python@3.12/bin/python3.12 -m pip install --break-system-packages scrapling[all]

# 2. 安装 Playwright 浏览器
playwright install chromium

# 3. 克隆本 skill
git clone https://github.com/hmj238751-ui/cns_collector.git ~/.claude/skills/cns-paper-collector/

# 4. 验证
claude --help && scrapling --help && swift --version && echo "就绪"
```

---

## 💾 安装

```bash
git clone https://github.com/hmj238751-ui/cns_collector.git ~/.claude/skills/cns-paper-collector/
```

无 git 环境：

```bash
mkdir -p ~/.claude/skills/cns-paper-collector/
curl -sL -o ~/.claude/skills/cns-paper-collector/skill.md \
  https://raw.githubusercontent.com/hmj238751-ui/cns_collector/main/skill.md
curl -sL -o ~/.claude/skills/cns-paper-collector/ocr_image.swift \
  https://raw.githubusercontent.com/hmj238751-ui/cns_collector/main/ocr_image.swift
```

---

## 🚀 使用

```bash
claude
> https://mp.weixin.qq.com/s/...
```

或批量：

```
/cns_collector url1 url2 url3
```

---

## 📖 支持的出版商

| 出版商 | 模式 | 说明 |
|--------|:----:|------|
| Nature OA / Nat Commun / Sci Reports | 🟢 全自动 | curl 直接下载，无需用户操作 |
| Nature 付费 | 🟡 半自动 | Chrome 打开页面，用户通过机构登录后点下载 |
| Science | 🟡 半自动 | Chrome 打开，用户通过 Cloudflare 验证后下载 |
| Cell Press | 🟡 半自动 | Chrome 打开页面，用户手动点下载按钮（Cloudflare 太强，无法程序化） |
| bioRxiv / medRxiv | 🟢 全自动 | curl 直接下载 |
| Genome Biology | 🟢 全自动 | BMC OA，curl 直接下载 |
| Oxford Academic | 🟡 半自动 | 先尝试 curl，失败则 Chrome |

> **半自动 = Claude 帮你打开期刊页面，你点一下下载按钮。不需要搜 DOI、找链接、重命名、打包。**

---

## 🧠 持久记忆（可选）

本 skill 支持 Claude Code 的持久记忆功能。使用过程中，Claude 会自动记录你的偏好（如下载路径、命名习惯、常用出版商策略），存储在本地 `~/.claude/projects/` 目录中。这些文件不上传到 GitHub，仅存在于你的机器上。

如果你从头开始使用，不需要任何记忆文件——skill 本身已经包含所有必要的规则。记忆只是让使用体验越来越好。

---

## ❓ 常见问题

| 问题 | 解决 |
|------|------|
| `scrapling: command not found` | 用 Homebrew Python 3.12 安装，见上方环境配置 |
| 微信验证码 | 请求间隔增加到 3-4 秒 |
| Nature 返回 406 | 付费文章——改用 Chrome |
| Cell 下载失败 | 正常——Cell 的 Cloudflare 无法程序化突破 |

---

## 📝 引用

```bibtex
@software{cns_collector,
  author    = {hmj238751-ui},
  title     = {cns_collector: 微信文献自动收集工具},
  year      = {2026},
  url       = {https://github.com/hmj238751-ui/cns_collector}
}
```

---

## 📄 许可与鸣谢

本 skill 调度以下开源工具：

| 工具 | 许可 | 引用 |
|------|------|------|
| scrapling | BSD-3-Clause | 研究用途请引用 [Karim Shoair (2024)](https://github.com/D4Vinci/Scrapling) |
| Playwright | Apache 2.0 | Microsoft |
| Crossref API | 免费 | [crossref.org](https://www.crossref.org) |
| Apple Vision | macOS SDK | Apple Inc. |
| curl | curl license | [curl.se](https://curl.se) |

详见 [ATTRIBUTION.md](ATTRIBUTION.md)。

MIT © [hmj238751-ui](https://github.com/hmj238751-ui)
