#!/usr/bin/env node
// Produce exactly the same downloadable filename as the Astro detail pages.
import { readFileSync } from 'node:fs';
import { basename } from 'node:path';
import { notePdfName, thesisPdfName } from '../src/lib/pdf-names.mjs';

const [kind, filePath] = process.argv.slice(2);
if (!['note', 'thesis'].includes(kind) || !filePath) {
  throw new Error('Usage: node scripts/pdf-name.mjs <note|thesis> <source.md>');
}

const text = readFileSync(filePath, 'utf8');
const frontmatter = text.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)?.[1];
if (!frontmatter) throw new Error(`Missing YAML frontmatter in ${filePath}`);

function field(name) {
  const pattern = new RegExp(`^${name}:\\s*["']?([^"\\r\\n']+)["']?\\s*$`, 'm');
  const value = frontmatter.match(pattern)?.[1];
  if (!value) throw new Error(`Missing ${name} in ${filePath}`);
  return value;
}
const slug = basename(filePath, '.md');
const date = field('published');

console.log(kind === 'note'
  ? notePdfName(slug, date)
  : thesisPdfName(slug, date, field('level')));
