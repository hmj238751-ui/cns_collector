# CNS Paper Collector (Personal Edition)

> My personal daily-driver with custom memory, hardcoded paths, and workflow optimizations from 30+ real paper collections. Public portable version: [cns-paper-collector](https://github.com/hmj238751-ui/cns-paper-collector).

A Claude Code skill that automates academic paper collection: fetches WeChat articles, extracts paper metadata, opens PDF download pages, renames files, and packages them into a ZIP.

**You send a WeChat link. Claude does the rest. You just click Download.**

---

## What it does

```
WeChat article / DOI / title → Claude extracts metadata → opens PDF in your browser → you click Download → ZIP on your Desktop
```

- Reads WeChat official account articles (mp.weixin.qq.com) via dynamic browser
- Extracts paper titles, DOIs, journals, and dates from article text + journal screenshots (OCR)
- Downloads Open Access PDFs automatically (curl)
- Opens paywalled PDF pages in a new Chrome window for you to download
- Renames PDFs to a standardized format: `YYYY-Journal-Title.pdf`
- Packages everything into `SMOOTH_YYYYMMDD.zip` on your Desktop

**~50 seconds for 4 papers. You only click the download button.**

---

## Prerequisites

| Requirement | How to check | How to install |
|-------------|-------------|----------------|
| **Claude Code** | Run `claude --help` | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| **scrapling** | Run `scrapling --help` | See [scrapling setup](#scrapling-setup) below |
| **Google Chrome** | macOS: `/Applications/Google Chrome.app` | [google.com/chrome](https://www.google.com/chrome/) |
| **Playwright browsers** | `playwright install chromium` | Bundled with scrapling setup |
| **curl** | Run `curl --version` | Pre-installed on macOS/Linux |
| **macOS 13+** (OCR) | Run `swift --version` | Built-in on macOS. Linux: see [Linux OCR](#linux-ocr) |

### scrapling setup

scrapling is the engine that fetches WeChat articles and extracts metadata. It's the most complex dependency — here's the complete setup:

**macOS:**
```bash
# 1. Ensure you're using Homebrew Python 3.12 (scrapling requires it)
/opt/homebrew/opt/python@3.12/bin/python3.12 -m pip install --break-system-packages scrapling[all]

# 2. Install Playwright's browser
playwright install chromium

# 3. Verify
scrapling --help
```

**Linux (Debian/Ubuntu):**
```bash
# 1. Install system dependencies
sudo apt install python3.12 python3.12-pip

# 2. Install scrapling
pip install scrapling[all]

# 3. Install Playwright dependencies and browser
playwright install-deps chromium
playwright install chromium

# 4. Verify
scrapling --help
```

**Why scrapling?** WeChat pages are entirely JavaScript-rendered. Static HTTP clients (curl, requests) return empty HTML shells — there's no article content to parse. scrapling launches a real Chrome browser, renders the full page including all JavaScript, and extracts the rendered content. It also handles TLS fingerprinting, anti-bot headers, and Cloudflare challenges for journal sites.

scrapling is MIT-licensed open source. See [ATTRIBUTION.md](ATTRIBUTION.md) for full copyright details.

**Troubleshooting scrapling:**

| Problem | Solution |
|---------|----------|
| `pip: command not found` | Use `pip3` or `python3 -m pip` |
| `error: externally-managed-environment` (macOS Homebrew) | Add `--break-system-packages` flag |
| `No module named 'scrapling'` after install | Check you're using the correct Python: `which python3` |
| `BrowserType.launch: Executable doesn't exist` | Run `playwright install chromium` |
| `PyObjC` build fails during install | Not critical — the core features still work without `camoufox` |

---

## Installation

### Method 1: git clone (recommended)

```bash
git clone https://github.com/hmj238751-ui/cns-paper-collector.git ~/.claude/skills/cns-paper-collector/
```

Then tell Claude: `请用 cns-paper-collector 这个 skill。`

### Method 2: Direct download (if you can't use git)

```bash
# Download the skill file directly
mkdir -p ~/.claude/skills/cns-paper-collector/
curl -sL -o ~/.claude/skills/cns-paper-collector/SKILL.md \
  https://raw.githubusercontent.com/hmj238751-ui/cns-paper-collector/main/SKILL.md
curl -sL -o ~/.claude/skills/cns-paper-collector/ocr_image.swift \
  https://raw.githubusercontent.com/hmj238751-ui/cns-paper-collector/main/ocr_image.swift
```

### Method 3: GitHub ZIP download

1. Go to `https://github.com/hmj238751-ui/cns-paper-collector`
2. Click the green `Code` button → `Download ZIP`
3. Unzip to `~/.claude/skills/cns-paper-collector/`

### Method 4: One-liner (macOS)

```bash
mkdir -p ~/.claude/skills/cns-paper-collector/ && cd ~/.claude/skills/cns-paper-collector/ && curl -sLO https://raw.githubusercontent.com/hmj238751-ui/cns-paper-collector/main/SKILL.md && curl -sLO https://raw.githubusercontent.com/hmj238751-ui/cns-paper-collector/main/ocr_image.swift && echo "Done. Tell Claude: /cns-paper-collector"
```

---

## Usage

Start a Claude Code session and send a WeChat article link:

```
claude
> https://mp.weixin.qq.com/s/oB9qCK7bBLEY54JHt7KRDw
```

Or use the slash command:

```
/cns-paper-collector https://mp.weixin.qq.com/s/... https://mp.weixin.qq.com/s/...
```

Claude will:
1. Fetch the article content
2. Extract the paper title, journal, and DOI
3. Open the PDF download page in Chrome
4. Ask you to click "Download PDF"
5. Rename and package everything into a ZIP on your Desktop

---

## Supported publishers

| Publisher | Auto-download | Notes |
|-----------|:---:|-------|
| Nature (flagship) OA | Yes | curl with `Accept: application/pdf` |
| Nature Communications | Yes | Open Access |
| Scientific Reports | Yes | Open Access |
| Nature paywalled | No | Opens in Chrome for institutional login |
| Science | No | Opens in Chrome after Cloudflare |
| **Cell Press** | **No** | Cloudflare is impenetrable — always manual |
| bioRxiv / medRxiv | Yes | No protection |
| Genome Biology | Yes | BMC Open Access |
| Oxford Academic | Sometimes | Try curl, fallback to Chrome |

---

## Skill architecture

```
Input (WeChat/DOI/title)
  │
  ├─ Phase 0: Metadata extraction
  │   ├─ DOI embedded in URL → extract directly
  │   ├─ WeChat article → scrapling dynamic browser → scan DOI / OCR screenshot
  │   └─ Title only → batch Crossref API lookup
  │
  ├─ Phase 1: PDF download
  │   ├─ Cache check → skip if already downloaded
  │   ├─ curl (OA journals) → validate %PDF- header
  │   ├─ Chrome new window (paywalled) → user clicks download
  │   └─ Give up (Cell.com)
  │
  └─ Phase 2: Rename & package
      └─ YYYY-Journal-Title.pdf → SMOOTH_YYYYMMDD.zip → Desktop
```

---

## Linux OCR

The macOS OCR script (`ocr_image.swift`) uses Apple Vision framework. Linux users should install `tesseract` instead:

```bash
sudo apt install tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim
tesseract screenshot.png stdout
```

Tell Claude to use `tesseract` instead of `swift ocr_image.swift` when on Linux.

---

## Windows notes

- Replace `open -a "Google Chrome"` with `start chrome`
- Replace `~/Desktop/` with `%USERPROFILE%\Desktop\`
- Replace `~/Downloads/` with `%USERPROFILE%\Downloads\`
- scrapling may require WSL or Git Bash (not tested on native Windows)
- The OCR script is macOS-only; Windows users need `tesseract` via WSL or skip OCR

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "scrapling: command not found" | `pip install scrapling[all]` |
| WeChat captcha on fetch | Claude staggers requests by 2-3s. If still failing, increase stagger. |
| curl returns 406 | Paper is paywalled. Opens in Chrome instead. |
| Cell paper can't download | Expected. Cell.com blocks all programmatic access. Open in Chrome. |
| OCR not working (Linux) | Install tesseract. See [Linux OCR](#linux-ocr). |
| ZIP not on Desktop | Check custom download paths. The skill uses `~/Downloads/` and `~/Desktop/`. |

---

## Contributing

This skill was originally built and battle-tested over ~30 real-world paper collections across Nature, Science, Cell, and bioRxiv.

Found a publisher pattern that works? A new anti-bot bypass? Open an issue or PR.

---

## Credits

This skill orchestrates several open-source tools. See [ATTRIBUTION.md](ATTRIBUTION.md) for full copyright details.

- **scrapling** — Web scraping engine (MIT) — [github.com/scrapling/scrapling](https://github.com/scrapling/scrapling)
- **Playwright** — Browser automation (Apache 2.0) — [playwright.dev](https://playwright.dev)
- **Apple Vision** — macOS OCR framework (Apple Inc.)
- **Crossref API** — Academic metadata — [crossref.org](https://www.crossref.org)
- **curl** — HTTP client — [curl.se](https://curl.se)

## License

MIT © [hmj238751-ui](https://github.com/hmj238751-ui)
