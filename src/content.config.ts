import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const notes = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/notes' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    type: z.enum(['Guide', 'Lab note', 'Background']),
    status: z.enum(['Stable', 'Experimental', 'Draft']),
    published: z.string(),
    updated: z.string(),
    testedOn: z.array(z.string()).default([]),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false)
  })
});

export const collections = { notes };
