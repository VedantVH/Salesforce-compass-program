@isTest
public class ReadinessAdvisorServiceTest {
    @isTest
    static void testGetReport() {
        // Create assessment
        Compliance_Assessment__c assessment = new Compliance_Assessment__c(Name = 'Readiness Audit');
        insert assessment;
        
        // Create rule of type 'Consent'
        Compliance_Rule__c rule = new Compliance_Rule__c(
            Name = 'Consent Check',
            Rule_Type__c = 'Consent',
            Is_Active__c = true,
            Severity_Score__c = 30
        );
        insert rule;
        
        Contact c = new Contact(LastName = 'TestUser');
        insert c;
        
        // 1 Fail result -> 100% fail -> readiness level should be 'Low' (since score 100 >= 70)
        Compliance_Result__c result = new Compliance_Result__c(
            Compliance_Assessment__c = assessment.Id,
            Compliance_Rule__c = rule.Id,
            Contact__c = c.Id,
            Status__c = 'Fail',
            Risk_Score__c = 30
        );
        insert result;
        
        Test.startTest();
        // Generate recommendations
        ReadinessAdvisorService.generateRecommendations(assessment.Id);
        
        // Get Readiness Report
        ReadinessAdvisorService.ReadinessReport report = ReadinessAdvisorService.getReport(assessment.Id);
        Test.stopTest();
        
        System.assertEquals(100.0, report.overallRiskScore, 'Risk score should be 100%');
        System.assertEquals('Low', report.readinessLevel, 'With 100% risk score, readiness level should be Low');
        System.assertEquals(1, report.topFixes.size());
        System.assertEquals('Fix: Consent', report.topFixes[0]);
        
        // Verify persisted recommendation is retrieved
        System.assertEquals(1, report.recommendations.size(), 'Should retrieve 1 recommendation');
        System.assertEquals('Recommendation: Renew Consent', report.recommendations[0].Name);
        System.assertEquals('High', report.recommendations[0].Priority__c);
        System.assertEquals(30, report.recommendations[0].Score_Impact__c);
        System.assertEquals('Medium', report.recommendations[0].Remediation_Effort__c);
    }
}
