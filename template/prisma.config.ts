import "dotenv/config";
import { defineConfig, env } from "prisma/config";

// En Prisma 7 la URL de conexión para Migrate vive aquí, no en el schema; el
// runtime se conecta vía adapter (ver src/lib/prisma.ts). `prisma generate` NO
// necesita la URL, así que solo declaramos el datasource cuando DATABASE_URL
// está presente. Así el postinstall (generate) funciona sin .env (CI, primer
// install) y Migrate sigue teniendo la URL cuando el usuario la define.
export default defineConfig({
  schema: "prisma/schema.prisma",
  ...(process.env.DATABASE_URL ? { datasource: { url: env("DATABASE_URL") } } : {}),
});
