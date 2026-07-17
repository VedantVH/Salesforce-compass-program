@isTest
public class BlastRadiusServiceTest {
    @isTest
    static void testBlastRadius() {
        // Create assessment
        Compliance_Assessment__c assessment = new Compliance_Assessment__c(Name = 'Blast Audit');
        insert assessment;
        
        // Create rules and contacts
        Compliance_Rule__c rule = new Compliance_Rule__c(Name = 'Consent Check', Rule_Type__c = 'Consent', Is_Active__c = true);
        insert rule;
        
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Aisha', LastName = 'Mehta'),
            new Contact(FirstName = 'Rahul', LastName = 'Sharma'),
            new Contact(FirstName = 'Arjun', LastName = 'Rao')
        };
        insert contacts;
        
        // 2 fails out of 3 total contacts
        List<Compliance_Result__c> results = new List<Compliance_Result__c>{
            new Compliance_Result__c(
                Compliance_Assessment__c = assessment.Id,
                Compliance_Rule__c = rule.Id,
                Contact__c = contacts[0].Id,
                Status__c = 'Pass',
                Risk_Score__c = 0
            ),
            new Compliance_Result__c(
                Compliance_Assessment__c = assessment.Id,
                Compliance_Rule__c = rule.Id,
                Contact__c = contacts[1].Id,
                Status__c = 'Fail',
                Risk_Score__c = 30
            ),
            new Compliance_Result__c(
                Compliance_Assessment__c = assessment.Id,
                Compliance_Rule__c = rule.Id,
                Contact__c = contacts[2].Id,
                Status__c = 'Fail',
                Risk_Score__c = 30
            )
        };
        insert results;
        
        Test.startTest();
        BlastRadiusService.BlastRadiusResult res = BlastRadiusService.calculate(assessment.Id);
        Test.stopTest();
        
        System.assertEquals(3, res.totalCount, 'Total contacts should be 3');
        System.assertEquals(2, res.affectedCount, 'Affected contacts count should be 2');
        System.assertEquals((2.0 * 100.0) / 3.0, res.affectedPercentage, 'Affected percentage is 66.67%');
    }
}
