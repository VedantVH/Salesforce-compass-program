public class AgentforceComplianceActions {
    @InvocableMethod(label='Run Compliance Assessment' description='Runs full DPDP compliance check')
    public static List<String> runAssessment(List<String> names) {
        List<String> results = new List<String>();
        for (String name : names) {
            Id assessmentId = ComplianceAssessmentService.runAssessment(name);
            results.add(String.valueOf(assessmentId));
        }
        return results;
    }
    
    @InvocableMethod(label='Get Readiness Report' description='Returns DPDP readiness summary')
    public static List<String> getReadinessReport(List<String> ids) {
        List<String> summaries = new List<String>();
        for (String id : ids) {
            ReadinessAdvisorService.ReadinessReport r = ReadinessAdvisorService.getReport((Id)id);
            summaries.add('Score: ' + r.overallRiskScore
                + ' | Level: ' + r.readinessLevel
                + ' | Fix: ' + String.join(r.topFixes, ', '));
        }
        return summaries;
    }
}
