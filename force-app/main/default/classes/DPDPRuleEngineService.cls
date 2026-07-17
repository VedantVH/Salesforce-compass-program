public class DPDPRuleEngineService {
    public class RuleResult {
        @AuraEnabled public Id contactId;
        @AuraEnabled public Boolean passed;
        @AuraEnabled public String failReason;
        @AuraEnabled public Decimal riskScore;
    }
    
    public static List<RuleResult> evaluate(Compliance_Rule__c rule, List<Contact> contacts) {
        List<RuleResult> results = new List<RuleResult>();
        for (Contact c : contacts) {
            RuleResult r = new RuleResult();
            r.contactId = c.Id;
            r.passed = true;
            r.failReason = null;
            
            if (rule.Rule_Type__c == 'Consent') {
                r.passed = (c.Consent_Status__c == 'Obtained');
                if (!r.passed) {
                    r.failReason = 'No consent on record';
                }
            } else if (rule.Rule_Type__c == 'Data Retention') {
                if (c.CreatedDate != null && rule.Max_Retention_Days__c != null) {
                    Integer days = c.CreatedDate.date().daysBetween(Date.today());
                    r.passed = (days <= (Integer)rule.Max_Retention_Days__c);
                    if (!r.passed) {
                        r.failReason = 'Data kept beyond limit';
                    }
                }
            } else if (rule.Rule_Type__c == 'Children') {
                r.passed = !(c.Is_Minor__c == true && c.Parental_Consent__c != 'Obtained');
                if (!r.passed) {
                    r.failReason = 'Minor without parental consent';
                }
            }
            
            r.riskScore = r.passed ? 0 : rule.Severity_Score__c;
            if (r.riskScore == null) {
                r.riskScore = 0;
            }
            results.add(r);
        }
        return results;
    }
}
