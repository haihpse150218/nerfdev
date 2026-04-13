import rss from "@astrojs/rss";
import { getCollection } from "astro:content";
import type { APIContext } from "astro";

export const prerender = true;

export async function GET(context: APIContext) {
  const posts = await getCollection("blog", ({ data }) => !data.draft);

  const sorted = posts.sort(
    (a, b) =>
      b.data.publishedDate.valueOf() - a.data.publishedDate.valueOf()
  );

  return rss({
    title: "Nerf Dev",
    description: "Tech blog by Nerf Dev",
    site: context.site!,
    items: sorted.map((post) => ({
      title: post.data.title,
      pubDate: post.data.publishedDate,
      description: post.data.description,
      link: `/blog/${post.slug}/`,
      categories: post.data.tags,
    })),
    customData: `<language>en</language>`,
  });
}
