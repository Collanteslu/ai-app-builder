import { describe, it, expect } from "vitest";
import { readFileSync, existsSync } from "fs";
import { resolve } from "path";

const TEMPLATE_DIR = resolve(__dirname, "..");

describe("template - archivos esenciales existen", () => {
  const requiredFiles = [
    "package.json",
    "tsconfig.json",
    "next.config.ts",
    "vitest.config.ts",
    "eslint.config.mjs",
    "postcss.config.mjs",
    "playwright.config.ts",
    ".env.example",
    ".gitignore",
    ".npmrc",
    ".nvmrc",
    ".prettierrc",
    "docker-compose.yml",
    "prisma/schema.prisma",
    "prisma.config.ts",
    "src/lib/utils.ts",
    "src/lib/env.ts",
    "src/lib/prisma.ts",
    "src/app/layout.tsx",
    "src/app/page.tsx",
    "src/app/error.tsx",
    "src/app/loading.tsx",
    "src/app/not-found.tsx",
    "src/app/globals.css",
    ".github/workflows/ci.yml",
    "e2e/example.spec.ts",
  ];

  it.each(requiredFiles)("%s existe", (file) => {
    expect(existsSync(resolve(TEMPLATE_DIR, file))).toBe(true);
  });
});

describe("template - package.json versionado pinned (sin ^)", () => {
  const pkg = JSON.parse(readFileSync(resolve(TEMPLATE_DIR, "package.json"), "utf-8"));

  const allDeps = { ...pkg.dependencies, ...pkg.devDependencies };

  const pinned = Object.entries(allDeps).filter(([_, v]) => typeof v === "string" && !v.startsWith("workspace:"));
  it.each(pinned)("%s tiene versión exacta (sin ^)", (name, version) => {
    expect(version).not.toMatch(/^\^/);
    expect(version).not.toMatch(/^~/);
    expect(version).toMatch(/^\d+\.\d+\.\d+/);
  });

  it("tiene packageManager definido como pnpm", () => {
    expect(pkg.packageManager).toMatch(/^pnpm@/);
  });

  it("tiene engine node >=22", () => {
    expect(pkg.engines?.node).toMatch(/>=22/);
  });
});

describe("template - configs básicas", () => {
  it("tsconfig.json es válido", () => {
    const tsconfig = JSON.parse(readFileSync(resolve(TEMPLATE_DIR, "tsconfig.json"), "utf-8"));
    expect(tsconfig.compilerOptions).toBeDefined();
    expect(tsconfig.compilerOptions.paths?.["@/*"]).toBeDefined();
  });

  it("next.config.ts existe y exporta configuración", () => {
    const content = readFileSync(resolve(TEMPLATE_DIR, "next.config.ts"), "utf-8");
    expect(content).toContain("export");
  });

  it(".nvmrc contiene versión 22", () => {
    const nvmrc = readFileSync(resolve(TEMPLATE_DIR, ".nvmrc"), "utf-8").trim();
    expect(nvmrc).toMatch(/^22/);
  });

  it("docker-compose.yml tiene PostgreSQL 17", () => {
    const dc = readFileSync(resolve(TEMPLATE_DIR, "docker-compose.yml"), "utf-8");
    expect(dc).toContain("postgres:17");
  });

  it("vitest.config.ts usa react plugin", () => {
    const config = readFileSync(resolve(TEMPLATE_DIR, "vitest.config.ts"), "utf-8");
    expect(config).toContain("@vitejs/plugin-react");
    expect(config).toContain("jsdom");
  });
});
