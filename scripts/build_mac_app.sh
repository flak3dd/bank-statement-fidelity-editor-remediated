#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="1.1.1"
TARGET="aarch64-apple-darwin"
REVISION="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || printf unknown)}"
OUTPUT="${1:-target/release/portable/macos-aarch64}"

rustup target add "$TARGET"
cargo build --locked --release --target "$TARGET" --bin dual-core-pdf-pipeline
python3 scripts/build_portable_bundle.py \
  --platform macos-aarch64 \
  --binary "target/$TARGET/release/dual-core-pdf-pipeline" \
  --output "$OUTPUT" \
  --revision "$REVISION"

mkdir -p target/release/artifacts
tar -C "$OUTPUT" -czf "target/release/artifacts/BankStatementFidelityEditor-${VERSION}-macos-aarch64.tar.gz" BankStatementFidelityEditor.app
sha256sum "target/release/artifacts/BankStatementFidelityEditor-${VERSION}-macos-aarch64.tar.gz" > "target/release/artifacts/BankStatementFidelityEditor-${VERSION}-macos-aarch64.tar.gz.sha256"
printf 'Created unsigned portable bundle: %s\n' "target/release/artifacts/BankStatementFidelityEditor-${VERSION}-macos-aarch64.tar.gz"
