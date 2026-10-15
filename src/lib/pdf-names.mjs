// Shared naming convention for downloadable site PDFs.
// Publication dates are stable: editing a document does not change its URL.
function validate(date, slug) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(Date.parse(date)) ||
      new Date(date).toISOString().slice(0, 10) !== date) {
    throw new Error(`Invalid publication date: ${date}`);
  }
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) {
    throw new Error(`Invalid PDF slug: ${slug}`);
  }
}

export function notePdfName(slug, published) {
  validate(published, slug);
  return `${published}_note_${slug}.pdf`;
}

export function thesisPdfName(slug, published, level) {
  validate(published, slug);
  if (level !== 'Bachelor' && level !== 'Master') {
    throw new Error(`Invalid thesis level: ${level}`);
  }
  return `${published}_thesis-${level.toLowerCase()}_${slug}.pdf`;
}
