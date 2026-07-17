public class ReadinessAdvisorService {
    public class ReadinessReport {
        @AuraEnabled public Decimal overallRiskScore;
        @AuraEnabled public String readinessLevel; // High / Medium / Low
        @AuraEnabled public List<String> topFixes;
        @AuraEnabled public List<Compliance_Recommendation__c> recommendations;
    }
    
    public static ReadinessReport getReport(Id assessmentId) {
        ReadinessReport report = new ReadinessReport();
        report.overallRiskScore = RiskScoringService.calculateRiskScore(assessmentId);
        if (report.overallRiskScore < 30) {
            report.readinessLevel = 'High';
        } else if (report.overallRiskScore < 70) {
            report.readinessLevel = 'Medium';
        } else {
            report.readinessLevel = 'Low';
        }
        report.topFixes = getTopFixes(assessmentId);
        report.recommendations = [
            SELECT Id, Name, Description__c, Priority__c, Score_Impact__c, Remediation_Effort__c
            FROM Compliance_Recommendation__c
            WHERE Compliance_Assessment__c = :assessmentId
            ORDER BY Score_Impact__c DESC
            LIMIT 50
        ];
        return report;
    }
    
    public static void generateRecommendations(Id assessmentId) {
        // Delete existing recommendations for this assessment to avoid duplicates
        List<Compliance_Recommendation__c> existing = [
            SELECT Id FROM Compliance_Recommendation__c 
            WHERE Compliance_Assessment__c = :assessmentId
            LIMIT 10000
        ];
        if (!existing.isEmpty()) {
            delete existing;
        }
        
        List<AggregateResult> ar = [
            SELECT Compliance_Rule__r.Rule_Type__c ruleType,
                   MAX(Compliance_Rule__r.Severity_Score__c) maxSeverity
            FROM Compliance_Result__c
            WHERE Compliance_Assessment__c = :assessmentId
            AND Status__c = 'Fail'
            GROUP BY Compliance_Rule__r.Rule_Type__c
        ];
        
        List<Compliance_Recommendation__c> recs = new List<Compliance_Recommendation__c>();
        for (AggregateResult a : ar) {
            Object rt = a.get('ruleType');
            String ruleTypeName = rt != null ? String.valueOf(rt) : 'Unknown';
            Object ms = a.get('maxSeverity');
            Decimal severity = ms != null ? (Decimal)ms : 0;
            
            Compliance_Recommendation__c rec = new Compliance_Recommendation__c();
            rec.Compliance_Assessment__c = assessmentId;
            rec.Score_Impact__c = severity;
            
            if (ruleTypeName == 'Consent') {
                rec.Name = 'Recommendation: Renew Consent';
                rec.Description__c = 'Obtain or renew consent for contacts with missing consent.';
                rec.Priority__c = 'High';
                rec.Remediation_Effort__c = 'Medium';
            } else if (ruleTypeName == 'Data Retention') {
                rec.Name = 'Recommendation: Purge Expired Data';
                rec.Description__c = 'Purge or archive records that exceed the configured retention limit.';
                rec.Priority__c = 'Medium';
                rec.Remediation_Effort__c = 'Low';
            } else if (ruleTypeName == 'Children') {
                rec.Name = 'Recommendation: Minor Verification';
                rec.Description__c = 'Verify age and parental consent for minor contacts.';
                rec.Priority__c = 'High';
                rec.Remediation_Effort__c = 'High';
            } else {
                rec.Name = 'Recommendation: Fix ' + ruleTypeName;
                rec.Description__c = 'Remediate failures for compliance rule type: ' + ruleTypeName;
                rec.Priority__c = severity >= 30 ? 'High' : 'Medium';
                rec.Remediation_Effort__c = 'Medium';
            }
            recs.add(rec);
        }
        
        if (!recs.isEmpty()) {
            insert recs;
        }
    }
    
    private static List<String> getTopFixes(Id assessmentId) {
        List<String> fixes = new List<String>();
        List<AggregateResult> ar = [
            SELECT Compliance_Rule__r.Rule_Type__c ruleType, COUNT(Id) failCount
            FROM Compliance_Result__c
            WHERE Compliance_Assessment__c = :assessmentId
            AND Status__c = 'Fail'
            GROUP BY Compliance_Rule__r.Rule_Type__c
            ORDER BY COUNT(Id) DESC 
            LIMIT 3
        ];
        for (AggregateResult a : ar) {
            Object rt = a.get('ruleType');
            String ruleTypeName = rt != null ? String.valueOf(rt) : 'Unknown';
            fixes.add('Fix: ' + ruleTypeName);
        }
        return fixes;
    }
}
