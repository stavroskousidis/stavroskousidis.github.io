#!/usr/bin/env bash
set -euo pipefail

output_dir="public/pdfs"
mkdir -p "$output_dir/notes" "$output_dir/theses"

# The public PDF URL and downloaded filename both use:
# YYYY-MM-DD_note_<slug>.pdf or YYYY-MM-DD_thesis-<level>_<slug>.pdf
# Keep the original slug-only URLs as compatibility aliases.
for source in src/content/notes/*.md; do
  slug="$(basename "$source" .md)"
  name="$(node scripts/pdf-name.mjs note "$source")"
  pdf="$output_dir/notes/$name"
  pandoc "$source" \
    --from=gfm+yaml_metadata_block \
    --pdf-engine=typst \
    --standalone \
    --lua-filter=config/pdf-metadata.lua \
    --metadata-file=config/pdf.yaml \
    --metadata=author:"Stavros Kousidis" \
    --metadata=lang:en \
    --output="$pdf"
  cp "$pdf" "$output_dir/$slug.pdf"
done

# Thesis descriptions: one-page A4 announcements with publication metadata.
for source in src/content/theses/*.md; do
  slug="$(basename "$source" .md)"
  name="$(node scripts/pdf-name.mjs thesis "$source")"
  pdf="$output_dir/theses/$name"
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
  cp "$pdf" "$output_dir/theses/$slug.pdf"
done
