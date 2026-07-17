@isTest
public class AgentforceComplianceActionsTest {
    @isTest
    static void testInvocableActions() {
        // Create an active rule and contact
        Compliance_Rule__c rule = new Compliance_Rule__c(
            Name = 'Consent Check',
            Rule_Type__c = 'Consent',
            Is_Active__c = true,
            Severity_Score__c = 30
        );
        insert rule;
        
        Contact c = new Contact(FirstName = 'Aisha', LastName = 'Mehta', Consent_Status__c = 'Obtained');
        insert c;
        
        Test.startTest();
        // Trigger Invocable Run Compliance Assessment
        List<String> runResults = AgentforceComplianceActions.runAssessment(new List<String>{'AI Scheduled Audit'});
        System.assertEquals(1, runResults.size());
        
        Id assessmentId = (Id)runResults[0];
        
        // Trigger Invocable Get Readiness Report
        List<String> reportSummaries = AgentforceComplianceActions.getReadinessReport(new List<String>{String.valueOf(assessmentId)});
        Test.stopTest();
        
        System.assertEquals(1, reportSummaries.size());
        String summary = reportSummaries[0];
        System.assert(summary.contains('Score: 0'), 'Score should be 0 because Aisha is compliant: ' + summary);
        System.assert(summary.contains('Level: High'), 'Level should be High: ' + summary);
    }
}
