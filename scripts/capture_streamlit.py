"""Capture screenshots of HarnessEval Streamlit dashboard tabs."""
import asyncio
from pathlib import Path
from playwright.async_api import async_playwright

OUTPUT_DIR = Path(r"D:\NerfDev\public\assets\blog\harness-eval")
URL = "http://localhost:8501"

TABS = [
    ("Config Builder", 0),
    ("Run Monitor", 1),
    ("Log Viewer", 2),
    ("Compare", 3),
    ("ANOVA", 4),
]


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport={"width": 1400, "height": 900})

        # Wait for app to load
        await page.goto(URL, wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(3000)

        # Screenshot the main page (Config Builder is default)
        await page.screenshot(path=str(OUTPUT_DIR / "tab-config-builder.png"), full_page=False)
        print("Captured: Config Builder")

        # Click each remaining tab
        for tab_name, idx in TABS[1:]:
            try:
                # Streamlit tabs are buttons with role="tab"
                tabs = page.locator('button[role="tab"]')
                count = await tabs.count()
                if idx < count:
                    await tabs.nth(idx).click()
                    await page.wait_for_timeout(2000)
                    await page.screenshot(
                        path=str(OUTPUT_DIR / f"tab-{tab_name.lower().replace(' ', '-')}.png"),
                        full_page=False,
                    )
                    print(f"Captured: {tab_name}")
                else:
                    print(f"Tab {idx} not found (only {count} tabs)")
            except Exception as e:
                print(f"Failed to capture {tab_name}: {e}")

        # Go back to Config Builder and take a full-page screenshot
        tabs = page.locator('button[role="tab"]')
        await tabs.nth(0).click()
        await page.wait_for_timeout(2000)
        await page.screenshot(
            path=str(OUTPUT_DIR / "dashboard-full.png"),
            full_page=True,
        )
        print("Captured: Full dashboard")

        # Also try to click "Run ANOVA" with sample data for a richer screenshot
        await tabs.nth(4).click()
        await page.wait_for_timeout(1500)
        # Select "Sample Data"
        try:
            sample_radio = page.get_by_text("Sample Data")
            await sample_radio.click()
            await page.wait_for_timeout(1000)
            # Click Run ANOVA button
            run_btn = page.get_by_role("button", name="Run ANOVA")
            await run_btn.click()
            await page.wait_for_timeout(3000)
            await page.screenshot(
                path=str(OUTPUT_DIR / "tab-anova-results.png"),
                full_page=True,
            )
            print("Captured: ANOVA with results")
        except Exception as e:
            print(f"ANOVA results capture failed: {e}")

        await browser.close()


asyncio.run(main())
