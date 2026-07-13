import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";
import { config } from "dotenv";

// Carga .env.test para tests (anula DATABASE_URL con DATABASE_URL_TEST)
config({ path: ".env.test" });

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: [],
    include: ["src/**/*.test.{ts,tsx}", "__tests__/**/*.test.ts"],
    coverage: {
      provider: "v8",
      include: ["src/**/*.{ts,tsx}"],
      exclude: ["src/**/*.test.*", "src/**/*.d.ts"],
    },
    env: {
      DATABASE_URL: process.env.DATABASE_URL_TEST || process.env.DATABASE_URL || "",
    },
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "src") },
  },
});
