// tests/e2e/game.spec.ts
import { test, expect } from '@playwright/test';
import process from 'process';

// Get server URL from environment or default to localhost
const SERVER_URL = process.env.GAME_SERVER_URL || 'http://localhost:5001';

// Verify required environment variables
test.beforeAll(async () => {
    if (!process.env.GAME_PASSWORD) {
        throw new Error('GAME_PASSWORD environment variable must be set');
    }
    console.log(`Testing against server: ${SERVER_URL}`);
});

test('should require login to access the game list', async ({ page }) => {
    await page.goto(SERVER_URL);
    await expect(page).toHaveURL(/.*login/);
});

test('should login and create shape in new game', async ({ page }) => {
    const password = process.env.GAME_PASSWORD!;

    // Login
    console.log('Starting login process...');
    await page.goto(`${SERVER_URL}/login`);
    await page.fill('input[type="password"]', password);
    await page.click('button[type="submit"]');

    // Create game
    const gameName = `test-${Date.now()}`;
    console.log(`Creating game: ${gameName}`);
    await page.fill('input[name="name"]', gameName);
    await page.click('button[type="submit"]');

    // Verify we're in the game
    await expect(page).toHaveTitle(new RegExp(gameName));

    // Create shape
    console.log('Creating shape...');
    await page.selectOption('#shapeType', 'circle');
    const canvas = page.locator('canvas');
    await canvas.click({ position: { x: 200, y: 200 } });

    await page.screenshot({ path: `test-results/${gameName}.png` });
});
// Test game name uniqueness
test('should prevent duplicate game names', async ({ page }) => {
    const password = process.env.GAME_PASSWORD!;
    const gameName = `duplicate-test-${Date.now()}`;

    // Login
    await page.goto('http://localhost:5001/login');
    await page.fill('input[type="password"]', password);
    await page.click('button[type="submit"]');

    // Create first game
    await page.fill('input[name="name"]', gameName);
    await page.click('button[type="submit"]');

    // Go back to game list
    await page.click('text=Back to Games');

    // Try to create game with same name
    await page.fill('input[name="name"]', gameName);
    await page.click('button[type="submit"]');

    // Should see error message
    await expect(page.locator('.error')).toContainText('exists');
});

// Test game persistence
// Updated persistence test
test('should show existing games after new login', async ({ browser }) => {
    const password = process.env.GAME_PASSWORD!;
    const gameName = `persist-test-${Date.now()}`;

    // Create first context and page
    const context1 = await browser.newContext();
    const page1 = await context1.newPage();

    // First login and create game
    await page1.goto('http://localhost:5001/login');
    await page1.fill('input[type="password"]', password);
    await page1.click('button[type="submit"]');

    await page1.fill('input[name="name"]', gameName);
    await page1.click('button[type="submit"]');
    await page1.click('text=Back to Games');

    // Close first context to ensure clean session
    await context1.close();

    // Create new context and page (fresh session)
    const context2 = await browser.newContext();
    const page2 = await context2.newPage();

    // Go to home page (should redirect to login)
    await page2.goto('http://localhost:5001');
    await expect(page2).toHaveURL(/.*login/);

    // Login again
    await page2.fill('input[type="password"]', password);
    await page2.click('button[type="submit"]');

    // Should see the game in the list
    await expect(page2.locator(`text=${gameName}`)).toBeVisible();

    // Cleanup
    await context2.close();
});
