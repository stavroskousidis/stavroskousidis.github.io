# PDF naming convention

Every PDF linked from the academic website uses its publication date, document type, and stable page slug.

- Notes: `YYYY-MM-DD_note_<slug>.pdf`
- Bachelor's thesis announcements: `YYYY-MM-DD_thesis-bachelor_<slug>.pdf`
- Master's thesis announcements: `YYYY-MM-DD_thesis-master_<slug>.pdf`

Examples:

- `2026-09-26_note_pq-openpgp-fedora-45-base.pdf`
- `2026-10-15_thesis-bachelor_least-privilege-linux-monitoring.pdf`
- `2026-10-15_thesis-master_secure-autonomous-attack-validation.pdf`

The date is taken from the existing `published` front matter, *not* the time the site was rebuilt. Updated material retains the same URL and downloadable filename; the separate `updated` metadata (when present) documents revisions without breaking links. The slug is the Markdown file's basename and should remain stable.

The Notes PDF link points to `/pdfs/notes/<filename>` and thesis links to `/pdfs/theses/<filename>`. Both use the HTML `download` attribute to suggest that exact filename to the browser.

Legacy undated URLs (`/pdfs/<note-slug>.pdf` and `/pdfs/theses/<thesis-slug>.pdf`) remain as compatibility copies. The pull-request `thesis-pdfs` artifact contains only the dated PDFs, not the legacy aliases.

The filename rules are shared between Astro and the build script via `src/lib/pdf-names.mjs`. The command-line adapter is `scripts/pdf-name.mjs`. Update these together if the naming convention ever changes.
