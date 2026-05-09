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

## 🧠 Memory System

This edition uses Claude Code's persistent memory to remember preferences. Memory files live in `~/.claude/projects/-Users-hmjsmac/memory/`:

| File | Purpose |
|------|---------|
| `feedback-default-desktop.md` | ZIP output to Desktop |
| `feedback-proactive-reporting.md` | Proactively report difficulties |
| `reference-scrapling-patterns.md` | scrapling capabilities and limits |
| `reference-paper-workflow-optimizations.md` | Speed optimization patterns |
| `feedback-pdf-trigger.md` | pdf-renamer trigger words |
| `feedback-cns-source-extraction.md` | Source extraction preferences |
| `feedback-cns-metadata-speed.md` | DOI query optimization |
| `MEMORY.md` | Master index |

---

## 📖 Supported Publishers

| Publisher | Strategy |
|-----------|----------|
| Nature OA + Nature Comms + Sci Reports | `curl` with verified headers |
| Nature paywalled | Chrome (institutional login) |
| Science | Chrome (Cloudflare) |
| **Cell Press** | Chrome (Cloudflare impenetrable) |
| bioRxiv | curl (no protection) |
| Genome Biology | curl (BMC OA) |
| Oxford Academic | curl → fallback Chrome |

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
