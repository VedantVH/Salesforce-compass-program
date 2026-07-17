public class ComplianceAssessmentService {
    public static Id runAssessment(String assessmentName) {
        Compliance_Assessment__c assessment = new Compliance_Assessment__c(Name = assessmentName);
        insert assessment;
        
        // Query OUTSIDE the loop to satisfy Salesforce governor limits
        List<Compliance_Rule__c> rules = [
            SELECT Id, Rule_Type__c, Max_Retention_Days__c, Severity_Score__c
            FROM Compliance_Rule__c 
            WHERE Is_Active__c = true
            LIMIT 100
        ];
        
        List<Contact> contacts = [
            SELECT Id, Name, Consent_Status__c, Data_Category__c,
                   Is_Minor__c, Parental_Consent__c, CreatedDate
            FROM Contact 
            LIMIT 200
        ];
        
        List<Compliance_Result__c> allResults = new List<Compliance_Result__c>();
        for (Compliance_Rule__c rule : rules) {
            List<DPDPRuleEngineService.RuleResult> res = DPDPRuleEngineService.evaluate(rule, contacts);
            for (DPDPRuleEngineService.RuleResult r : res) {
                allResults.add(new Compliance_Result__c(
                    Compliance_Assessment__c = assessment.Id,
                    Contact__c = r.contactId,
                    Compliance_Rule__c = rule.Id,
                    Status__c = r.passed ? 'Pass' : 'Fail',
                    Risk_Score__c = r.riskScore,
                    Fail_Reason__c = r.failReason
                ));
            }
        }
        
        if (!allResults.isEmpty()) {
            insert allResults; // Bulk insert AFTER loop
        }
        
        // Generate recommendations for the failed results
        ReadinessAdvisorService.generateRecommendations(assessment.Id);
        
        // Log the assessment run event in the compliance audit trail
        Compliance_Audit__c audit = new Compliance_Audit__c(
            Name = 'Assessment Run: ' + assessmentName,
            Compliance_Assessment__c = assessment.Id,
            Event_Type__c = 'Assessment Run',
            Event_Date__c = DateTime.now(),
            Details__c = 'Assessment completed with ' + allResults.size() + ' compliance results.'
        );
        insert audit;
        
        return assessment.Id;
    }
}
