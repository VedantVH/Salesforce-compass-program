public class FixSimulatorService {
    public static Decimal simulateFix(Id assessmentId, String fixType) {
        List<Compliance_Result__c> results = [
            SELECT Status__c, Risk_Score__c,
                   Compliance_Rule__r.Rule_Type__c
            FROM Compliance_Result__c
            WHERE Compliance_Assessment__c = :assessmentId
            LIMIT 10000
        ];
        Integer simulatedFails = 0;
        for (Compliance_Result__c r : results) {
            Boolean stillFails = (r.Status__c == 'Fail');
            if (fixType == 'MarkAllConsentsObtained'
                && r.Compliance_Rule__r.Rule_Type__c == 'Consent') {
                stillFails = false; // simulated fix in memory only
            }
            if (stillFails) {
                simulatedFails++;
            }
        }
        Decimal simulatedScore = results.isEmpty() ? 0
            : (simulatedFails * 100.0) / results.size();

        // Log the simulation event in the compliance audit trail
        Compliance_Audit__c audit = new Compliance_Audit__c(
            Name = 'Simulation Run',
            Compliance_Assessment__c = assessmentId,
            Event_Type__c = 'Fix Simulation',
            Event_Date__c = DateTime.now(),
            Details__c = 'Simulated fix of type: ' + fixType + '. Projected score: ' + simulatedScore + '%'
        );
        insert audit;

        return simulatedScore;
    }
}
