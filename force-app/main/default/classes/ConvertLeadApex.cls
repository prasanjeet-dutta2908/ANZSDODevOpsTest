public with sharing class ConvertLeadApex {
    
    @InvocableMethod(label='Convert Lead' description='Converts a lead into an account, a contact, and optionally an opportunity.')
    public static List<LeadConversionResult> convertLeads(List<LeadConversionRequest> requests) {
        List<LeadConversionResult> results = new List<LeadConversionResult>();

        for (LeadConversionRequest request : requests) {
            LeadConversionResult result = new LeadConversionResult();
           // try {
                System.debug('Processing Lead ID: ' + request.leadId);
                
                // Convert the lead using helper method
                Map<String, String> conversionResult = convertLead(request);
                system.debug('request' +request);
                
                result.accountId = conversionResult.get('AccountId');
                result.contactId = conversionResult.get('ContactId');
                result.opportunityId = conversionResult.get('OpportunityId');
                result.success = true;
           // } catch (Exception e) {
               // result.success = false;
                //result.errorMessage = e.getMessage();
                //System.debug('Lead Conversion Failed: ' + e.getMessage());
            //}
            results.add(result);
        }
        return results;
    }

    private static Map<String, String> convertLead(LeadConversionRequest request) {
        Map<String, String> result = new Map<String, String>();

        if (request.leadId == null) {
            throw new LeadConversionException('Lead ID cannot be null.');
        }

        Lead leadRecord = [SELECT Id, Company, RecordTypeId FROM Lead WHERE Id = :request.leadId LIMIT 1];

        System.debug('Found Lead: ' + leadRecord.Id + ', Record Type: ' + leadRecord.RecordTypeId);

        // Ensure Account is created or mapped correctly
       String accountId;
        if (request.accountId == null) {
            if (leadRecord.Company != null) {
                // Create or find a Business Account
                Account[] accounts = [SELECT Id FROM Account WHERE Name = :leadRecord.Company LIMIT 1];
                if (accounts.size() > 0) {
                    accountId = accounts[0].Id;
                } else {
                    Account newAccount = new Account(
                        Name = leadRecord.Company,
                        RecordTypeId = '012Kc0000011nohIAA' // Replace with your Business Account Record Type ID
                    );
                    insert newAccount;
                    accountId = newAccount.Id;
                    System.debug('Created Business Account: ' + accountId);
                }
            } else {
                // Create a Person Account (if enabled in org)
                Account newPersonAccount = new Account(
                    FirstName = leadRecord.FirstName,
                    LastName = leadRecord.LastName,
                    RecordTypeId = '012Kc0000011nocIAA' // Replace with your Person Account Record Type ID
                );
                insert newPersonAccount;
                accountId = newPersonAccount.Id;
                System.debug('Created Person Account: ' + accountId);
            }
        }
        // Set up lead conversion process
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(request.leadId);
        lc.setConvertedStatus(request.convertedStatus);
        lc.setDoNotCreateOpportunity(!request.createOpportunity);
        if (request.overwriteLeadSource != null) lc.setOverwriteLeadSource(request.overwriteLeadSource);
        if (request.sendEmailToOwner != null) lc.setSendNotificationEmail(request.sendEmailToOwner);
        if (accountId != null) lc.setAccountId(accountId);
        if (request.contactId != null) lc.setContactId(request.contactId);
        if (request.createOpportunity) lc.setOpportunityName(request.opportunityName);

        // Execute Lead Conversion
        Database.LeadConvertResult conversionResult = Database.convertLead(lc);
        if (conversionResult.isSuccess()) {
            result.put('AccountId', conversionResult.getAccountId());
            result.put('ContactId', conversionResult.getContactId());
            if (request.createOpportunity) {
                result.put('OpportunityId', conversionResult.getOpportunityId());
            }
            System.debug('Lead Conversion Successful!');
        } else {
            throw new LeadConversionException('Lead conversion failed: ' + conversionResult.getErrors()[0].getMessage());
        }

        return result;
    }

    // Data Wrapper for Invocable Apex
    public class LeadConversionRequest {
        @InvocableVariable(required=true)
        public String leadId;
        @InvocableVariable
        public String contactId;
        @InvocableVariable
        public String accountId;
        @InvocableVariable(required=true)
        public String convertedStatus;
        @InvocableVariable
        public Boolean overwriteLeadSource;
        @InvocableVariable
        public Boolean createOpportunity;
        @InvocableVariable
        public String opportunityName;
        @InvocableVariable
        public Boolean sendEmailToOwner;
    }

    public class LeadConversionResult {
        @InvocableVariable
        public String accountId;
        @InvocableVariable
        public String contactId;
        @InvocableVariable
        public String opportunityId;
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
    }

    public class LeadConversionException extends Exception {}
}