# Copyright & Attribution

## scrapling

This skill depends on **scrapling**, an open-source web scraping library. If you use this skill for research purposes, please cite scrapling:

```bibtex
@misc{scrapling,
  author = {Karim Shoair},
  title = {Scrapling},
  year = {2024},
  url = {https://github.com/D4Vinci/Scrapling},
  note = {An adaptive Web Scraping framework for extracting structured data}
}
```

- **Project**: [scrapling](https://github.com/D4Vinci/Scrapling)
- **License**: BSD-3-Clause
- **Copyright**: Karim Shoair & scrapling contributors

scrapling is the core engine that enables WeChat article fetching. WeChat pages are entirely JavaScript-rendered — static HTTP clients (curl, requests) return empty HTML shells. scrapling's dynamic browser (built on Playwright) renders the full page, including article content, journal screenshots, and embedded DOIs.

Key scrapling features used by this skill:
- `scrapling extract fetch` — dynamic browser for JS-rendered WeChat pages
- `scrapling extract get` — static HTTP with anti-bot headers for Nature search
- `scrapling extract stealthy-fetch` — Cloudflare bypass for protected journal sites

scrapling itself relies on:
- **Playwright** (Apache 2.0) — browser automation engine
- **curl_cffi** (MIT) — TLS fingerprint impersonation
- **patchright** (MIT) — anti-detection browser patches

---

## Swift Vision OCR

The `ocr_image.swift` script uses Apple's **Vision** framework (macOS 13+).

- **Framework**: [Apple Vision](https://developer.apple.com/documentation/vision)
- **License**: Proprietary (part of macOS SDK)
- **Copyright**: Apple Inc.

Linux users should use **Tesseract OCR** as an alternative:
- **Project**: [Tesseract OCR](https://github.com/tesseract-ocr/tesseract)
- **License**: Apache 2.0

---

## Crossref API

Metadata lookups use the **Crossref REST API**.

- **Service**: [Crossref](https://www.crossref.org/)
- **API**: `https://api.crossref.org/works/{DOI}`
- **Terms**: [Crossref API Terms](https://www.crossref.org/documentation/retrieve-metadata/rest-api/)
- Usage is free and open. Polite use policy: no authentication required for basic queries.

---

## cns_collector

- **License**: MIT
- **Copyright**: [hmj238751-ui](https://github.com/hmj238751-ui)

This skill is a workflow orchestration layer built on top of the tools listed above. It does not bundle or redistribute any third-party code — users must install dependencies (scrapling, Chrome, etc.) separately.
