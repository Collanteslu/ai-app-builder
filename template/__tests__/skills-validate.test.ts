import { describe, it, expect } from "vitest";
import { readFileSync, readdirSync, existsSync } from "fs";
import { join, resolve } from "path";

const SKILLS_DIR = resolve(__dirname, "../../skills");

function getSkillDirs(): string[] {
  return readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name);
}

describe("skills - validación de SKILL.md", () => {
  const skillDirs = getSkillDirs();

  it("tiene al menos una skill", () => {
    expect(skillDirs.length).toBeGreaterThan(0);
  });

  it.each(skillDirs)("%s — SKILL.md existe y tiene frontmatter válido", (dir) => {
    const skillPath = join(SKILLS_DIR, dir, "SKILL.md");
    expect(existsSync(skillPath)).toBe(true);

    const content = readFileSync(skillPath, "utf-8");
    expect(content.startsWith("---")).toBe(true);

    const endFrontmatter = content.indexOf("---", 3);
    expect(endFrontmatter).toBeGreaterThan(3);

    const frontmatter = content.slice(3, endFrontmatter).trim();
    expect(frontmatter).toContain("name:");
    expect(frontmatter).toContain("description:");
  });

  it.each(skillDirs)("%s — nombre coincide con el directorio", (dir) => {
    const skillPath = join(SKILLS_DIR, dir, "SKILL.md");
    const content = readFileSync(skillPath, "utf-8");
    const match = content.match(/^name:\s*(\S+)/m);
    expect(match).not.toBeNull();
    expect(match![1]).toBe(dir);
  });

  it.each(skillDirs)("%s — descripción no vacía y ≤ 1024 chars", (dir) => {
    const skillPath = join(SKILLS_DIR, dir, "SKILL.md");
    const content = readFileSync(skillPath, "utf-8");
    const match = content.match(/^description:\s*(.+)/m);
    expect(match).not.toBeNull();
    const desc = (match?.[1] ?? "").trim();
    expect(desc.length).toBeGreaterThan(0);
    expect(desc.length).toBeLessThanOrEqual(1024);
  });

  it.each(skillDirs)("%s — tiene sección de contenido tras el frontmatter", (dir) => {
    const skillPath = join(SKILLS_DIR, dir, "SKILL.md");
    const content = readFileSync(skillPath, "utf-8");
    const endFrontmatter = content.indexOf("---", 3);
    const body = content.slice(endFrontmatter + 3).trim();
    expect(body.length).toBeGreaterThan(50);
  });
});
