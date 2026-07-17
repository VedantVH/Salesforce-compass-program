@isTest
public class FixSimulatorServiceTest {
    @isTest
    static void testSimulateFix() {
        // Create assessment
        Compliance_Assessment__c assessment = new Compliance_Assessment__c(Name = 'Simulation Audit');
        insert assessment;
        
        // Create rule of type 'Consent'
        Compliance_Rule__c rule = new Compliance_Rule__c(
            Name = 'Consent Check',
            Rule_Type__c = 'Consent',
            Is_Active__c = true
        );
        insert rule;
        
        Contact c = new Contact(LastName = 'TestUser');
        insert c;
        
        // Create a failed result linked to the Consent rule
        Compliance_Result__c result = new Compliance_Result__c(
            Compliance_Assessment__c = assessment.Id,
            Compliance_Rule__c = rule.Id,
            Contact__c = c.Id,
            Status__c = 'Fail',
            Risk_Score__c = 30
        );
        insert result;
        
        Test.startTest();
        Decimal simulatedScoreWithFix = FixSimulatorService.simulateFix(assessment.Id, 'MarkAllConsentsObtained');
        Decimal simulatedScoreWithoutFix = FixSimulatorService.simulateFix(assessment.Id, 'OtherFix');
        Test.stopTest();
        
        System.assertEquals(0, simulatedScoreWithFix, 'Simulating Consent fix should reduce risk score to 0%');
        System.assertEquals(100.0, simulatedScoreWithoutFix, 'Simulating an unrelated fix should keep risk score at 100%');
        
        // Verify compliance audit records are inserted
        List<Compliance_Audit__c> audits = [
            SELECT Id, Name, Event_Type__c, Details__c
            FROM Compliance_Audit__c
            WHERE Compliance_Assessment__c = :assessment.Id
        ];
        System.assertEquals(2, audits.size(), 'Should have logged 2 simulation events in the audit trail');
        System.assertEquals('Simulation Run', audits[0].Name);
        System.assertEquals('Fix Simulation', audits[0].Event_Type__c);
    }
}
