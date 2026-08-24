@isTest
private class SendSlackCardActionTest {
    private class Mock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assert(req.getEndpoint().endsWith('/chat.postMessage'), 'posts to chat.postMessage');
            System.assert(req.getBody().contains('blocks'), 'payload has Block Kit blocks');
            HttpResponse res = new HttpResponse(); res.setStatusCode(200); res.setBody('{"ok":true}'); return res;
        }
    }
    @isTest static void postsBlockKit() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        SendSlackCardAction.Request req = new SendSlackCardAction.Request();
        req.channel = 'C123'; req.orderNumber = 'OR-1001'; req.status = 'Shipped';
        req.summary = 'On the way'; req.availableAction = 'View details';
        Test.startTest();
        List<SendSlackCardAction.Response> res = SendSlackCardAction.send(new List<SendSlackCardAction.Request>{ req });
        Test.stopTest();
        System.assert(res[0].ok, 'callout should succeed');
    }
    @isTest static void buildsValidBlockKitJson() {
        SendSlackCardAction.Request req = new SendSlackCardAction.Request();
        req.channel = 'C1'; req.orderNumber = 'OR-2002'; req.status = 'Exception'; req.availableAction = 'Approve rebooking';
        String body = SendSlackCardAction.buildBlockKit(req);
        Object parsed = JSON.deserializeUntyped(body);
        System.assert(parsed instanceof Map<String,Object>, 'valid JSON object');
        System.assert(body.contains('Approve rebooking'), 'includes the action label');
    }
}
