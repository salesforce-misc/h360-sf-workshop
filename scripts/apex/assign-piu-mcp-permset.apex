// Grant your External-MCP permission set to the Platform Integration User (PIU).
//
// WHY (the MCP-5 trap): an Agentforce agent's RUNTIME callout to an MCP server /
// external service runs as the Platform Integration User (the "cloud@..." principal),
// NOT the human/admin user. If you grant only yourself, your MCP Workbench / curl test
// passes while the WIRED agent silently returns "no data". The permset carries the
// External Credential principal access, so the PIU needs it too.
// Adapted from bstaubersalesforce/ncino-agentforce-workshop (Checkpoint 2p diagnostics).
// (See Module 8a — Connect your own External MCP Server.)
//
// 1) Set YOUR permset name below (the one granting your External Credential principal + API access).
// 2) Run:  sf apex run --file scripts/apex/assign-piu-mcp-permset.apex -o <alias>
//    Look for:  PIU_RESULT=✔   (or  ℹ already assigned)
String permSetName = 'REPLACE_WITH_YOUR_EXTERNAL_MCP_PERMSET';   // <-- edit for your external MCP server
try {
    List<User> matches = [SELECT Id, Name, Username FROM User WHERE Name LIKE 'Platform%' AND IsActive = true];
    if (matches.isEmpty()) {
        System.debug('PIU_RESULT=❌ No active user matching Name LIKE \'Platform%\' found.');
    } else {
        if (matches.size() > 1) {
            System.debug('PIU_WARN=Multiple Platform% users found; using ' + matches[0].Username);
        }
        User piu = matches[0];
        PermissionSet ps = [SELECT Id, Label FROM PermissionSet WHERE Name = :permSetName LIMIT 1];
        List<PermissionSetAssignment> existing = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :piu.Id AND PermissionSetId = :ps.Id
        ];
        if (existing.isEmpty()) {
            insert new PermissionSetAssignment(AssigneeId = piu.Id, PermissionSetId = ps.Id);
            System.debug('PIU_RESULT=✔ Assigned "' + ps.Label + '" to ' + piu.Name);
        } else {
            System.debug('PIU_RESULT=ℹ Already assigned to ' + piu.Name);
        }
    }
} catch (QueryException qe) {
    System.debug('PIU_RESULT=❌ User or PermissionSet not found (set permSetName): ' + qe.getMessage());
} catch (DmlException de) {
    System.debug('PIU_RESULT=❌ Assignment failed: ' + de.getMessage());
}
