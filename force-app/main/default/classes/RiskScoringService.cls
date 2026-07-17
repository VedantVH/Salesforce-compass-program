public class RiskScoringService {
    public static Decimal calculateRiskScore(Id assessmentId) {
        List<Compliance_Result__c> results = [
            SELECT Status__c, Risk_Score__c 
            FROM Compliance_Result__c
            WHERE Compliance_Assessment__c = :assessmentId
            LIMIT 10000
        ];
        if (results.isEmpty()) {
            return 0;
        }
        Integer failCount = 0;
        for (Compliance_Result__c r : results) {
            if (r.Status__c == 'Fail') {
                failCount++;
            }
        }
        return (failCount * 100.0) / results.size();
    }
}
