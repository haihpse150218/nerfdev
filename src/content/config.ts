import { defineCollection, z } from "astro:content";

const blog = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string().max(70),
    description: z.string().max(160),
    publishedDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    author: z.string().default("nerf-dev"),
    tags: z.array(z.string()).min(1).max(5),
    series: z
      .object({
        name: z.string(),
        part: z.number(),
      })
      .optional(),
    draft: z.boolean().default(false),
    featured: z.boolean().default(false),
    cover: z
      .object({
        src: z.string(),
        alt: z.string(),
      })
      .optional(),
    newsletter: z
      .object({
        sent: z.boolean(),
        sentDate: z.coerce.date().optional(),
      })
      .optional(),
    minutesRead: z.number().optional(),
  }),
});

export const collections = { blog };
