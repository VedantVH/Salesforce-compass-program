@isTest
public class DPDPRuleEngineServiceTest {
    @testSetup
    static void setupData() {
        // Create demo contacts representing different compliance states
        List<Contact> contacts = new List<Contact>();
        
        // 1. Compliant contact (Consent obtained, not minor)
        contacts.add(new Contact(
            FirstName = 'Aisha',
            LastName = 'Mehta',
            Consent_Status__c = 'Obtained',
            Is_Minor__c = false
        ));
        
        // 2. Non-compliant contact (Consent missing)
        contacts.add(new Contact(
            FirstName = 'Rahul',
            LastName = 'Sharma',
            Consent_Status__c = 'Not Obtained',
            Is_Minor__c = false
        ));
        
        // 3. Minor with parental consent
        contacts.add(new Contact(
            FirstName = 'Karan',
            LastName = 'Gupta',
            Consent_Status__c = 'Obtained',
            Is_Minor__c = true,
            Parental_Consent__c = 'Obtained'
        ));
        
        // 4. Minor without parental consent
        contacts.add(new Contact(
            FirstName = 'Arjun',
            LastName = 'Rao',
            Consent_Status__c = 'Obtained',
            Is_Minor__c = true,
            Parental_Consent__c = 'Not Obtained'
        ));
        
        insert contacts;
    }
    
    @isTest
    static void testConsentRule() {
        Compliance_Rule__c rule = new Compliance_Rule__c(
            Rule_Type__c = 'Consent',
            Severity_Score__c = 30
        );
        
        List<Contact> contacts = [
            SELECT Id, Consent_Status__c, Is_Minor__c, Parental_Consent__c, CreatedDate 
            FROM Contact
        ];
        
        Test.startTest();
        List<DPDPRuleEngineService.RuleResult> results = DPDPRuleEngineService.evaluate(rule, contacts);
        Test.stopTest();
        
        // Verify results
        Map<Id, DPDPRuleEngineService.RuleResult> resultMap = new Map<Id, DPDPRuleEngineService.RuleResult>();
        for (DPDPRuleEngineService.RuleResult r : results) {
            resultMap.put(r.contactId, r);
        }
        
        Contact aisha = [SELECT Id FROM Contact WHERE FirstName = 'Aisha' LIMIT 1];
        Contact rahul = [SELECT Id FROM Contact WHERE FirstName = 'Rahul' LIMIT 1];
        
        System.assertEquals(true, resultMap.get(aisha.Id).passed, 'Aisha has consent and should pass');
        System.assertEquals(false, resultMap.get(rahul.Id).passed, 'Rahul lacks consent and should fail');
        System.assertEquals('No consent on record', resultMap.get(rahul.Id).failReason);
        System.assertEquals(30, resultMap.get(rahul.Id).riskScore);
    }
    
    @isTest
    static void testDataRetentionRule() {
        Compliance_Rule__c rule = new Compliance_Rule__c(
            Rule_Type__c = 'Data Retention',
            Max_Retention_Days__c = 10,
            Severity_Score__c = 20
        );
        
        // Query a contact and override their created date to simulate old data
        Contact aisha = [SELECT Id, CreatedDate FROM Contact WHERE FirstName = 'Aisha' LIMIT 1];
        Contact rahul = [SELECT Id, CreatedDate FROM Contact WHERE FirstName = 'Rahul' LIMIT 1];
        
        // Aisha is created today (0 days old, should pass 10 days retention rule)
        // Rahul created 15 days ago (should fail 10 days retention rule)
        Test.setCreatedDate(rahul.Id, DateTime.now().addDays(-15));
        
        List<Contact> contacts = [
            SELECT Id, Consent_Status__c, Is_Minor__c, Parental_Consent__c, CreatedDate 
            FROM Contact 
            WHERE Id IN (:aisha.Id, :rahul.Id)
        ];
        
        Test.startTest();
        List<DPDPRuleEngineService.RuleResult> results = DPDPRuleEngineService.evaluate(rule, contacts);
        Test.stopTest();
        
        Map<Id, DPDPRuleEngineService.RuleResult> resultMap = new Map<Id, DPDPRuleEngineService.RuleResult>();
        for (DPDPRuleEngineService.RuleResult r : results) {
            resultMap.put(r.contactId, r);
        }
        
        System.assertEquals(true, resultMap.get(aisha.Id).passed, 'Recent data should pass retention');
        System.assertEquals(false, resultMap.get(rahul.Id).passed, 'Old data exceeding max retention should fail');
        System.assertEquals('Data kept beyond limit', resultMap.get(rahul.Id).failReason);
        System.assertEquals(20, resultMap.get(rahul.Id).riskScore);
    }
    
    @isTest
    static void testChildrenRule() {
        Compliance_Rule__c rule = new Compliance_Rule__c(
            Rule_Type__c = 'Children',
            Severity_Score__c = 50
        );
        
        List<Contact> contacts = [
            SELECT Id, Consent_Status__c, Is_Minor__c, Parental_Consent__c, CreatedDate 
            FROM Contact
        ];
        
        Test.startTest();
        List<DPDPRuleEngineService.RuleResult> results = DPDPRuleEngineService.evaluate(rule, contacts);
        Test.stopTest();
        
        Map<Id, DPDPRuleEngineService.RuleResult> resultMap = new Map<Id, DPDPRuleEngineService.RuleResult>();
        for (DPDPRuleEngineService.RuleResult r : results) {
            resultMap.put(r.contactId, r);
        }
        
        Contact karan = [SELECT Id FROM Contact WHERE FirstName = 'Karan' LIMIT 1];
        Contact arjun = [SELECT Id FROM Contact WHERE FirstName = 'Arjun' LIMIT 1];
        
        System.assertEquals(true, resultMap.get(karan.Id).passed, 'Minor with parental consent should pass');
        System.assertEquals(false, resultMap.get(arjun.Id).passed, 'Minor without parental consent should fail');
        System.assertEquals('Minor without parental consent', resultMap.get(arjun.Id).failReason);
        System.assertEquals(50, resultMap.get(arjun.Id).riskScore);
    }
}
