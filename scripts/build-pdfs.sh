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
    --metadata-file=config/pdf.yaml \
    --metadata=author:"Stavros Kousidis" \
    --metadata=lang:en \
    --output="$output_dir/$slug.pdf"
done
