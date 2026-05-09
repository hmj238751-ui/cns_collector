# cns_collector

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Release](https://img.shields.io/badge/release-v1.00-blue)](https://github.com/hmj238751-ui/cns_collector/releases)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)]()

每周从微信收集 10-20 篇 CNS 论文，发链接 → 自动提取元数据 → 下载 PDF → 重命名 → 打包 ZIP 到桌面。已经稳定运行数十次。你只需要点一下下载按钮。

---

## 📊 Workflow

```
  WeChat link / DOI / title
         │
         ▼
  ┌──────────────────────────────────────┐
  │  Phase 0: Metadata Extraction        │
  │  DOI scan → OCR screenshot → Crossref │
  └──────────────────┬───────────────────┘
                     ▼
  ┌──────────────────────────────────────┐
  │  Phase 1: PDF Download               │
  │  Cache → curl (OA) → Chrome (paywall)│
  └──────────────────┬───────────────────┘
                     ▼
  ┌──────────────────────────────────────┐
  │  Phase 2: Rename & Package           │
  │  YYYY-Journal-Title.pdf → ZIP → Desktop│
  └──────────────────────────────────────┘
```

---

## 🎯 Skill 触发词

在 Claude Code 中，以下任意方式均可触发本 skill：

| 触发方式 | 示例 |
|---------|------|
| 微信链接 | `https://mp.weixin.qq.com/s/...` |
| 命令 | `/cns-paper-collector url1 url2` |
| 关键词 | `汇总这几篇文章` `帮我下载这篇` `加入今天的汇总` |
| DOI | `10.1038/s41586-026-10476-w` |
| 期刊链接 | `nature.com/articles/...` |
| 下载确认 | `ok了` `下载好了` `完成了` |

## 🔧 Environment Configuration

### Prerequisites

| Requirement | Check | This machine |
|-------------|-------|:---:|
| Claude Code | `claude --help` | ✓ |
| scrapling 0.2.99+ | `scrapling --help` | ✓ |
| Homebrew Python 3.12 | `/opt/homebrew/opt/python@3.12/bin/python3.12` | ✓ |
| Google Chrome | `/Applications/Google Chrome.app` | ✓ |
| Playwright | `playwright install chromium` | ✓ |
| Swift 5.9+ (OCR) | `swift --version` | ✓ |
| curl | `curl --version` | ✓ |

### Setup (first time on a new machine)

```bash
# 1. Install scrapling
/opt/homebrew/opt/python@3.12/bin/python3.12 -m pip install --break-system-packages scrapling[all]

# 2. Playwright browser
playwright install chromium

# 3. Clone this skill
git clone https://github.com/hmj238751-ui/cns_collector.git ~/.claude/skills/cns-paper-collector/

# 4. Verify
claude --help && scrapling --help && swift --version && echo "Ready"
```

---

## 🚀 Quick Start

```bash
claude
> https://mp.weixin.qq.com/s/...
```

Or batch:
```
/cns-paper-collector url1 url2 url3
```

---

## 💾 Installation

```bash
git clone https://github.com/hmj238751-ui/cns_collector.git ~/.claude/skills/cns-paper-collector/
```

Direct download:
```bash
mkdir -p ~/.claude/skills/cns-paper-collector/
curl -sL -o ~/.claude/skills/cns-paper-collector/skill.md \
  https://raw.githubusercontent.com/hmj238751-ui/cns_collector/main/skill.md
curl -sL -o ~/.claude/skills/cns-paper-collector/ocr_image.swift \
  https://raw.githubusercontent.com/hmj238751-ui/cns_collector/main/ocr_image.swift
```

---

## 🧠 持久记忆（可选）

本 skill 支持 Claude Code 的持久记忆功能。使用过程中，Claude 会自动记录你的偏好（如下载路径、命名习惯、常用出版商策略），存储在本地 `~/.claude/projects/` 目录中。这些文件不上传到 GitHub，仅存在于你的机器上。

如果你从头开始使用，不需要任何记忆文件——skill 本身已经包含所有必要的规则。记忆只是让使用体验越来越好。

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

## ❓ Troubleshooting

| Problem | Fix |
|---------|-----|
| `scrapling: command not found` | `pip install scrapling[all]` via Homebrew Python 3.12 |
| WeChat captcha | Increase stagger to 3-4s |
| Nature 406 | Paywalled — Chrome instead |
| Cell fails | Expected — always manual |

---

## 📝 Citation

```bibtex
@software{cns_paper_collector_personal,
  author    = {hmj238751-ui},
  title     = {CNS Paper Collector (Personal Edition)},
  year      = {2026},
  url       = {https://github.com/hmj238751-ui/cns_collector}
}
```

## 📄 License & Credits

This skill orchestrates: scrapling (MIT), Playwright (Apache 2.0), Apple Vision, Crossref API, curl. See [ATTRIBUTION.md](ATTRIBUTION.md).

**CNS Paper Collector**: MIT © [hmj238751-ui](https://github.com/hmj238751-ui)
