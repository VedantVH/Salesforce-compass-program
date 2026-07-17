@isTest
public class ComplianceAssessmentServiceTest {
    @isTest
    static void testRunAssessment() {
        // Insert active rules
        List<Compliance_Rule__c> rules = new List<Compliance_Rule__c>{
            new Compliance_Rule__c(Name = 'Consent Check', Rule_Type__c = 'Consent', Is_Active__c = true, Severity_Score__c = 30),
            new Compliance_Rule__c(Name = 'Retention Check', Rule_Type__c = 'Data Retention', Max_Retention_Days__c = 365, Is_Active__c = true, Severity_Score__c = 20)
        };
        insert rules;
        
        // Insert contacts
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Aisha', LastName = 'Mehta', Consent_Status__c = 'Obtained'),
            new Contact(FirstName = 'Rahul', LastName = 'Sharma', Consent_Status__c = 'Not Obtained')
        };
        insert contacts;
        
        Test.startTest();
        Id assessmentId = ComplianceAssessmentService.runAssessment('Quarterly Audit');
        Test.stopTest();
        
        // Verify Assessment is inserted
        Compliance_Assessment__c assessment = [SELECT Id, Name FROM Compliance_Assessment__c WHERE Id = :assessmentId];
        System.assertEquals('Quarterly Audit', assessment.Name);
        
        // Verify Compliance Results are inserted
        // 2 rules * 2 contacts = 4 results
        List<Compliance_Result__c> results = [
            SELECT Id, Compliance_Assessment__c, Contact__c, Status__c, Risk_Score__c
            FROM Compliance_Result__c
            WHERE Compliance_Assessment__c = :assessmentId
        ];
        System.assertEquals(4, results.size(), 'There should be 4 compliance result records');
        
        // Verify recommendations were generated and persisted
        List<Compliance_Recommendation__c> recommendations = [
            SELECT Id, Name, Priority__c, Score_Impact__c
            FROM Compliance_Recommendation__c
            WHERE Compliance_Assessment__c = :assessmentId
        ];
        System.assertEquals(1, recommendations.size(), 'Should have generated 1 recommendation due to Rahul lacking consent');
        System.assertEquals('Recommendation: Renew Consent', recommendations[0].Name);
        System.assertEquals('High', recommendations[0].Priority__c);
        System.assertEquals(30, recommendations[0].Score_Impact__c);
        
        // Verify compliance audit record was inserted
        List<Compliance_Audit__c> audits = [
            SELECT Id, Name, Event_Type__c, Details__c
            FROM Compliance_Audit__c
            WHERE Compliance_Assessment__c = :assessmentId
        ];
        System.assertEquals(1, audits.size(), 'Should have inserted 1 compliance audit trail log');
        System.assertEquals('Assessment Run: Quarterly Audit', audits[0].Name);
        System.assertEquals('Assessment Run', audits[0].Event_Type__c);
        System.assert(audits[0].Details__c.contains('Assessment completed with 4 compliance results.'));
    }
}
