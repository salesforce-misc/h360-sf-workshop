@isTest
private class OrderStatusSkillTest {
    // OrderStatusSkill queries Order__c WITH USER_MODE, so it enforces FLS as the running user.
    // Custom-field FLS on Order__c is NOT granted by profile (not even to System Administrator) —
    // it comes only via the Headless360_Workshop_Access permission set. So BOTH the seed insert
    // and the Skill call must run as a user assigned that permset; otherwise they fail with an FLS
    // DmlException on any org where the deploying user lacks that FLS (i.e. every fresh org).
    // We deliberately do NOT use @testSetup — that runs as the deploying user and would fail the
    // insert at FLS. Each test seeds inside its own System.runAs(permset user) block. See KNOWN-GAPS T12.
    private static void seedOrder() {
        insert new Order__c(
            Name = 'Test order', Order_Number__c = 'OR-1001', Status__c = 'Shipped',
            Owner_Name__c = 'Jordan Rivera', Status_Summary__c = 'Order OR-1001 shipped.',
            Next_Action__c = 'Track shipment'
        );
    }

    // A minimal standard user + the workshop permission set → the FLS the Skill's USER_MODE query needs.
    private static User permsetUser() {
        Profile p = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];
        String uniq = 'h360test' + String.valueOf(Datetime.now().getTime());
        User u = new User(
            FirstName = 'Headless', LastName = 'Tester', Alias = 'h360t',
            Email = uniq + '@example.com', Username = uniq + '@h360.test.invalid',
            ProfileId = p.Id, TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Headless360_Workshop_Access' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        return u;
    }

    @isTest static void returnsStatusForValidOrder() {
        User u = permsetUser();
        List<OrderStatusSkill.Response> res;
        System.runAs(u) {
            seedOrder();
            OrderStatusSkill.Request req = new OrderStatusSkill.Request();
            req.orderNumber = 'OR-1001';
            res = OrderStatusSkill.getStatus(new List<OrderStatusSkill.Request>{ req });
        }
        System.assertEquals(1, res.size());
        System.assert(res[0].found, 'valid order should be found');
        System.assertEquals('OR-1001', res[0].orderNumber);
        System.assertEquals('Shipped', res[0].status);
        System.assertNotEquals(null, res[0].recordId, 'should return the real record Id');
        System.assertNotEquals(null, res[0].availableAction);
        // The displayable card object (CLT-bound output) mirrors the flat fields.
        System.assertNotEquals(null, res[0].card, 'should return the displayable card object');
        System.assertEquals(res[0].orderNumber, res[0].card.orderNumber);
        System.assertEquals(res[0].status, res[0].card.status);
        System.assertEquals(res[0].summary, res[0].card.summary);
        System.assertEquals(res[0].availableAction, res[0].card.availableAction);
        System.assertEquals(res[0].recordId, res[0].card.recordId);
        System.assertEquals(true, res[0].card.found, 'card should mirror found=true');
    }

    @isTest static void handlesNotFound() {
        User u = permsetUser();
        List<OrderStatusSkill.Response> res;
        System.runAs(u) {
            OrderStatusSkill.Request req = new OrderStatusSkill.Request();
            req.orderNumber = 'nope';
            res = OrderStatusSkill.getStatus(new List<OrderStatusSkill.Request>{ req });
        }
        System.assert(!res[0].found, 'unknown order should not be found');
        System.assertEquals('Not Found', res[0].status);
        System.assertNotEquals(null, res[0].card, 'card should be populated even when not found');
        System.assertEquals(false, res[0].card.found, 'card should mirror found=false');
        System.assertEquals('Not Found', res[0].card.status);
    }
}
