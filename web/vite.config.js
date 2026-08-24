import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// The React app calls the standalone backend proxy (proxy.mjs) on :8787, which holds the
// Agent API token server-side and forwards to api.salesforce.com. No Vite proxy needed —
// proxy.mjs handles CORS + token injection (the real partner pattern). Run both:
//   node proxy.mjs   (terminal 1)
//   npm run dev      (terminal 2)
export default defineConfig({
  plugins: [react()],
});
