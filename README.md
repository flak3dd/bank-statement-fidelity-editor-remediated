# Bank Statement Fidelity Editor v1.0.0

A high-fidelity PDF text editor focused on bank statements: replace text and numbers in-place with the original kerning, font, size, color, and position preserved, then keep all transactions and running balances mathematically consistent.

## What it does

- **Targeted edits.** Click any text on a rendered page to select the exact bounding box; type a new value; the engine performs a redaction-based replacement that re-uses the original glyph metrics.
- **Multi-stage workflow.** Parse → Edit → Balance Preview → Confirm & Render → Visual Validate → Final Math Check, with autosaved drafts so you can pause and resume mid-edit. See [Workflow](#workflow) below.
- **Explicit backend routing.** Extraction uses only the selected cloud parser and then the qualified offline parser; unrelated cloud services are never attempted implicitly. Optional verification providers are reported separately and cannot override mandatory local gates. See [Backend Preferences](#backend-preferences).
- **Capability detection.** The app reports configured and unavailable backends in Backend Preferences without making unrelated startup network calls. Explicit credential checks remain available on demand.
- **Batch Processing Dashboard.** Drag and drop a folder of PDFs to queue up asynchronous extraction or smart auto-balancing across dozens of statements at once.
- **Progressive Disclosure.** Complex verification settings and forensic modes are tucked behind an "Advanced Mode" toggle, keeping the default UI clean and focused.
- **Smart Balance Engine.** Parses the full PDF, detects mathematical imbalance, and asks Gemini for the minimum cascading adjustment plan. Only the *last* running balance is auto-corrected by default; everything else stays untouched. Falls back to local deterministic balance analysis when AI is unavailable.
- **Qualified extraction.** The selected LlamaParse or Document AI provider may fall back only to the local geometry-aware parser. Local OCR remains a deferred, non-selectable v1 PDF backend.
- **Evidence-gated verification.** Verifies every page at 300 DPI with immutable calibrated thresholds, structural/page-box/font/metadata checks, exact old/new text membership, live-text editability, strict ledger equivalence, and hashed replay evidence. pdfRest and Vision AI are optional additive providers with explicit pass/fail/unavailable outcomes.
- **Audit log + change history.** Every edit lands in an append-only log file with a snapshot PDF, plus an in-memory undo/redo stack and an autosaved `audit/history.json` so you can resume after a crash. The final step automatically merges the Audit JSON Report as a new page onto the final output PDF.
- **CLI + GUI parity.** Both interfaces drive the same `Runtime` job loop, so anything you can do in the GUI you can script.

## What it does not do

- It cannot forge Adobe signatures, mimic a commercial MuPDF watermark, or defeat sophisticated forensic detection. Re-saved PDFs may still be flagged as "modified" by tools that read library fingerprints.
- Without any API keys at all, only manual edit / verify / render with local offline parsing works. The more keys you configure, the more pipeline stages light up.
- pdfRest and Vision AI are optional additive verification layers. Applitools is deferred because no production bridge existed; it is not configurable or advertised as supported.

## System dependencies

| OS | Required |
|---|---|
| **Windows** | Visual Studio 2019 Build Tools (v142). Python 3.10+. |
| **macOS** | `brew install mupdf tesseract leptonica`. Python 3.10+. |
| **Linux (Ubuntu)** | `apt-get install libmupdf-dev tesseract-ocr libleptonica-dev`. Python 3.10+. |

Python packages: `pip install pymupdf pymupdfpro fonttools pillow`.

## Build

```text
cargo build --release
```

The release binary is `target/release/dual-core-pdf-pipeline`.

## Configuration

All configuration is via environment variables (or a `.env` file). Copy `.env.example` to `.env` to get started.

### Required Keys

| Variable | Description |
|---|---|
| `DUAL_CORE_PASSPHRASE` | Software root-of-trust passphrase (≥16 chars). Alternatively, create a `.pipeline_key` file. |

### AI & Parsing Keys

| Variable | Used By | Fallback If Missing |
|---|---|---|
| `GEMINI_API_KEY` | Smart Balance, AI Completeness, Vision Validation | → Manual-only mode (local balance engine) |
| `GEMINI_AUTH_MODE` | Auth method: `api_key` (default) or `vertex` (enterprise SA/ADC) | Defaults to `api_key` |
| `MINDEE_API_KEY` | Mindee Financial Document API | → offline parser (PyMuPDF built-in) |
| `LLAMAPARSE_API_KEY` | **Default parser** — LlamaParse LLM-based parser | → offline parser |
| `DOCUMENT_AI_PROJECT_ID` | Google Document AI parser | → offline parser |
| `DOCUMENT_AI_LOCATION` | e.g. `us` | |
| `DOCUMENT_AI_PROCESSOR_ID` | Processor ID | |
| `DOCUMENT_AI_API_KEY` | Document AI v1beta3 API key (preferred auth) | → SA/ADC auth |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service-account JSON (legacy fallback) | → ADC auto-detection |

### PDF Engine & Verification Keys

| Variable | Used By | Fallback If Missing |
|---|---|---|
| `PYMUPDF_PRO_KEY` | PyMuPDF Pro (enhanced font handling) | → PyMuPDF free tier |
| `PDFREST_API_KEY` | Adobe-tier cloud rendering for verification | → local Pdfium |

### Optional / Telemetry

| Variable | Description |
|---|---|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP gRPC endpoint (default: `http://localhost:4317`) |
| `OTEL_SERVICE_NAME` | Defaults to `dual-core-pdf-pipeline` |
| `RUST_LOG` | e.g. `info`, `debug` |
| `LOG_DIR` | Defaults to `./logs` |
| `WEBHOOK_URL` | Used for submitting automated bug reports and logs during the Beta phase |

Run `dual-core-pdf-pipeline doctor` to print a one-shot health check (env vars set, directories writable, runtime worker reachable).

## Beta Testing

We are currently in a Beta Testing phase for `v1.0.0`. If you encounter a hard crash or a bug, the app features an integrated automated bug reporting tool and interactive repair loop. See the [Beta Testing Guide](docs/BETA_TESTING.md) for details on how telemetry and error submissions work.

## Backend Preferences

The **Backend Preferences** panel (Settings → Backend Preferences) lets you choose which backend to use for each pipeline stage. Options that require a missing API key are marked with ⛔ and show a hover tooltip explaining what's needed.

### PDF Engine
| Mode | Description | Requires |
|---|---|---|
| **Auto** (default) | PyMuPDF first, falls back to Pdfium | Python + pymupdf |
| Dual Concurrent | Both engines in parallel | Python + pymupdf |
| Force Native (Pdfium) | Pdfium only | Always available |
| Force PyMuPDF | PyMuPDF only | Python + pymupdf |
| Typst reconstruction | Legacy persisted value only; rejected in fidelity workflows | Not selectable |

### AI Provider
| Mode | Description | Requires |
|---|---|---|
| **Manual Only** (default) | No AI calls | Nothing |
| Gemini (API Key) | AI Studio key | `GEMINI_API_KEY` |
| Gemini (Vertex AI) | Enterprise SA/ADC | Service account + ADC |
| Groq (Llama 3) | Fast math reasoning | `GROQ_API_KEY` |
| OpenRouter (DeepSeek) | Double-check reasoning | `OPENROUTER_API_KEY` |

### Document Parser
| Mode | Description | Requires | Fallback |
|---|---|---|---|
| **LlamaParse** (default) | LLM-based parsing | `LLAMAPARSE_API_KEY` | → qualified offline parser |
| Offline Heuristic | Local geometry-aware extraction | Always available | — |
| Local OCR | Deferred for the v1 PDF workflow | Not selectable | — |
| Document AI | Google ML parsing | GCP credentials | → qualified offline parser |

### Verification Renderer
| Mode | Description | Requires | Fallback |
|---|---|---|---|
| **Local Pdfium** ✅ (default) | Local rendering | Always available | — |
| pdfRest (Cloud) | Adobe-tier rendering | `PDFREST_API_KEY` | → Local Pdfium |

### Calibrated Verification Policy

Mandatory verification uses the immutable policy recorded in `assets/verification-calibration-v2.json`. The current outside-region tile ceiling is `0.02`, the intended-region residual ceiling is `0.04`, the SSIM structural floor is `0.85`, every page is checked, and deterministic verification runs once without widening masks or retrying unchanged output under looser criteria.

## CLI

```text
dual-core-pdf-pipeline gui                                 # launch the GUI
dual-core-pdf-pipeline serve                               # run headless server (binds 0.0.0.0:$PORT)
dual-core-pdf-pipeline doctor                              # config health check
dual-core-pdf-pipeline verify-api-keys                     # verify all API keys
dual-core-pdf-pipeline text -i in.pdf -o out.pdf \
    --old "100.00" --new "150.00" --page 0 --bbox 50,40,90,52
dual-core-pdf-pipeline balance -i in.pdf -o out.pdf [--auto-approve]
dual-core-pdf-pipeline auto-balance -i in.pdf -o out.pdf   # Smart balance with auto-approve
dual-core-pdf-pipeline extract -i in.pdf -o data.json
dual-core-pdf-pipeline verify --original a.pdf --edited b.pdf --output-dir audit/verify [--use-pdfrest]
dual-core-pdf-pipeline render -i in.pdf -o pages -p 0 --dpi 300
dual-core-pdf-pipeline font-complete -i in.pdf --font Helvetica
dual-core-pdf-pipeline analyze-fonts -i in.pdf
dual-core-pdf-pipeline ai-fix-visual -i in.pdf -p 0
dual-core-pdf-pipeline docai-train                         # Train a new Document AI processor version
dual-core-pdf-pipeline fontcache-init                      # Bootstrap font cache
dual-core-pdf-pipeline transfer-transactions --source-pdf a.pdf --target-pdf b.pdf -o out.pdf
dual-core-pdf-pipeline adjust-dates -i in.pdf -o out.pdf --mode shift-forward-1-month
dual-core-pdf-pipeline run-transfer-tests --statements a.pdf,b.pdf
dual-core-pdf-pipeline export-history --from-log audit/2026.log -o history.json

### Stress Testing
cargo test --test au_transfer_stress -- --ignored --nocapture
```

## GUI shortcuts

- `Ctrl+O` open • `Ctrl+Z/Y` undo/redo • `Ctrl+S` export history
- `+` / `-` zoom • `0` reset zoom • `←/→` page nav
- Middle-drag (or Shift+drag) to pan; Ctrl+wheel to zoom

## Workflow

The application supports two primary flows: **Single Statement** and **Batch Processing**.

### Single Statement Flow
The right-hand "Workflow" panel walks the user through six stages. Each
stage is gated by an explicit button click — the app never silently
moves to the next step.

1. **① Parse + AI validate.** The selected document parser extracts every transaction; if an AI provider is configured, Gemini double-checks for missed rows. If the cloud parser fails, the pipeline auto-falls back to the offline parser. Result: a `ParseValidation` with a completeness score (0..1) and a list of any rows the deterministic geometry extractor saw but the parser missed.
2. **Edit.** The inline edit table (powered by `egui_extras::TableBuilder`) shows every parsed row with editable Date / Description / Debit / Credit / Balance columns. Numeric fields turn red when the typed text isn't parseable. Click "↶" on any row to revert every queued edit on that row at once.
3. **② Balance Out Preview.** Recomputes every running balance with the user's edits applied and shows the per-row diff plus the final imbalance. Translucent yellow boxes appear on the canvas over each `will_change` cell — hover for a `<old> → <new>` tooltip.
4. **③ Confirm and Render.** Applies edits through the selected exact in-place engine. Every target requires stable old-text identity, unique geometry membership, exact requested/matched/placed counts, and staged atomic publication. Lossy Typst reconstruction and automatic font substitution are disabled.
5. **Independent verification.** Re-parses the staged output locally, checks every page under immutable thresholds, verifies structural and live-text membership invariants, and persists hashed machine evidence. Optional pdfRest, Vision AI, and Document AI outcomes are additive and explicitly recorded as passed, failed, or unavailable.
6. **Finalization.** Publishes only an output whose locally reparsed row count, sequence, signs, values, running balances, closing balance, content membership, editability, geometry, and visual gates all pass.

### Batch Processing Flow
The **Batch Processing** tab allows for bulk operations across multiple PDFs:
1. **Load Folder:** Drag and drop a folder containing multiple bank statements.
2. **Bulk Extraction:** Click "Extract All to JSON" to concurrently extract transactional data from all files.
3. **Bulk Auto-Balance:** Click "Auto-Balance All" to invoke the Smart Balance Engine on all files.

### Drafts

The whole session (parse, queued edits, stage) autosaves to
`audit/workflow.json` every 1.5s as you edit. **File → Resume workflow
draft** restores it; **File → Discard workflow draft** clears it. The
draft is hashed against the source PDF so the GUI can warn you if you
re-open the draft against a modified file. On a successful workflow
completion the draft is automatically removed.

## Architecture

```text
app/          CLI, GUI, runtime, audit log, telemetry, config, API availability detection
engine/       Balance math, transaction model, verification (multi-layer), history, layout,
              typst reconstruction, font analysis/replication/shaping, offline parser
pdf/          Engine trait + selector (PyMuPDF primary, Pdfium fallback, OxidizePdf)
extractors/   Geometry providers (per-bank templates, PyMuPDF heuristic) + hybrid merger
ai/           Document AI, Gemini, LlamaParse, pdfRest, Vision AI,
              supervised Python bridge
security/     Software root-of-trust, ChaCha20-Poly1305 encryption
```

All long-running work goes through the `Runtime` job loop. The GUI never blocks. Python work is funnelled into a single dedicated actor thread to avoid PyO3 cross-thread issues. Panics inside the actor are caught and surfaced as structured errors instead of crashing the process.

### Fallback Hierarchy

Every pipeline stage is designed with explicit fallback chains:

```
PDF editing:   selected exact engine; unsupported or ambiguous targets fail before publication
Parsers:       selected LlamaParse/Document AI → qualified offline parser only
Balance:       deterministic exact-decimal engine; configured AI is advisory
Verification:  mandatory local full-document gates + optional pdfRest/Vision/Document AI evidence
Provider error: explicit unavailable/failed gate; never converted into a local pass
```

### Processing boundary

Version 1 processes documents through the local application runtime. It does not expose or claim a remote document-processing engine. The optional headless server currently provides operational health/readiness endpoints only; any future remote processing service requires a separately designed, authenticated, versioned API and threat model.

## Forensics & watermarking caveats

This tool is designed for evidence-verified in-place edits, but it does not claim universal visual or forensic identity with every commercial PDF producer. See [the original disclaimer](#what-it-does-not-do).
