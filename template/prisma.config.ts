import "dotenv/config";
import { defineConfig, env } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  // En Prisma 7 la URL de conexión para Migrate vive aquí, no en el schema.
  // El runtime se conecta vía adapter (ver src/lib/prisma.ts).
  datasource: {
    url: env("DATABASE_URL"),
  },
});
