# ComplyLens: Salesforce-Native DPDP Compliance Copilot

ComplyLens is a platform-native Salesforce application designed to help organizations assess, monitor, and remediate customer data compliance under India's **Digital Personal Data Protection (DPDP) Act, 2023**.

This project was built and implemented as a part of the **Salesforce Compass Program**.

---

## Technical Architecture

ComplyLens is built entirely on the Salesforce platform, adhering to a strict **"Deterministic Logic, AI-driven Explanation"** design principle:
1. **Deterministic Rule Engine (Apex)**: All compliance determinations are made by configured Apex rules running on Salesforce data—never inferred by AI.
2. **Salesforce Native Schema (Custom Objects)**: All compliance states, rules, assessments, audit logs, and recommendations are stored natively.
3. **Agentforce Integration**: Agentforce functions purely as an explanation layer to read, summarize, and explain the deterministic compliance results to business users.

```
                  +-----------------------------------+
                  |   Lightning Web Components (UI)   |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  |   Agentforce Explanation Layer    |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  |     Apex Backend Services         |
                  |  - Rule Engine    - Scoring       |
                  |  - Blast Radius   - Simulator     |
                  |  - Advisor & Recommendation       |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  |      Custom Salesforce Schema     |
                  +-----------------------------------+
```

---

## Custom Database Schema

### Standard Object Enhancements
- **Contact**: Enhanced with fields to track DPDP compliance status:
  - `Consent_Status__c` (Obtained / Not Obtained)
  - `Is_Minor__c` (Boolean)
  - `Parental_Consent__c` (Obtained / Not Obtained)
  - `Data_Category__c`
  - `Data_Retention_End_Date__c`
  - `Transparency_Notice_Provided__c`

### Core Custom Objects
- `Compliance_Assessment__c`: Header object representing a compliance audit run.
- `Compliance_Rule__c`: Configurable rules (e.g., Consent Check, Retention, Minor without consent) with severity risk score deductions.
- `Compliance_Result__c`: Individual evaluation record linking an assessment, a contact, and a compliance rule.
- `Compliance_Audit__c`: Secure audit log tracking assessment runs, fix simulations, and user actions.
- `Compliance_Recommendation__c`: Actionable tasks suggesting expected score improvements and remediation effort.

---

## Features Implemented (Backend Scope)

All backend features are fully implemented and 100% covered by Apex unit tests:

### 1. Deterministic Rule Engine
- **Class**: [DPDPRuleEngineService.cls](force-app/main/default/classes/DPDPRuleEngineService.cls)
- **Description**: Evaluates contact records against active compliance rules (e.g., Consent Validation, Data Retention limits, Children's Privacy consent checks) and outputs detailed failure reasons and risk deductions.

### 2. Assessment Risk Scoring
- **Class**: [RiskScoringService.cls](force-app/main/default/classes/RiskScoringService.cls)
- **Description**: Calculates the overall compliance score (0% to 100% risk) of a given assessment run based on rule validation failure rates.

### 3. Contact & Business Blast Radius
- **Class**: [BlastRadiusService.cls](force-app/main/default/classes/BlastRadiusService.cls)
- **Description**: Aggregates and quantifies the total exposure by evaluating the proportion of the contact database affected by rule failures.

### 4. In-Memory Fix Simulator
- **Class**: [FixSimulatorService.cls](force-app/main/default/classes/FixSimulatorService.cls)
- **Description**: Evaluates the projected score improvement when a correction scenario is simulated (e.g., renewing consent) without altering actual contact data. Writes all simulation events into `Compliance_Audit__c`.

### 5. Readiness Advisor & Recommendation Engine
- **Class**: [ReadinessAdvisorService.cls](force-app/main/default/classes/ReadinessAdvisorService.cls)
- **Description**: Evaluates rule failures, generates prioritized `Compliance_Recommendation__c` records sorted by severity, score impact, and estimated effort, and displays them inside the Readiness Report.

### 6. Agentforce Action Endpoints
- **Class**: [AgentforceComplianceActions.cls](force-app/main/default/classes/AgentforceComplianceActions.cls)
- **Description**: Exposes invocable Apex methods (`runAssessment` and `getReadinessReport`) to integrate seamlessly with Agentforce Copilots for conversational audit summaries.

---

## Unit Testing & Verification

Comprehensive test classes cover every branch of the business logic:
- [DPDPRuleEngineServiceTest.cls](force-app/main/default/classes/DPDPRuleEngineServiceTest.cls)
- [RiskScoringServiceTest.cls](force-app/main/default/classes/RiskScoringServiceTest.cls)
- [BlastRadiusServiceTest.cls](force-app/main/default/classes/BlastRadiusServiceTest.cls)
- [FixSimulatorServiceTest.cls](force-app/main/default/classes/FixSimulatorServiceTest.cls)
- [ReadinessAdvisorServiceTest.cls](force-app/main/default/classes/ReadinessAdvisorServiceTest.cls)
- [ComplianceAssessmentServiceTest.cls](force-app/main/default/classes/ComplianceAssessmentServiceTest.cls)
- [AgentforceComplianceActionsTest.cls](force-app/main/default/classes/AgentforceComplianceActionsTest.cls)
