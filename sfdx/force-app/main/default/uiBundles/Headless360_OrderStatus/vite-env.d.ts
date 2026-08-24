/// <reference types="vite/client" />

/** Salesforce API version injected at build time by the Vite define plugin. */
declare const __SF_API_VERSION__: string;

interface ImportMetaEnv {
  /** Dev-only: frontdoor URL for ACC on localhost (bypasses in-org session requirement). */
  readonly VITE_SF_FRONTDOOR_URL?: string;
  /** The org's Agentforce agent (Headless360_Order_Assistant) BotDefinition Id. */
  readonly VITE_AGENT_ID?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
