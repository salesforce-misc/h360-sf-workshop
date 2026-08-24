import { useEffect, useRef, useState } from "react";
import { embedAgentforceClient } from "@salesforce/agentforce-conversation-client";

export function AgentforceChat() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    let cancelled = false;
    let loApp: HTMLElement | undefined;
    let chatClientComponent: any | undefined;

    // Read agentId from build-time env var (per-org value)
    const agentId = import.meta.env.VITE_AGENT_ID;
    if (!agentId) {
      const msg = "VITE_AGENT_ID not set — build with the org's agent id";
      setError(msg);
      console.error(`[AgentforceChat] ${msg}`);
      return;
    }

    // Check for dev-only frontdoorUrl (for localhost `sf ui-bundle dev`)
    const frontdoorUrl = import.meta.env.VITE_SF_FRONTDOOR_URL;

    if (import.meta.env.DEV && frontdoorUrl) {
      // Dev mode ONLY: frontdoorUrl embeds a live session token. `import.meta.env.DEV`
      // is false under `vite build`, so this branch is stripped from the deployed bundle
      // — a stray VITE_SF_FRONTDOOR_URL can never bake a live session URL into shipped JS.
      console.log("[AgentforceChat] Using frontdoorUrl (dev mode)");

      try {
        const result = embedAgentforceClient({
          container,
          frontdoorUrl,
          agentforceClientConfig: {
            agentId,
            agentLabel: "Order Assistant",
            renderingConfig: {
              mode: "floating",
              showHeaderIcon: true,
            },
          },
          onReady: (detail) => {
            console.log("[AgentforceChat] Lightning Out ready:", detail);
          },
          onError: (error) => {
            console.error(`[AgentforceChat] Lightning Out error [${error.type}]:`, error.detail);
          },
        });

        if (!cancelled) {
          loApp = result.loApp;
          chatClientComponent = result.chatClientComponent;
        }
      } catch (err) {
        setError(`Failed to embed Agentforce client: ${err}`);
        console.error("Agentforce embedding error:", err);
      }

      return () => {
        cancelled = true;
        container.replaceChildren();

        // Tear down Lightning Out app to unregister (StrictMode-safe)
        try {
          // loApp.destroy() triggers internal cleanup + unregister
          if (loApp && 'destroy' in loApp && typeof (loApp as any).destroy === 'function') {
            (loApp as any).destroy();
          }
          // Remove from DOM if still attached (triggers disconnectedCallback → unregister)
          if (loApp && loApp.parentNode) {
            loApp.remove();
          }
          // Remove chatClientComponent if present
          if (chatClientComponent && 'remove' in chatClientComponent && typeof chatClientComponent.remove === 'function') {
            chatClientComponent.remove();
          }
        } catch (teardownErr) {
          console.warn("[AgentforceChat] Teardown error:", teardownErr);
        }
      };
    }

    // In-org mode: derive salesforceOrigin from SFDC_ENV or window.location
    // Source from SFDC_ENV.orgUrl (e.g., "https://orgfarm-XXXXX.lightning.force.com")
    // and transform .lightning.force.com → .my.salesforce.com.

    const sfdcEnv = (globalThis as any).SFDC_ENV;
    if (import.meta.env.DEV) console.log("[AgentforceChat] SFDC_ENV:", JSON.stringify(sfdcEnv, null, 2));

    let salesforceOrigin: string | undefined;

    // Preferred: derive from SFDC_ENV.orgUrl
    if (sfdcEnv?.orgUrl) {
      const orgUrl = sfdcEnv.orgUrl as string;
      if (orgUrl.includes('.lightning.force.com')) {
        // Transform https://orgfarm-XXXXX.lightning.force.com → https://orgfarm-XXXXX.my.salesforce.com
        salesforceOrigin = orgUrl.replace('.lightning.force.com', '.my.salesforce.com');
      } else if (orgUrl.includes('.my.salesforce.com')) {
        // Already in the correct form
        salesforceOrigin = orgUrl;
      }
    }

    // Fallback: transform window.location.origin
    if (!salesforceOrigin) {
      const currentOrigin = window.location.origin;
      try {
        const url = new URL(currentOrigin);
        let host = url.hostname;

        // Strip namespace segment (e.g., orgfarm-55669dd59e--c → orgfarm-55669dd59e)
        host = host.replace(/--[^.]+\.my\.salesforce\.app$/, '.my.salesforce.app');

        // Transform .my.salesforce.app → .my.salesforce.com
        if (host.endsWith('.my.salesforce.app')) {
          host = host.replace('.my.salesforce.app', '.my.salesforce.com');
        }

        salesforceOrigin = `${url.protocol}//${host}`;
      } catch {
        // Fallback to raw origin if URL parsing fails
        salesforceOrigin = currentOrigin;
      }
    }

    if (import.meta.env.DEV) console.log("[AgentforceChat] Resolved salesforceOrigin:", salesforceOrigin);

    if (!salesforceOrigin) {
      setError("Unable to determine Salesforce org origin");
      return;
    }

    try {
      const result = embedAgentforceClient({
        container,
        salesforceOrigin,
        agentforceClientConfig: {
          agentId,
          agentLabel: "Order Assistant",
          renderingConfig: {
            mode: "floating",
            showHeaderIcon: true,
          },
        },
        onReady: (detail) => {
          if (import.meta.env.DEV) console.log("[AgentforceChat] Lightning Out ready:", detail);
        },
        onError: (error) => {
          console.error(`[AgentforceChat] Lightning Out error [${error.type}]:`, error.detail);
          // Surface the failure — the most common lab mistake (VITE_AGENT_ID built for
          // the wrong org) arrives here, and a console-only error leaves a silent blank chat.
          if (!cancelled) {
            setError(`Order Assistant failed to load [${error.type}]. Most likely VITE_AGENT_ID was built for a different org than this one.`);
          }
        },
      });

      if (!cancelled) {
        loApp = result.loApp;
        chatClientComponent = result.chatClientComponent;
      }
    } catch (err) {
      setError(`Failed to embed Agentforce client: ${err}`);
      console.error("Agentforce embedding error:", err);
    }

    return () => {
      cancelled = true;
      container.replaceChildren();

      // Tear down Lightning Out app to unregister (StrictMode-safe)
      try {
        // loApp.destroy() triggers internal cleanup + unregister
        if (loApp && 'destroy' in loApp && typeof (loApp as any).destroy === 'function') {
          (loApp as any).destroy();
        }
        // Remove from DOM if still attached (triggers disconnectedCallback → unregister)
        if (loApp && loApp.parentNode) {
          loApp.remove();
        }
        // Remove chatClientComponent if present
        if (chatClientComponent && 'remove' in chatClientComponent && typeof chatClientComponent.remove === 'function') {
          chatClientComponent.remove();
        }
      } catch (teardownErr) {
        console.warn("[AgentforceChat] Teardown error:", teardownErr);
      }
    };
  }, []);

  if (error) {
    // Surface visibly instead of returning null — a blank chat with only a console
    // error is how a wrong/missing VITE_AGENT_ID goes unnoticed during the lab.
    console.error("AgentforceChat error:", error);
    return (
      <div role="alert" style={{ padding: "0.75rem 1rem", fontSize: "0.85rem", color: "#c62828" }}>
        Order Assistant unavailable: {error}
      </div>
    );
  }

  return <div ref={containerRef} style={{ width: "100%", height: "100%" }} />;
}
