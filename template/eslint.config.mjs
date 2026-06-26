import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";

const eslintConfig = [
  ...nextCoreWebVitals,
  ...nextTypescript,
  {
    rules: {
      "@typescript-eslint/no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
      // Estrictez de Next 16 que conviene ver como DEUDA, no como bloqueo:
      // - no-explicit-any: tipar es ideal, pero un `any` puntual no debe romper el build.
      // - set-state-in-effect (React Compiler): sugerencia de rendimiento, no un bug.
      // Quedan como AVISO (visibles), no como error. El gate real es `pnpm audit:builder`.
      "@typescript-eslint/no-explicit-any": "warn",
      "react-hooks/set-state-in-effect": "warn",
    },
  },
];

export default eslintConfig;
