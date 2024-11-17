// playwright.config.ts
import { PlaywrightTestConfig } from '@playwright/test';

const config: PlaywrightTestConfig = {
  testDir: './tests/e2e',
  timeout: 60000,  // Increased timeout for public network
  workers: 1,
  use: {
    baseURL: process.env.GAME_SERVER_URL || 'http://localhost:5001',
    trace: 'retain-on-failure',
    screenshot: 'on',
    video: 'on-first-retry',
  },
  reporter: [
    ['list'],
    ['html', { open: 'never' }],
    ['junit', { outputFile: 'test-results/junit.xml' }]  // Added JUnit reporter for Jenkins
  ],
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    }
  ],
  retries: process.env.GAME_SERVER_URL?.includes('24.29.85.43') ? 2 : 0,  // Add retries for public network
};

export default config;