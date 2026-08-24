@isTest
private class HxlWidgetViewerControllerTest {

    private class BodyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(200);
            r.setBody('{"apiName":"HelloWorld","contentType":{"fullyQualifiedName":"lightning__agentforceWidget"},'
                + '"contentBody":{"widgetBody":{"definition":"tile/widget","children":['
                + '{"definition":"tile/text","attributes":{"text":"Hi"}}]}}}');
            return r;
        }
    }

    private class ErrMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(404);
            r.setBody('not found');
            return r;
        }
    }

    @isTest
    static void listWidgets_runsWithoutError() {
        // No dependency on org data: an empty result is valid.
        Test.startTest();
        List<HxlWidgetViewerController.WidgetSummary> ws = HxlWidgetViewerController.listWidgets();
        Test.stopTest();
        System.assertNotEquals(null, ws, 'listWidgets should return a (possibly empty) list');
    }

    @isTest
    static void getWidgetBody_returnsJson() {
        Test.setMock(HttpCalloutMock.class, new BodyMock());
        Test.startTest();
        String body = HxlWidgetViewerController.getWidgetBody('20Ybm00000AyunxEAB');
        Test.stopTest();
        System.assert(body.contains('widgetBody'), 'body should contain widgetBody');
        System.assert(body.contains('tile/widget'), 'body should contain the root tile');
    }

    @isTest
    static void getWidgetBody_blankThrows() {
        Boolean threw = false;
        Test.startTest();
        try {
            HxlWidgetViewerController.getWidgetBody('');
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'blank contentId should throw');
    }

    @isTest
    static void getWidgetBody_nonOkStatusThrows() {
        Test.setMock(HttpCalloutMock.class, new ErrMock());
        Boolean threw = false;
        Test.startTest();
        try {
            HxlWidgetViewerController.getWidgetBody('MCID_DOES_NOT_EXIST');
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'a non-200 response should throw');
    }
}
