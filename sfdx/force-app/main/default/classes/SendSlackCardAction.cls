/**
 * Slack surface (Tier 2) — posts a Block Kit card of the order status to a Slack channel.
 * The Block Kit is built EXPLICITLY here (not auto-rendered by HXL). Called by the agent via a Topic action.
 * Wiring: Named Credential Slack_API (https://slack.com/api) + a CUSTOM External Credential carrying a bearer bot token
 * (xoxb-, param BotToken on principal Slack_Bot_Principal) — NOT an OIDC Auth Provider. Bot scopes chat:write,
 * channels:read (+ chat:write.public). Secrets are org-config, not committed.
 */
public with sharing class SendSlackCardAction {
    public class Request {
        @InvocableVariable(required=true label='Slack Channel Id') public String channel;
        @InvocableVariable(required=true label='Order Number') public String orderNumber;
        @InvocableVariable(required=true label='Status') public String status;
        @InvocableVariable(label='Summary') public String summary;
        @InvocableVariable(label='Available Action') public String availableAction;
        @InvocableVariable(label='Record Id') public String recordId; // real Order__c Id → button opens the record
    }
    public class Response { @InvocableVariable public Boolean ok; @InvocableVariable public String detail; }

    @InvocableMethod(label='Send Slack Card' description='Posts a Block Kit card of the order status to a Slack channel.')
    public static List<Response> send(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request req : requests) {
            Response r = new Response();
            try {
                HttpRequest http = new HttpRequest();
                http.setEndpoint('callout:Slack_API/chat.postMessage');
                http.setMethod('POST');
                http.setHeader('Content-Type', 'application/json; charset=utf-8');
                http.setBody(buildBlockKit(req));
                HttpResponse resp = new Http().send(http);
                // Slack returns HTTP 200 even on logical failure (e.g. invalid_auth,
                // not_in_channel) — the truth is the `ok` field in the JSON body, NOT
                // the status code. Parse the body so success is reported honestly.
                Boolean slackOk = false;
                String slackErr = null;
                if (resp.getStatusCode() == 200 && String.isNotBlank(resp.getBody())) {
                    Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                    slackOk = (body.get('ok') == true);
                    slackErr = (String) body.get('error');
                }
                r.ok = slackOk;
                r.detail = slackOk ? 'posted (HTTP 200, ok:true)'
                                   : 'Slack rejected: ' + (slackErr != null ? slackErr : 'HTTP ' + resp.getStatusCode());
            } catch (Exception e) {
                r.ok = false; r.detail = e.getMessage();
            }
            out.add(r);
        }
        return out;
    }

    @TestVisible
    private static String buildBlockKit(Request req) {
        // Block Kit "card": a header + a section with the status + a context line + one action button.
        Map<String, Object> body = new Map<String, Object>{
            'channel' => req.channel,
            'text' => 'Order ' + req.orderNumber + ' — ' + req.status,
            'blocks' => new List<Object>{
                new Map<String, Object>{ 'type' => 'header',
                    'text' => new Map<String, Object>{ 'type' => 'plain_text', 'text' => 'Order ' + req.orderNumber } },
                new Map<String, Object>{ 'type' => 'section',
                    'text' => new Map<String, Object>{ 'type' => 'mrkdwn',
                        'text' => '*Status:* ' + req.status + (String.isBlank(req.summary) ? '' : '\n' + req.summary) } },
                new Map<String, Object>{ 'type' => 'actions',
                    'elements' => new List<Object>{
                        new Map<String, Object>{ 'type' => 'button',
                            'text' => new Map<String, Object>{ 'type' => 'plain_text',
                                'text' => String.isBlank(req.availableAction) ? 'View details' : req.availableAction },
                            // A `url` button opens a link and needs NO Slack Interactivity / backend.
                            // (A `value` button instead sends an interaction payload → requires the app
                            // to enable Interactivity + a Request URL to receive it — not wired here.)
                            // Links to the real Order__c record when we have its Id; else the list view.
                            'url' => URL.getOrgDomainUrl().toExternalForm()
                                + (String.isNotBlank(req.recordId)
                                    ? '/lightning/r/Order__c/' + req.recordId + '/view'
                                    : '/lightning/o/Order__c/list') } } }
            }
        };
        return JSON.serialize(body);
    }
}
