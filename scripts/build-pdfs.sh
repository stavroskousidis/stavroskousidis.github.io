#!/usr/bin/env bash
set -euo pipefail

output_dir="public/pdfs"
mkdir -p "$output_dir"

for source in src/content/notes/*.md; do
  slug="$(basename "$source" .md)"
  pandoc "$source" \
    --from=gfm+yaml_metadata_block \
    --pdf-engine=typst \
    --standalone \
    --lua-filter=config/pdf-metadata.lua \
    --metadata-file=config/pdf.yaml \
    --metadata=author:"Stavros Kousidis" \
    --metadata=lang:en \
    --output="$output_dir/$slug.pdf"
done

# Thesis descriptions: one-page A4 announcements with publication metadata.
mkdir -p "$output_dir/theses"
for source in src/content/theses/*.md; do
  slug="$(basename "$source" .md)"
  pdf="$output_dir/theses/$slug.pdf"
  pandoc "$source" \
    --from=gfm+yaml_metadata_block \
    --pdf-engine=typst \
    --standalone \
    --lua-filter=config/thesis-pdf.lua \
    --metadata-file=config/thesis-pdf.yaml \
    --metadata=author:"Stavros Kousidis" \
    --metadata=lang:en \
    --output="$pdf"

  if ! command -v pdfinfo >/dev/null 2>&1; then
    echo "pdfinfo (poppler-utils) is required to verify that thesis PDFs fit on one page." >&2
    exit 1
  fi
  pages="$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')"
  if [[ "$pages" != "1" ]]; then
    echo "Thesis PDF must be one page: $pdf is $pages pages." >&2
    exit 1
  fi
done
