/*
Summary:This handler contains business logic for Quote_ERP__C trigger
*/
public with sharing class QuoteERPHandler {

public static void processERPQuotes(List<Quote_ERP__C> newQuotesERPList){
    // Take quotes and seperate the list into two generic lists
    // All or None is set to false in Database methods to allow for correct records to be inserted
    //Get IDs for record types
    ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeID();
    ID opportunityStdRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Xometry Standard Sales').getRecordTypeID();

    Set<ID> createdContactIDs = NEW SET<ID>();
    Set<ID> createdAccountIDs = NEW SET<ID>();
    List<Quote_ERP__C> NonGenericQuotesList = NEW List<Quote_ERP__C>();
    List<Quote_ERP__C> GenericQuotesList = NEW List<Quote_ERP__C>();

    for (Quote_ERP__C q : newQuotesERPList  ){
        if(q.IS_Generic__C == TRUE){
           GenericQuotesList.add(q);
        }
        else{
           NonGenericQuotesList.add(q);  
        }
    }

    System.debug('The size of the nongeneric list is ' + NonGenericQuotesList.size());
//1st set of logic for NonGenerics
    // Check if Account exists with domain otherwise create account
    // More then one quote can occur 
    Set<String> NonGenericDomainSet = NEW Set<String>();
    for (Quote_ERP__C q : NonGenericQuotesList){
        NonGenericDomainSet.add(q.Account_Domain__c);
    }
    List<Account> existingAccountLists = [Select ID, Email_Domain__c from Account where Email_Domain__c in :NonGenericDomainSet
    and parentid=Null];
    
    System.debug('The size of the existingAccount list is ' + existingAccountLists.size());

    Map<String,Account> domainNewAccountMap = New Map<String,Account>();
    if( !existingAccountLists.isEmpty()){
    for (account a : existingAccountLists){
        domainNewAccountMap.put(a.Email_Domain__c,a);
    }
    }
    // If Domain is not in Map then get add to accounts
    Set<Account> AccountCreateSet = New Set<Account>();
    for(Quote_ERP__C q : NonGenericQuotesList){
        if( !domainNewAccountMap.containsKey(q.Account_Domain__c)){
            System.debug('We should be inside now with a domain of' + q.Account_Domain__c);
            Account newAccount = New Account();
            newAccount.name = q.Account_Domain__c;
            newAccount.Email_Domain__c= q.Account_Domain__c;
            //New Automated Accounts Should be assigned to BDRs
            //Then switched over to AM
            newAccount.Account_Owner_Type__c='BDR';
            newAccount.RecordtypeID= accountCustomerRecordTypeID;
            AccountCreateSet.add(newAccount);
        }
    }

    List<Account> AccountCreateList = New List<Account>(AccountCreateSet);
    // Create Accounts that don't exist in the system
    System.debug('About to create the Accounts');
    System.debug('The accounts to be inserted are ' + AccountCreateList );
    Database.SaveResult[] srList = Database.insert(AccountCreateList, false);
    List<Audit_Trail_Error__c> myAuditErrorList = New List<Audit_Trail_Error__c>();
   //Check Results of Insert -- Create error object to write errors to
   for (Database.SaveResult sr: srList) {
       if (sr.isSuccess()){
           //Operation was successful
           createdAccountIDs.add(sr.getID());
           System.debug('Succesfully Inserted Accounts Records' + sr.getID());
       }
       else {
           //Log errors
           for(Database.Error err : sr.getErrors()) {
               System.debug('The following error has occured.');
               System.debug(err.getStatusCode() + ' : ' + err.getMessage());
               System.debug('Account fields that affected this error: ' + err.getFields());
               Audit_Trail_Error__c myAuditError = New Audit_Trail_Error__c();
               myAuditError.Module__c = 'QuoteERPHandler';
               myAuditError.Dev_Audit_Notes__c = 'Non Generic Account Inserts';
               myAuditError.StatusCode__c = err.getStatusCode().name();
               myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
               myAuditError.errorFields__c = String.join(err.getFields(),' ').abbreviate(250);
               myAuditErrorList.add(myAuditError);
           }
       }
   }
//Update quotes with accountIDs

List<Account> allQuoteAccountList = [Select ID, Email_Domain__c, Account_Owner_Type__c from Account where Email_Domain__c in :NonGenericDomainSet
    and parentid=Null];

System.debug('We should now have all the accounts created for the non generic quotes');
System.debug('The size of the non geneirc accounts is ' + allQuoteAccountList.size());
Map<String,Account> domainAccountMap = New Map<String,Account>();
if(!allQuoteAccountList.isEmpty()){

for (account a : allQuoteAccountList){
    domainAccountMap.put(a.Email_Domain__c,a);
}}
//Get AccountIds and Provide them to quotes
for (Quote_ERP__C q: NonGenericQuotesList){
    if(domainAccountMap.containsKey(q.Account_Domain__c)){
       q.AccountID__c = domainAccountMap.get(q.Account_Domain__c).ID;
    }
}



//Move on to NonGeneric Contacts

SET<String> nonGenericQuoteEmailSet = NEW SET<String>();
for(Quote_ERP__C q : NonGenericQuotesList){
    nonGenericQuoteEmailSet.add(q.Quote_Email__c);
}

//Check if Contact exists based on email and Lastname
List<Contact> nonGenericContactsExisting = New List<Contact>();
nonGenericContactsExisting = [Select Last_Name__c, Primary_Email__C from contact where Primary_Email__C in :nonGenericQuoteEmailSet];

//Map the Contacts to determine where a contact does not exist
Map<String,Contact> emailContactMap = New Map<String,Contact>();
if(!nonGenericContactsExisting.isEmpty()){
    for (Contact c : nonGenericContactsExisting){
        emailContactMap.put(c.Primary_Email__C,c);
    }
}

//Check if the contact exists. If not make a contact
Set<Contact> newContactsSets = NEW Set<Contact>();
for (Quote_ERP__C q: NonGenericQuotesList){
    if( !emailContactMap.containsKey(q.Quote_Email__c) && !String.isBlank(q.ERP_Contact_Last_Name__C) ){
        Contact c = NEW Contact();
        c.AccountID = q.AccountID__C;
        c.LastName=q.ERP_Contact_Last_Name__C;
        c.FirstName=q.ERP_Contact_First_Name__C;
        c.Primary_Email__C = q.Quote_Email__C;
        c.Xometry_ERP_Contact_ID__c = q.ERP_Contact__C;
        newContactsSets.add(c);
    }
}
//Convert the Set to List
List<Contact> newContactsList = new List<Contact>(newContactsSets);
    // Create Contacts that don't exist in the system
    System.debug('About to create the Contacts');
    System.debug('The contacts to be inserted are ' + newContactsList );
    srList = Database.insert(newContactsList, false);

   //Check Results of Insert -- Create error object to write errors to
   for (Database.SaveResult sr: srList) {
       if (sr.isSuccess()){
           //Operation was successful
           createdContactIDs.add(sr.getID());
           System.debug('Succesfully Inserted Contact Records' + sr.getID());
       }
       else {
           //Log errors
           for(Database.Error err : sr.getErrors()) {
               System.debug('The following error has occured.');
               System.debug(err.getStatusCode() + ' : ' + err.getMessage());
               System.debug('Contact fields that affected this error: ' + err.getFields());
               Audit_Trail_Error__c myAuditError = New Audit_Trail_Error__c();
               myAuditError.Module__c = 'QuoteERPHandler';
               myAuditError.Dev_Audit_Notes__c = 'Non Generic Account Inserts';
               myAuditError.StatusCode__c = err.getStatusCode().name();
               myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
               myAuditError.errorFields__c = String.join(err.getFields(),' ').abbreviate(250);
               myAuditErrorList.add(myAuditError);
           }
       }
   }

//Update quotes with ContactIDs
List<Contact> allnonGenericContactQList = [Select Last_Name__c, Primary_Email__C from contact where Primary_Email__C in :nonGenericQuoteEmailSet];

System.debug('We should now have all the contacts created for the non generic quotes');
System.debug('The size of the non geneirc contacts is ' + allnonGenericContactQList.size());

Map<String,Contact> emailAllNonGenericContactMap = NEW MAP<string,Contact>();
if(!allnonGenericContactQList.isEmpty()){
    for (contact c : allnonGenericContactQList){
        emailAllNonGenericContactMap.put(c.Primary_Email__C,c);
    }
}
//Update quotes
for ( Quote_ERP__C q: NonGenericQuotesList){
    if(emailAllNonGenericContactMap.containsKey(q.Quote_Email__C)) {
        q.ContactID__C = emailAllNonGenericContactMap.get(q.Quote_Email__C).ID;
    }
}

//Process Logic for the generics
//For Generics use email to create account 
System.debug('The size of the generic list is ' + GenericQuotesList.size());

//Generics are controlled by Contacts that rollup to Accounts. First get AccountIDs based on the Contact
//Check if Account exists with generic email. Use email as the domain/Email
//Otherwise do nothing create a quote without a contact/email
//IF generic's contact does not exist then simply create a quote 
Set<String> genericQuoteEmailSet = NEW Set<String>();


for(Quote_ERP__C q: GenericQuotesList){
    genericQuoteEmailSet.add(q.Quote_Email__C);
}

List<Contact> genericExistingContactingList = NEW List<Contact>();
genericExistingContactingList = [Select Id,AccountID, LastName, Primary_Email__C from Contact where Primary_Email__C in :genericQuoteEmailSet ];
List<Account> genericExistingAccountList = NEW List<Account>();
genericExistingAccountList = [Select ID,Name from Account where Name in :genericQuoteEmailSet ];

//Map existing generic Accounts
map<String,Account> genericAccountMap = NEW map<String,Account>();
if(!genericExistingAccountList.isEmpty() ){
for (Account a: genericExistingAccountList){
    genericAccountMap.put(a.Name,a);
}
}

map<String,Contact> genericContactMap = NEW map<String,Contact>();

//System.debug('The contacts returned from the query are :: ');
//System.debug(genericExistingContactingList);
if(!genericExistingContactingList.isEmpty()){
for (contact c: genericExistingContactingList){
    //System.debug('Inside the Contact Map Put ' + c.Primary_Email__C);
    genericContactMap.put(c.Primary_Email__C,c);
} }


List<Account> genericNewAccountList = NEW List<Account>();
Set<Account> genericNewAccountSet = NEW Set<Account>();

//Check if there is either a Contact with matching email that has AccountId or there is a generic email that matches the email
//For Generics Contacts live at the top.
for(Quote_ERP__C q: GenericQuotesList){
    if(!genericContactMap.containsKey(q.Quote_Email__C) && !genericAccountMap.containsKey(q.Quote_Email__C)){
            // New Account.
        System.debug('Inside the generic New Account List');
        Account newAccount = NEW Account();
        newAccount.name = q.Quote_Email__C;
        newAccount.Email_Domain__c= q.Account_Domain__c;
            //New Automated Accounts Should be assigned to BDRs
            //Then switched over to AM
        newAccount.Account_Owner_Type__c='BDR';
        newAccount.RecordtypeID= accountCustomerRecordTypeID;
        genericNewAccountSet.add(newAccount);
    
    }    
}

//Insert the New Accounts
genericNewAccountList.addAll(genericNewAccountSet);

   // Create Accounts that don't exist in the system
    System.debug('About to create the Generic Accounts');
    System.debug('The Generic accounts to be inserted are ' + genericNewAccountList );
     srList = Database.insert(genericNewAccountList, false);
   //Check Results of Insert -- Create error object to write errors to
   for (Database.SaveResult sr: srList) {
       if (sr.isSuccess()){
           //Operation was successful
           createdAccountIDs.add(sr.getID());
           System.debug('Succesfully Inserted Accounts Records' + sr.getID());
       }
       else {
           //Log errors
           for(Database.Error err : sr.getErrors()) {
               System.debug('The following error has occured.');
               System.debug(err.getStatusCode() + ' : ' + err.getMessage());
               System.debug('Account fields that affected this error: ' + err.getFields());
               Audit_Trail_Error__c myAuditError = New Audit_Trail_Error__c();
               myAuditError.Module__c = 'QuoteERPHandler';
               myAuditError.Dev_Audit_Notes__c = 'Non Generic Account Inserts';
               myAuditError.StatusCode__c = err.getStatusCode().name();
               myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
               myAuditError.errorFields__c = String.join(err.getFields(),' ').abbreviate(250);
               myAuditErrorList.add(myAuditError);
           }
       }
   }

genericExistingAccountList = [Select ID,Name from Account where Name in :genericQuoteEmailSet ];
MAP<String,Account> genericAllAccountMap = NEW MAP<String,Account>();
for (Account a: genericNewAccountList){
    genericAllAccountMap.put(a.Name,a);
}

//Check if there is either a Contact with matching email that has AccountId or there is a generic email that matches the email
//For Generics Contacts live at the top.
for(Quote_ERP__C q: GenericQuotesList){
    if(genericContactMap.containsKey(q.Quote_Email__C)) {
        // Use Contact's Account
        q.AccountID__C=genericContactMap.get(q.Quote_Email__C).AccountID;
    }
    else if(genericAllAccountMap.containsKey(q.Quote_Email__C)){
        //Use Account
        q.AccountID__C= genericAllAccountMap.get(q.Quote_Email__C).ID;
    }
}

//



List<Contact> genericNewContactList = NEW List<Contact>();
Set<Contact> genericNewContactSet = NEW Set<Contact>();

//If Generic Contact is missing create a generic Contact
//Use the accountID on the Contact if it exists

for (Quote_ERP__C q: GenericQuotesList){
    if(!genericContactMap.containsKey(q.Quote_Email__C)){
        System.debug('New Contact Time');
        Contact newContact = NEW Contact();
        newContact.FirstName=q.ERP_Contact_First_Name__C;
        newContact.Primary_Email__C = q.Quote_Email__C;
        newContact.Xometry_ERP_Contact_ID__c = q.ERP_Contact__C;
        if(!String.isblank(q.ERP_Contact_Last_Name__C)){
           newContact.LastName = q.ERP_Contact_Last_Name__C ;
        }
        else {newContact.LastName = q.Quote_Email__c;}
       newContact.AccountID = q.AccountID__C; 
       genericNewContactSet.add(newContact);
    }

}

genericNewContactList.addAll(genericNewContactSet);
//Insert the Contacts
 // Create Contacts that don't exist in the system
    System.debug('About to create the Generic Contacts');
    System.debug('The contacts to be inserted are ' + genericNewContactList );
    srList = Database.insert(genericNewContactList, false);

   //Check Results of Insert -- Create error object to write errors to
   for (Database.SaveResult sr: srList) {
       if (sr.isSuccess()){
           //Operation was successful
           createdContactIDs.add(sr.getID());
           System.debug('Succesfully Inserted Contact Records' + sr.getID());
       }
       else {
           //Log errors
           for(Database.Error err : sr.getErrors()) {
               System.debug('The following error has occured.');
               System.debug(err.getStatusCode() + ' : ' + err.getMessage());
               System.debug('Contact fields that affected this error: ' + err.getFields());
               Audit_Trail_Error__c myAuditError = New Audit_Trail_Error__c();
               myAuditError.Module__c = 'QuoteERPHandler';
               myAuditError.Dev_Audit_Notes__c = 'Generic Contact Inserts';
               myAuditError.StatusCode__c = err.getStatusCode().name();
               myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
               myAuditError.errorFields__c = String.join(err.getFields(),' ').abbreviate(250);
               myAuditErrorList.add(myAuditError);
           }
       }
   }
//Update the Contacts in the GenericQuotes
List<Contact> allGenericContactsQList = [Select ID, Primary_Email__C from Contact where Primary_Email__C in :genericQuoteEmailSet];

System.debug('We should now have all the contacts created for the non generic quotes');
System.debug('The size of the non geneirc contacts is ' + allGenericContactsQList.size());
Map<String,Contact> emailAllGenericContactMap = New Map<String,Contact>();
if(!allGenericContactsQList.isEmpty()){
    for (Contact c: allGenericContactsQList){
        emailAllGenericContactMap.put(c.Primary_Email__C,c);
    }
}

//Update quotes
for( Quote_ERP__C q: GenericQuotesList){
    if(emailAllGenericContactMap.containsKey(q.Quote_Email__C)){
        q.ContactID__C= emailAllGenericContactMap.get(q.Quote_Email__C).ID;
    }
}

//Insert any erros that occured

//handle the logic for creating leads and opts
//System.debug('Checking that the account and contact is passed in');
//System.debug(newQuotesERPList);
System.debug('Start of the Opp Section : ' + newQuotesERPList.size());

Set<ID> quoteAccountIDSet = New Set<ID>();
Set<ID> quoteContactIDSet = New Set<ID>();
Set<String> quoteEmailSet = New Set<String>();
Set<String> quoteOppXomQuoteSet = New Set<String>();
Set<String> quoteLeadXomQuoteSet = New Set<String>();
List<Quote_ERP__C> oppsToCreatePreSup = New List<Quote_ERP__C>();
List<Quote_ERP__C> leadsToCreate = New List<Quote_ERP__C>();
for (quote_erp__c q : newQuotesERPList){
        quoteAccountIDSet.add(q.AccountID__C);
        quoteContactIDSet.add(q.ContactID__C);
        quoteEmailSet.add(q.Quote_Email__C);
}



List<Account> allAccountsList = [Select ID, Name, Account_Owner_Type__c, OwnerID, Email_Domain__c from Account where ID in :quoteAccountIDSet];
Map<ID,Account> allAccountsMap = NEW Map<ID,Account>(allAccountsList);

List<Contact> allContactsList = [Select ID,LastName,Primary_Email__C, Suppress_Opps_and_Leads_Flag__c from Contact where ID in :quoteContactIDSet];
Map<ID,Contact> allContactsMap = New Map<ID,Contact>(allContactsList);

List<Lead> allLeadsList = [Select ID,LastName,Company,Email from Lead where Email in : quoteEmailSet];

//ERP_PartPK
List<Quote_ERP__C> quoteTypeBDRList = New List<Quote_ERP__C>();
List<Quote_ERP__C> quoteTypeAMList = New List<Quote_ERP__C>();
String laccounttype;
//Sort into BDR or AM accounttype
for (Quote_ERP__C q: newQuotesERPList){
    if(allAccountsMap.containsKey(q.AccountID__C)){
        laccounttype=allAccountsMap.get(q.AccountID__C).Account_Owner_Type__c;
        if(laccounttype=='AM'){
            quoteTypeAMList.add(q);
        }
        else if (laccounttype=='BDR'){
            quoteTypeBDRList.add(q);
        }
    } 
}

//Sort the BDRs into generic and non generic 
    //List<Quote_ERP__C> NonGenericBDRQuotesList = NEW List<Quote_ERP__C>();
    //List<Quote_ERP__C> GenericBDRQuotesList = NEW List<Quote_ERP__C>();

    for (Quote_ERP__C q : quoteTypeBDRList  ){
        if(q.IS_Generic__C == TRUE){
        //If Generic and BDR check if Contact exists
        //If no contact assign to leadsToCreate
        //If yes assign to opportunity list oppsToCreatePreSup
           if(allContactsMap.containsKey(q.ContactID__C)){
              oppsToCreatePreSup.add(q);
           }
           else{
               leadsToCreate.add(q);
           }
        }
        else{
           oppsToCreatePreSup.add(q);  
        }
    }

// For AM Check if Contact is New and Hits threshold value
for(Quote_ERP__C q: quoteTypeAMList){
If(createdContactIDs.contains(q.ContactID__C) || q.Quote_Price__C>5000 ){
    oppsToCreatePreSup.add(q);
}
}

List<Quote_ERP__C> oppsToCreate = NEW List<Quote_ERP__C>();
Set<String> existingOPPwithPartSet = NEW SET<STRING>();
//Check For Contact Flagged for suppression
for(Quote_ERP__C q : oppsToCreatePreSup){
        if(allContactsMap.containsKey(q.ContactID__C)){
        if(allContactsMap.get(q.ContactID__C).Suppress_OPPS_AND_LEADS_FLAG__C == FALSE){
            oppsTOCreate.add(q);
            existingOPPwithPartSet.add(q.ERP_PartPK__C);
        }
        }
}



//Does Opp Exist with Part Combo
List<Quote_ERP__C> quoteOppNoPartList = NEW List<Quote_ERP__C>();
List<Quote_ERP__C> quoteOppHasPartList = NEW List<Quote_ERP__C>();

//In order to not fail with duplicates get the last opportunity created with the part combo
List<Quote_ERP__C> allOpportunitiesList = [Select Name, ID, ERP_PartPK__c, Quote_Email__C, OpportunityID__C, OpportunityID__R.StageName, OpportunityID__R.Createddate from Quote_ERP__C where OpportunityID__C!=Null
and ERP_PartPK__C in : existingOPPwithPartSet order by ERP_PartPK__c, Createddate desc];
Map<String,Quote_ERP__C> partQuoteMap = NEW Map<String,Quote_ERP__C>();
if(!allOpportunitiesList.isEmpty()){
for(Quote_ERP__C q: allOpportunitiesList){
    if(!partQuoteMap.containsKey(q.ERP_PartPK__C))
    partQuoteMap.put(q.ERP_PartPK__C,q);
}
}

for (Quote_ERP__C q: oppsTOCreate){
    if(partQuoteMap.containsKey(q.ERP_PartPK__C)){
        quoteOppHasPartList.add(q);
    }
    else{
        quoteOppNoPartList.add(q);
    }

}

List<Opportunity> oppsWithPartUpdateList = New List<Opportunity>();
//For existing Opportunities Assign the OpportunityID to the Quote and then Update Opportunity
for(Quote_ERP__C q: quoteOppHasPartList){
string lAmount;
ID lOPPID = partQuoteMap.get(q.ERP_PartPK__C).OpportunityID__C;
q.OpportunityID__C = lOPPID;
Opportunity Opp = New Opportunity();
//Check if Opportunity was Stagename Closed Lost
if(partQuoteMap.get(q.ERP_PartPK__C).OpportunityID__R.StageName=='Closed Lost'){
    Opp.ID = lOPPID;
    Opp.Amount = q.Quote_Price__c;
    Opp.Stagename = 'System Reopened';
    Opp.System_Reopened_Flag__c =TRUE;
}
else {
Opp.ID = lOPPID;
Opp.Amount = q.Quote_Price__C;

}
//Add Opp to list to be updated
oppsWithPartUpdateList.add(Opp);
}

SET<ID> updateOppIDSet = NEW SET<ID>();
//Update the opportunities
   System.debug('About to Update the Opps');
    System.debug('The opportunities to be update are ' + genericNewContactList );
    srList = Database.update(oppsWithPartUpdateList, false);

   //Check Results of Insert -- Create error object to write errors to
   for (Database.SaveResult sr: srList) {
       if (sr.isSuccess()){
           //Operation was successful
           updateOppIDSet.add(sr.getID());
           System.debug('Succesfully Updated Opportunity Contact Records' + sr.getID());
       }
       else {
           //Log errors
           for(Database.Error err : sr.getErrors()) {
               System.debug('The following error has occured.');
               System.debug(err.getStatusCode() + ' : ' + err.getMessage());
               System.debug('Opportunity fields that affected this error: ' + err.getFields());
               Audit_Trail_Error__c myAuditError = New Audit_Trail_Error__c();
               myAuditError.Module__c = 'QuoteERPHandler';
               myAuditError.Dev_Audit_Notes__c = 'Opportunity Updates';
               myAuditError.StatusCode__c = err.getStatusCode().name();
               myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
               myAuditError.errorFields__c = String.join(err.getFields(),' ').abbreviate(250);
               myAuditErrorList.add(myAuditError);
           }
       }
   }

List<Opportunity> oppsWithNoPartInsertList = New List<Opportunity>();
Datetime dtNow = datetime.now();
Datetime oppCloseDatetime = dtNow + 14;
Date oppCloseDate = dtNow.date();
String nowYYYYMMDD = dtNow.format('YYYYMMdd');
//Opp Name use quote and other standard
//AccountID
//Stage Bant Needed
// Amount based on Price
//Close Date two weeks from today
//ContactID
//Create new Opportunities
for (Quote_ERP__C q: quoteOppNoPartList){
     Opportunity Opp = NEW Opportunity();
     Opp.AccountID = q.AccountID__C;
     // Check if the account was new: createdAccountIDs if so assign round robin flag
     if(createdAccountIDs.contains(q.AccountID__C)){
         Opp.IS_RR_Eligible_Flag__c = TRUE;
     }
     Opp.StageName = 'Bant Needed';
     Opp.Name = 'OPP-' + q.Xometry_ERP_ID__C + '-' +nowYYYYMMDD;
     Opp.Amount = q.Quote_Price__C;
     Opp.CloseDate = oppCloseDate;
     Opp.OwnerID = allAccountsMap.get(q.AccountID__C).OwnerID;
     Opp.Quote_ERP_XOM_CREATE_ID__c = q.Xometry_ERP_ID__c;
     oppsWithNoPartInsertList.add(Opp);
}


SET<ID> insertOppIDSet = NEW SET<ID>();
//Insert the opportunities
   System.debug('About to Update the Opps');
    System.debug('The opportunities to be inserted are ' + oppsWithNoPartInsertList );
    srList = Database.insert(oppsWithNoPartInsertList, false);

   //Check Results of Insert -- Create error object to write errors to
   for (Database.SaveResult sr: srList) {
       if (sr.isSuccess()){
           //Operation was successful
           insertOppIDSet.add(sr.getID());
           System.debug('Succesfully oppsWithNoPartInsertList Opportunity Contact Records' + sr.getID());
       }
       else {
           //Log errors
           for(Database.Error err : sr.getErrors()) {
               System.debug('The following error has occured.');
               System.debug(err.getStatusCode() + ' : ' + err.getMessage());
               System.debug('Opportunity fields that affected this error: ' + err.getFields());
               Audit_Trail_Error__c myAuditError = New Audit_Trail_Error__c();
               myAuditError.Module__c = 'QuoteERPHandler';
               myAuditError.Dev_Audit_Notes__c = 'Opportunity Inserts';
               myAuditError.StatusCode__c = err.getStatusCode().name();
               myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
               myAuditError.errorFields__c = String.join(err.getFields(),' ').abbreviate(250);
               myAuditErrorList.add(myAuditError);
           }
       }
   }

//Assign OpportunityIDs to Quotes
List<OpportunityContactRole> newOppContactRoleList = NEW List<OpportunityContactRole>();
Map<String,Opportunity> newOppsCreatedMap = New Map<String,Opportunity>();
if (!oppsWithNoPartInsertList.isEmpty()){
for(Opportunity opp : oppsWithNoPartInsertList ){
    newOppsCreatedMap.put(opp.Quote_ERP_XOM_CREATE_ID__c,opp);
}
}
for (Quote_ERP__C q: quoteOppNoPartList){
    if(newOppsCreatedMap.containsKey(q.Xometry_ERP_ID__C)){
        ID lOPPID = newOppsCreatedMap.get(q.Xometry_ERP_ID__C).ID;
        q.OpportunityID__C = lOPPID;
        //Update the Junction Object Create the Decision Maker as the role and set primary
        OpportunityContactRole newOppCRole = NEW OpportunityContactRole();
        newOppCRole.ContactID = q.ContactID__C;
        newOppCRole.IsPrimary = TRUE;
        newOppCRole.OpportunityID= lOPPID;
        newOppCRole.Role = 'Decision Maker';
        newOppContactRoleList.add(newOppCRole);
    }
}

//Insert the junction object
SET<ID> insertOppContactRoleIDSet = NEW SET<ID>();
//Insert the opportunities
   System.debug('About to Insert the OppsContactRoles');
    System.debug('The opportunitiescontact roles to be inserted are ' + newOppContactRoleList );
    srList = Database.insert(newOppContactRoleList, false);

   //Check Results of Insert -- Create error object to write errors to
   for (Database.SaveResult sr: srList) {
       if (sr.isSuccess()){
           //Operation was successful
           insertOppContactRoleIDSet.add(sr.getID());
           System.debug('Succesfully Inserted newOppContactRoleList Opportunity Contact Records' + sr.getID());
       }
       else {
           //Log errors
           for(Database.Error err : sr.getErrors()) {
               System.debug('The following error has occured.');
               System.debug(err.getStatusCode() + ' : ' + err.getMessage());
               System.debug('OpportunityContact Role  fields that affected this error: ' + err.getFields());
               Audit_Trail_Error__c myAuditError = New Audit_Trail_Error__c();
               myAuditError.Module__c = 'QuoteERPHandler';
               myAuditError.Dev_Audit_Notes__c = 'OpportunityContact Role Inserts';
               myAuditError.StatusCode__c = err.getStatusCode().name();
               myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
               myAuditError.errorFields__c = String.join(err.getFields(),' ').abbreviate(250);
               myAuditErrorList.add(myAuditError);
           }
       }
   }

//If the AuditList is not empty then insert the audit list
if (!myAuditErrorList.isEmpty()){
Insert myAuditErrorList;
}

}
}