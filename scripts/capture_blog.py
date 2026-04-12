"""Capture screenshot of the HarnessEval blog post on Astro dev server."""
import asyncio
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport={"width": 1200, "height": 800})

        # Blog post page
        await page.goto(
            "http://localhost:4321/blog/2026-04-12-harness-eval-de-cuong-nghien-cuu/",
            wait_until="networkidle",
            timeout=15000,
        )
        await page.wait_for_timeout(2000)

        # Viewport screenshot
        await page.screenshot(
            path=r"D:\NerfDev\public\assets\blog\harness-eval\blog-preview.png",
            full_page=False,
        )
        print("Captured: blog post preview")

        # Full page
        await page.screenshot(
            path=r"D:\NerfDev\public\assets\blog\harness-eval\blog-full.png",
            full_page=True,
        )
        print("Captured: blog post full page")

        # Home page with the new post
        await page.goto("http://localhost:4321/", wait_until="networkidle", timeout=15000)
        await page.wait_for_timeout(1500)
        await page.screenshot(
            path=r"D:\NerfDev\public\assets\blog\harness-eval\homepage.png",
            full_page=False,
        )
        print("Captured: homepage")

        await browser.close()

asyncio.run(main())
