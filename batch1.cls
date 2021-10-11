
global class APB014_Alert_Contract_Expiry_date implements Database.Batchable<sObject>{
    
    //Get every Contract with type<>NDA AND Amendment Contract Under Review=false AND status=Live 
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query='Select Id,  Owner.email, ContractNumber, OwnerId, owner.name, Accountid, account.name, account.owner.email, Expiry_Date__c From Contract Where Rolling_Contract_Extension__c = false AND Type__c != \'NDA\' AND Amendment_Contract_Under_Review__c = false AND Status = \'Live\'';
        return Database.getQueryLocator(query);
        
    }
    
    //Send Email to every Contract owner for remind Contract owner that the Contract expiry date is coming in 6 months or today
    global void execute(Database.BatchableContext BC, List<Contract> scope){
        list<Contract> contractList = new list<Contract>();
        
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(Contract ScopeContract : scope){
            system.debug('ScopeContract.Owner.Email ' + ScopeContract.Owner.Email);
            contractList.add(ScopeContract);
            
            List<String> sendTo = new List<String>();
            sendTo.add(ScopeContract.Owner.Email);
            
            List<String> sendTo2 = new List<String>();
            sendTo2.add(ScopeContract.Account.Owner.Email);
            
            Date aujourdhui = date.newInstance(
                date.today().year(),
                date.today().month(),
                date.today().day()
            );
            
            //  Check if the mail must and can be sent (user must be active, must not have an empty or '@accenture.com' email)
            //  if the contract expires in 6 month 
            if(ScopeContract.Expiry_Date__c == aujourdhui.addMonths(6) &&
               ScopeContract.Owner.email != null && 
               ScopeContract.Owner.email.indexOf('@accenture.com') == -1)
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                mail.setToAddresses(sendTo);
                mail.setCcAddresses(sendTo2);
                mail.setReplyTo('alert@ingenico.com');
                mail.setSenderDisplayName('Ingenico Salesforce');
                
                mail.setSubject('Contract Expiry in 6 Months');
                
                
                String body = 'Dear '+ScopeContract.Owner.Name+', <br><br>';
                body += 'Your Contract '+ScopeContract.ContractNumber+ ' for ' +ScopeContract.account.name+', is due to expire in 6 months.<br><br>';
                body += 'If you are initiating a contract extension, please update Salesforce to reflect this by creating a new Contract record. You must also tick the "Amendment Contract Under Review" tick-box within the existing Contract record.<br>';
                body += '<br>Click on link below to launch the Contract record: ';
                body += '<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+ScopeContract.id+'">'+ScopeContract.ContractNumber+'</a>';
                body += '<br><br>Thanks.';
                mail.setHtmlBody(body);
                mails.add(mail);
                
                
                //  if the contract expires today
            }else if(ScopeContract.Expiry_Date__c == aujourdhui &&
                     ScopeContract.Owner.email != null && 
                     ScopeContract.Owner.email.indexOf('@accenture.com') == -1)
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                mail.setToAddresses(sendTo);
                mail.setCcAddresses(sendTo2);
                mail.setReplyTo('alert@ingenico.com');
                mail.setSenderDisplayName('Ingenico Salesforce');
                
                mail.setSubject('Your Contract ' +ScopeContract.ContractNumber + ' expires today');
                
                
                String body = 'Dear '+ScopeContract.Owner.Name+', <br><br>';
                body += 'Your Contract '+ScopeContract.ContractNumber+ ' for ' +ScopeContract.account.name+', expires today.<br><br>';
                body += 'If you are initiating a contract extension, please update Salesforce to reflect this by creating a new Contract record.<br>';
                body += '<br>Otherwise, please change the Status to "Expired". Click on link below to launch the Contract record: ';
                body += '<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+ScopeContract.id+'">'+ScopeContract.ContractNumber+'</a>';
                body += '<br><br>Thanks.';
                mail.setHtmlBody(body);
                mails.add(mail);
            }
        }
        Messaging.sendEmail(mails);
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}