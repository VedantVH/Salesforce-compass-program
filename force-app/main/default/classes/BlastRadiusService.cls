public class BlastRadiusService {
    public class BlastRadiusResult {
        @AuraEnabled public Integer affectedCount;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Decimal affectedPercentage;
    }
    
    public static BlastRadiusResult calculate(Id assessmentId) {
        BlastRadiusResult result = new BlastRadiusResult();
        result.totalCount = [SELECT COUNT() FROM Contact LIMIT 50000];
        result.affectedCount = [
            SELECT COUNT()
            FROM Compliance_Result__c
            WHERE Compliance_Assessment__c = :assessmentId
            AND Status__c = 'Fail'
            LIMIT 50000
        ];
        result.affectedPercentage = result.totalCount > 0
            ? (result.affectedCount * 100.0) / result.totalCount 
            : 0;
        return result;
    }
}
