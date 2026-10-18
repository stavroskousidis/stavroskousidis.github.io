# stavroskousidis.github.io

Source code for [stavroskousidis.github.io](https://stavroskousidis.github.io/), the personal academic website of Stavros Kousidis, Professor of Cyber Security Engineering at TH Köln.

The site is built with [Astro](https://astro.build/) and published through GitHub Pages.

## Local development

```bash
npm install
npm run dev
```

Create a production build with:

```bash
npm run build
```

## Featured thesis opportunities

The landing page shows one open Bachelor's thesis and one open Master's thesis.
Within each level, a topic with `featured: true` in its
`src/content/theses/*.md` frontmatter takes precedence. If no open topic of
that level is featured, the newest `published` date wins. Ties are resolved by
title and then by ID. Assigned and under-discussion topics are not featured.

For example:

```yaml
level: "Master"
status: "Open"
published: "2026-10-18"
featured: true
```

If multiple open theses at the same level are marked `featured: true`,
the newest among them is shown. The complete theses page continues to display
open and under-discussion topics, grouped by level and sorted newest first.

## Deployment

The GitHub Actions workflow in `.github/workflows/deploy.yml` builds and deploys every push to `main`.

## License

Copyright © 2026 Stavros Kousidis. No reuse license is granted unless a `LICENSE` file is added.
