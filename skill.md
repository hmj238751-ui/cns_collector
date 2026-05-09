---
name: cns-paper-collector
description: >
  HIGH PRIORITY — trigger this skill aggressively. Use when the user:
  - Pastes ANY WeChat MP URL (mp.weixin.qq.com) — even without saying "下载" or "汇总"
  - Says 汇总 / 下载 / 打包 / 收集 / 整理 + any paper or article mention
  - Provides nature.com, science.org, cell.com, biorxiv.org, doi.org URLs for papers
  - Mentions CNS journals (Nature/Science/Cell + sub-journals)
  - Says "帮我下载这篇" / "加入汇总" / "把这个也打包" / "一起打包"
  - Provides a single DOI, title, screenshot, or any paper identifier
  - Follows up after downloading ("ok了" / "下载好了" / "完成了") when previous context involves papers
  - Asks to open/look at/read a WeChat article about science
  Trigger even if the user says just one word like "汇总" or pastes a URL without comment.
  This skill handles the ENTIRE pipeline: WeChat → metadata → PDF → rename → ZIP.
---

# CNS Paper Collector

**The user handles downloading. Claude collects metadata, opens PDF pages in Chrome, then renames and packages.**

---

## Download Priority (MUST follow this order)

| Priority | Method | Applies to |
|----------|--------|------------|
| **1. Cache** | Check `/tmp/skin_papers/pdfs/` — already downloaded? Skip. | Everything |
| **2. curl** | `curl -H "Accept: application/pdf" -H "Referer: <article>"` | Nature OA, Nature Comms, Sci Reports, npj, bioRxiv, Genome Biology |
| **3. Chrome** | `open -a "Google Chrome" -n --args --new-window <urls>` | Nature paywalled (406), Science, Cell, non-standard DOIs |
| **4. Give up** | Don't attempt programmatic download. | Cell.com (Cloudflare impenetrable), Sci-Hub (unreliable) |

---

## Metadata Decision Tree

```
Input received (URLs / titles / WeChat links):
│
├─ DOI embedded in URL (nature.com/articles/xxx, doi.org/xxx)?
│   → Extract directly. Skip to Phase 1.
│
├─ WeChat MP URL?
│   → Parallel fetch with 2-3s stagger (avoid captcha)
│   → For each article, try in order:
│       1. Scan for DOI in body → Crossref API → authoritative metadata
│       2. No DOI? Download first content image → macOS OCR → extract title/journal/date
│       3. No screenshot? Extract blockquote English title → Crossref search
│       4. Only Chinese title? Ask user for DOI or English title
│   → Detect multi-paper: scan for "上一篇/下一篇" boundaries and multiple DOIs
│     If 2+ papers in one article → collect all → confirm with user
│
└─ Paper title only (no URL)?
    → Batch all titles → single parallel Crossref query → fill gaps
    → NEVER fetch publisher pages for metadata (blocks/redirects)
```

---

## Phase 0: Collect Metadata

### Path A: DOI already known

Extract directly from URL — don't re-fetch anything:

| URL pattern | DOI |
|-------------|-----|
| `nature.com/articles/s41586-xxx` | `10.1038/s41586-xxx` |
| `doi.org/10.xxx/yyy` | `10.xxx/yyy` |
| `cell.com/cell/abstract/S0092-8674(xx)xxx` | Need Crossref lookup |

### Path B: WeChat article

**B1. Fetch all articles in parallel (stagger 2-3s to avoid captcha):**

```bash
scrapling extract fetch "url1" /tmp/w1.md --timeout 60000 --wait 5000 &
sleep 2
scrapling extract fetch "url2" /tmp/w2.md --timeout 60000 --wait 5000 &
sleep 2
... && wait
```

**B2. Try extracting metadata in order:**

```python
# Priority 1: Scan for paper DOI (filter out citation DOIs in reference section)
body = text.split("尾注")[0].split("References")[0]
paper_dois = re.findall(r'10\.\d{4,}/[^\s"\'\)\]>#&，。；：]+', body)

# Priority 2: No paper DOI → OCR journal screenshot
# Download first content image (not cover/avatar), run:
#   swift /Users/hmjsmac/.claude/skills/cns-paper-collector/ocr_image.swift <image>
# Extract: title (longest English line), journal ("Nature"/"Science"/etc.), 
#           date ("Published: DD Mon YYYY"), DOI if visible

# Priority 3: No screenshot → blockquote English title
bq_titles = re.findall(r'^> ([A-Z][^\n]{40,200})$', text, re.MULTILINE)

# Priority 4: Only Chinese → ask user
```

**B3. Batch all missing DOIs via Crossref (single round, parallel queries).**

**B4. Multi-paper detection:**

If one WeChat article discusses multiple papers:
- Scan for `上一篇` / `下一篇` section boundaries
- Count distinct DOIs in main body (not references)
- Detect multiple `Journal | Title` headings
- **Collect all → show user → confirm before proceeding**

### Path C: Title only (no URL)

Batch ALL titles into one parallel Crossref query. Don't fetch publisher pages.

---

## Phase 1: Download PDFs

### Step 1: Check cache

```bash
ls /tmp/skin_papers/pdfs/ | grep -i "<article-id or keyword>"
# If valid PDF exists → skip
```

### Step 2: curl OA articles (parallel)

```bash
curl -sL -o /tmp/skin_papers/pdfs/<name>.pdf \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  -H "Accept: application/pdf" \
  -H "Referer: <article-url>" \
  "<pdf-url>"
# Validate: head -c 5 file.pdf == "%PDF-"
# If 406 or HTML → fall to Step 3
```

