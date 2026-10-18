import type { CollectionEntry } from 'astro:content';

type Thesis = CollectionEntry<'theses'>;

export function compareThesesByPublication(a: Thesis, b: Thesis): number {
  return b.data.published.localeCompare(a.data.published)
    || a.data.title.localeCompare(b.data.title)
    || a.id.localeCompare(b.id);
}

export function compareThesesByLevelAndPublication(a: Thesis, b: Thesis): number {
  return a.data.level.localeCompare(b.data.level)
    || compareThesesByPublication(a, b);
}

// Always show at most one open topic per level. A featured topic wins;
// otherwise the newest publication wins, with deterministic title/ID ties.
export function selectHomepageTheses(theses: Thesis[]): Thesis[] {
  const open = theses.filter((thesis) => thesis.data.status === 'Open');

  return (['Bachelor', 'Master'] as const)
    .map((level) => open
      .filter((thesis) => thesis.data.level === level)
      .sort((a, b) => Number(b.data.featured) - Number(a.data.featured)
        || compareThesesByPublication(a, b))[0])
    .filter((thesis): thesis is Thesis => thesis !== undefined);
}
