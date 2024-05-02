public with sharing class OpportunityHelper {
    public List<Opportunity> newRecords;
    public List<Opportunity> oldRecords;
    public Map<Id,Opportunity> newRecordsMap;
    public Map<Id,Opportunity> oldRecordsMap;

    public OpportunityHelper() {
        this.newRecords = Trigger.new;
        this.oldRecords = Trigger.old;
        this.newRecordsMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldRecordsMap = (Map<Id, Opportunity>) Trigger.oldMap;
    }

    ///OpportunityTrigger.trigger implementation  ===== Opportunity Part 1

    public static void oppAmountValidation (List<Opportunity> newRecords) {
        for(Opportunity opp : newRecords){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }
    public static void closedWonOppDeletion(List<Opportunity> oldRecords){
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :oldRecords)]);
        for(Opportunity opp : oldRecords){
            if(opp.StageName == 'Closed Won'){
                if(accounts.get(opp.AccountId).Industry == 'Banking'){
                    opp.addError('Cannot delete a closed won opportunity for a banking account');
                }
            }
        }
    }

    public static void assignPrimaryContactWithTitleCEO(List<Opportunity> newRecords){
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : newRecords){
            accountIds.add(opp.AccountId);
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId, Title FROM Contact WHERE AccountId IN:accountIds AND Title = 'CEO' ORDER BY FirstName Asc]);
        Map<Id, Contact> accountIdToContacts = new Map<Id,Contact>();
        for(Contact con : contacts.values()){
            if(!accountIdToContacts.containsKey(con.AccountId)){
                accountIdToContacts.put(con.AccountId, con);
            }
        }
        for(Opportunity opp : newRecords){
            if(opp.Primary_Contact__c == null){
                if(accountIdToContacts.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContacts.get(opp.AccountId).Id;
                }
                
            }
        }

    }

        ///AnotherOpportunityTrigger.trigger implementation  ===== Opportunity Part 2

        public static void setOppType(List<Opportunity> newRecords){
            //Bulkified for multiple Opp records by not referring the 0 index record in the Opp list from AnotherOpportunityTrigger.
            List<Opportunity> oppsToBeUpdated = new List<Opportunity>();
            for(Opportunity opp : [SELECT Id, Name, Type FROM Opportunity WHERE Id IN : newRecords]){
                if(opp.Type == null){
                    opp.Type = 'New Customer';
                    oppsToBeUpdated.add(opp);
                }
            }
            update oppsToBeUpdated;
        }



        public static void closedOppValidation(List<Opportunity> oldRecords){
            for(Opportunity opp : oldRecords){
                if(opp.IsClosed){
                    opp.addError('Cannot delete closed opportunity');
                }
            }
        }

        public static void taskForNewOpp(List<Opportunity> newRecords){
            //Removed DML Operation within FOR Loop from AnotherOpportunityTrigger
            List<Task> newTasks = new List<Task>();
            for(Opportunity opp : newRecords){
                Task tsk = new Task(
                    Subject = 'Call Primary Contact',
                    WhatId = opp.Id,
                    OwnerId = opp.OwnerId,
                    Status = 'Not Started',
                    Priority = 'Normal'
                );
                newTasks.add(tsk);
            }
            insert newTasks;
        }

        public static void appendOppDesc(List<Opportunity> newRecords){
            for (Opportunity opp : newRecords){
                    if (opp.StageName != null){
                        opp.Description += '\n Stage Change:' +opp.StageName + ':' + DateTime.now().format();
                    }           
            }
        }

        public static void sendEmailWhenOppDeleted (List<Opportunity> oldRecords){
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage> ();
            Map<Id, String> oppIdToEmailMap = new Map<Id, String>();
            for(Opportunity opp : [SELECT Id, Owner.Email FROM Opportunity WHERE Id IN :oldRecords]){
                if(opp.Owner != null && opp.Owner.Email != null){
                   oppIdToEmailMap.put(opp.Id, opp.Owner.Email);
                }
            }
            
            for (Opportunity opp : oldRecords){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{oppIdToEmailMap.get(opp.Id)});
                mail.setSubject('Opportunity Deleted : ' + opp.Name);
                mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
                mails.add(mail);
        }        
            try {
                Messaging.sendEmail(mails);
            } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
            }
        }

        public static void assignPrimaryContactWithTitleVPSales(List<Opportunity> newRecords){

            Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : newRecords){
            accountIds.add(opp.AccountId);
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId, Title FROM Contact WHERE AccountId IN:accountIds AND Title = 'Vp Sales' ORDER BY FirstName Asc]);
        Map<Id, Contact> accountIdToContacts = new Map<Id,Contact>();
        for(Contact con : contacts.values()){
            if(!accountIdToContacts.containsKey(con.AccountId)){
                accountIdToContacts.put(con.AccountId, con);
            }
        }
        List <Opportunity> undeletedOpps = [SELECT Id, AccountId, Primary_Contact__c FROM Opportunity WHERE Id IN :newRecords];
        for(Opportunity opp : undeletedOpps){
            if(opp.Primary_Contact__c == null){
                if(accountIdToContacts.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContacts.get(opp.AccountId).Id;
                }
            }
        }
        update undeletedOpps;
    }
}