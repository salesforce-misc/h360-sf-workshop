/**
 * Backing controller for the HXL Widget Viewer LWC.
 *
 * Reads HXL "Mosaic" widgets (UiWidgetBundle / content type `lightning__agentforceWidget`)
 * so they can be browsed + inspected in-org.
 *
 * - listWidgets(): SOQL over ManagedContent (the widget list — includes drafts).
 * - getWidgetBody(): the widget body JSON is NOT a SOQL field and ConnectApi channel reads
 *   return nothing for unpublished/draft widgets, so we self-callout to the Connect authoring
 *   REST endpoint (returns the full contentBody, incl. drafts). Requires a RemoteSiteSetting
 *   for the org My Domain — provisioned per-org by scripts/deploy-hxl-viewer.sh.
 */
public with sharing class HxlWidgetViewerController {

    @TestVisible private static final String WIDGET_TYPE = 'lightning__agentforceWidget';
    @TestVisible private static final String API_VERSION = 'v67.0';

    public class WidgetSummary {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String apiName;
        @AuraEnabled public String language;
    }

    @AuraEnabled(cacheable=true)
    public static List<WidgetSummary> listWidgets() {
        List<WidgetSummary> out = new List<WidgetSummary>();
        for (ManagedContent mc : [
            SELECT Id, Name, ApiName, PrimaryLanguage
            FROM ManagedContent
            WHERE ContentTypeFullyQualifiedName = :WIDGET_TYPE
            ORDER BY Name
        ]) {
            WidgetSummary w = new WidgetSummary();
            w.id = mc.Id;
            w.name = mc.Name;
            w.apiName = mc.ApiName;
            w.language = mc.PrimaryLanguage;
            out.add(w);
        }
        return out;
    }

    @AuraEnabled
    public static String getWidgetBody(String contentId) {
        if (String.isBlank(contentId)) {
            throw new AuraHandledException('A widget content id is required.');
        }
        String endpoint = URL.getOrgDomainUrl().toExternalForm()
            + '/services/data/' + API_VERSION + '/connect/cms/contents/'
            + EncodingUtil.urlEncode(contentId, 'UTF-8');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + apiSessionId());
        req.setHeader('Accept', 'application/json');
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new AuraHandledException(
                'Connect CMS API returned ' + res.getStatusCode()
                + '. If this is a callout error, confirm the RemoteSiteSetting for this org '
                + '(scripts/deploy-hxl-viewer.sh provisions it).');
        }
        return res.getBody();
    }

    /**
     * An API-enabled session id for the self-callout. In Lightning (Aura/LWC) context
     * UserInfo.getSessionId() returns a session that is NOT API-enabled (self-callouts 401),
     * so we render a Visualforce page that emits $Api.Session_ID. Falls back to
     * UserInfo.getSessionId() in test/other contexts where getContent() is unavailable.
     */
    @TestVisible
    private static String apiSessionId() {
        if (Test.isRunningTest()) {
            return UserInfo.getSessionId();
        }
        try {
            String sid = Page.HxlApiSession.getContent().toString().trim();
            if (String.isNotBlank(sid)) {
                return sid;
            }
        } catch (Exception e) {
            // fall through to the Lightning session (may 401, but better than a hard error)
        }
        return UserInfo.getSessionId();
    }
}