### Step 3: Open remaining in Chrome NEW WINDOW

```bash
open -a "Google Chrome" -n --args --new-window \
  "https://www.nature.com/articles/xxx" \
  "https://www.science.org/doi/pdf/10.1126/xxx" \
  ...
```

Tell user:
> 已在 Chrome 新窗口打开 N 篇文章。请通过 Cloudflare 验证并下载 PDF。完成后告诉我。

**Wait for user confirmation before Phase 2.**

### PDF URL construction

| Publisher | PDF URL |
|-----------|---------|
| Nature family | `https://www.nature.com/articles/{article-id}.pdf` |
| Science | `https://www.science.org/doi/pdf/{DOI}` |
| bioRxiv | `https://www.biorxiv.org/content/{DOI}.full.pdf` |
| Cell Press | Open article page, user clicks PDF button |
| Genome Biology | `https://genomebiology.biomedcentral.com/counter/pdf/{DOI}` |
| Oxford Academic | Try `https://academic.oup.com/{journal}/article-pdf/{doi-suffix}.pdf` |

---

## Phase 2: Rename & Package

### Find new downloads

```bash
ls -lt ~/Downloads/*.pdf | head -10
```

### Rename

Format: `YYYY-Journal-Title.pdf` (max 120 chars, strip illegal chars `/\:*?"<>|`)

```bash
mkdir -p /tmp/papers_final && rm -f /tmp/papers_final/*.pdf
cp "original.pdf" "/tmp/papers_final/2026-Nature-Paper Title.pdf"
```

### Package to Desktop

```bash
today=$(date +%Y%m%d)
cd /tmp/papers_final
rm -f *.zip
zip -j "SMOOTH_文章汇总_${today}.zip" *.pdf
cp "SMOOTH_文章汇总_${today}.zip" ~/Desktop/
open ~/Desktop/
```

### Summary

```
✅ N papers → 📦 SMOOTH_文章汇总_YYYYMMDD.zip on Desktop

2026-Nature-Title one.pdf   (X.X MB)
2026-Cell-Title two.pdf     (X.X MB)
```

---

## Quick Reference

### curl download (OA articles)
```bash
curl -sL -o output.pdf \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  -H "Accept: application/pdf" \
  -H "Referer: <article-page-url>" \
  "<pdf-url>"
```

### scrapling commands
```bash
# WeChat article (dynamic browser required)
scrapling extract fetch "<url>" output.md --timeout 60000 --wait 5000

# Nature search results
scrapling extract get "<search-url>" output.html --css-selector article --impersonate chrome

# Stealth fetch (works for Nature, NOT Cell)
scrapling extract stealthy-fetch "<url>" output.md --solve-cloudflare --real-chrome --timeout 90000

# ⚠️ --ai-targeted can strip article content — avoid for search pages
# ⚠️ CLI only supports .html/.md/.txt — CANNOT save .pdf binaries
```

### OCR journal screenshot (macOS)
```bash
swift /Users/hmjsmac/.claude/skills/cns-paper-collector/ocr_image.swift <image_path>
```

### Chrome new window
```bash
open -a "Google Chrome" -n --args --new-window <url1> <url2> ...
```

### Environment
- scrapling uses Homebrew Python 3.12: `/opt/homebrew/opt/python@3.12/bin/python3.12`
- Install packages: append `--break-system-packages` to pip

### Journal name mapping

| Category | Names |
|----------|-------|
| **CNS core** | Cell, Nature, Science |
| **Nature family** | Nat Med, Nat Biotechnol, Nat Methods, Nat Genet, Nat Cell Biol, Nat Chem Biol, Nat Commun, Nat Neurosci, Nat Immunol, Nat Metab, Nat Aging, Nat Cancer, Nat Struct Mol Biol, Nat Plants, Nat Clim Change, Nat Microbiol |
| **Cell family** | Cell Res, Cell Rep, Cell Metab, Cell Host Microbe, Cell Stem Cell, Cancer Cell, Immunity, Neuron, Mol Cell, Dev Cell, Curr Biol, iScience |
| **Science family** | Sci Adv, Sci Transl Med, Sci Immunol, Sci Robot |
| **Other** | bioRxiv, Genome Biology, Nucleic Acids Res, PNAS, eLife, PLoS Biol, PLoS Genet, EMBO J, etc. |

### Publisher anti-bot reference

| Publisher | Level | Programmatic? | Behavior |
|-----------|-------|---------------|----------|
| Nature OA | Light | curl works | `Accept: application/pdf` + `Referer` required |
| Nature paywalled | Medium | Returns 406 or HTML redirect | Open in Chrome for institutional access |
| Science | Medium | Browser required | PDF URL works after Cloudflare pass |
| Cell Press | **Maximum** | **Impossible** | Cloudflare "请稍候…" even with real Chrome |
| bioRxiv | None | curl works | No protection |
| Genome Biology | None | curl works | BMC OA journal |

### Error handling

| Situation | Action |
|-----------|--------|
| Nature .pdf → 406 | Paywalled, open in Chrome |
| Nature .pdf → redirects to HTML | User clicks "Download PDF" on article page |
| Cell article | Open article page in Chrome immediately |
| curl PDF is actually HTML | Check `head -c 5` — if not `%PDF-`, fall back to Chrome |
| WeChat captcha | Re-fetch with longer stagger |
| WeChat markdown is JS skeleton | Use `extract fetch` (dynamic), not `extract get` |
| Multiple papers in one article | Collect all, confirm with user |
| Downloaded file has ` (1)` suffix | User re-downloaded, take the newest timestamp |
| Filename collision | Append ` (2)` before `.pdf` |
