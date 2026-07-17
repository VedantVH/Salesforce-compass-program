@isTest
public class RiskScoringServiceTest {
    @isTest
    static void testCalculateRiskScore() {
        // Create assessment
        Compliance_Assessment__c assessment = new Compliance_Assessment__c(Name = 'Risk Audit');
        insert assessment;
        
        // Create rules and contacts for lookups
        Compliance_Rule__c rule = new Compliance_Rule__c(Name = 'Consent Check', Rule_Type__c = 'Consent', Is_Active__c = true);
        insert rule;
        
        Contact c = new Contact(LastName = 'TestUser');
        insert c;
        
        // 1 Pass and 1 Fail results => score should be (1/2)*100 = 50.0
        List<Compliance_Result__c> results = new List<Compliance_Result__c>{
            new Compliance_Result__c(
                Compliance_Assessment__c = assessment.Id,
                Compliance_Rule__c = rule.Id,
                Contact__c = c.Id,
                Status__c = 'Pass',
                Risk_Score__c = 0
            ),
            new Compliance_Result__c(
                Compliance_Assessment__c = assessment.Id,
                Compliance_Rule__c = rule.Id,
                Contact__c = c.Id,
                Status__c = 'Fail',
                Risk_Score__c = 30
            )
        };
        insert results;
        
        Test.startTest();
        Decimal score = RiskScoringService.calculateRiskScore(assessment.Id);
        Test.stopTest();
        
        System.assertEquals(50.0, score, 'Risk score should be 50.0%');
    }
    
    @isTest
    static void testCalculateRiskScoreEmpty() {
        // Create assessment with no results
        Compliance_Assessment__c assessment = new Compliance_Assessment__c(Name = 'Empty Audit');
        insert assessment;
        
        Test.startTest();
        Decimal score = RiskScoringService.calculateRiskScore(assessment.Id);
        Test.stopTest();
        
        System.assertEquals(0, score, 'Score should be 0 for assessment with no results');
    }
}
