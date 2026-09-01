/**
 * The reference Skill — one capability, surfaced across three surfaces.
 * @InvocableMethod with Apex Request/Response classes: the Apex-class in/out shape is what makes
 * this action CLT-eligible (Custom Lightning Types render Apex-backed action output).
 *
 * Queries the reference demo object Order__c (by Order_Number__c). Reskin: point the SOQL at your
 * own order/case/shipment object and map the fields — the Request/Response contract stays the same.
 *
 * `global` (not `public`): a Salesforce-hosted MCP server auto-exposes only `global`
 * @InvocableMethod classes as tools — a `public` class must instead be registered in
 * Setup → API Catalog. The whole chain (class + method + Request/Response/Card + their
 * @InvocableVariable fields) is promoted so the exposed surface is unambiguous. See
 * Module 3a — "Add your Apex action".
 */
global with sharing class OrderStatusSkill {
    global class Request {
        @InvocableVariable(required=true label='Order Number')
        global String orderNumber;
    }
    /**
     * The display shape for the in-conversation rich card (Surface #3, Custom Lightning Type).
     * This inner class is what the CLT binds to: OrderStatusCard/schema.json references it as
     * `@apexClassType/c__OrderStatusSkill$Card`, and the renderer LWC receives it via `@api value`.
     * It intentionally mirrors the flat Response fields — the CLT needs ONE displayable object to
     * attach the renderer to (flat outputs cannot be bound; verified against Salesforce's
     * agent-script-recipes customLightningTypes example, 2026-07-23).
     */
    global class Card {
        @InvocableVariable global String orderNumber;
        @InvocableVariable global String status;
        @InvocableVariable global String owner;
        @InvocableVariable global String summary;
        @InvocableVariable global String availableAction;
        @InvocableVariable global String recordId;
        @InvocableVariable global Boolean found;
    }

    global class Response {
        @InvocableVariable global String orderNumber;
        @InvocableVariable global String status;      // Processing / Shipped / Delivered / Exception / Not Found
        @InvocableVariable global String owner;
        @InvocableVariable global String summary;
        @InvocableVariable global String availableAction; // the one in-flow action (e.g. "Approve rebooking")
        @InvocableVariable global String recordId;    // real Order__c Id — used for the "view record" link
        @InvocableVariable global Boolean found;
        // The same data as a single object — this is the CLT-displayable output that renders the
        // rich card in-conversation. The flat fields above stay for the agent's text reasoning.
        @InvocableVariable global Card card;
    }

    @InvocableMethod(label='Get Order Status' description='Returns status + one available action for an order (reference Skill).')
    global static List<Response> getStatus(List<Request> requests) {
        // Collect the requested order numbers and query once (bulk-safe).
        Set<String> numbers = new Set<String>();
        for (Request req : requests) {
            if (String.isNotBlank(req.orderNumber)) numbers.add(req.orderNumber);
        }
        Map<String, Order__c> byNumber = new Map<String, Order__c>();
        for (Order__c o : [
            SELECT Id, Order_Number__c, Status__c, Owner_Name__c, Status_Summary__c, Next_Action__c
            FROM Order__c
            WHERE Order_Number__c IN :numbers
            WITH USER_MODE
        ]) {
            byNumber.put(o.Order_Number__c, o);
        }

        List<Response> out = new List<Response>();
        for (Request req : requests) {
            Response r = new Response();
            r.orderNumber = req.orderNumber;
            Order__c o = byNumber.get(req.orderNumber);
            if (o == null) {
                r.found = false;
                r.status = 'Not Found';
                r.summary = 'No order matches "' + req.orderNumber + '".';
            } else {
                r.found = true;
                r.status = o.Status__c;
                r.owner = o.Owner_Name__c;
                r.summary = o.Status_Summary__c;
                r.availableAction = String.isNotBlank(o.Next_Action__c) ? o.Next_Action__c : 'View details';
                r.recordId = o.Id;
            }
            // Mirror the flat fields into the displayable card object (the CLT-bound output).
            Card c = new Card();
            c.orderNumber = r.orderNumber;
            c.status = r.status;
            c.owner = r.owner;
            c.summary = r.summary;
            c.availableAction = r.availableAction;
            c.recordId = r.recordId;
            c.found = r.found;
            r.card = c;
            out.add(r);
        }
        return out;
    }
}
