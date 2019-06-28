@isTest
public class QuoteERPTest {

@isTest 
static void SingleQuoteTest() {
    Integer myint = 5;
    		Quote_ERP__c myQuote= New Quote_ERP__C();
            myQuote.Account_Domain__C = 'SuperAccount';
            myQuote.ERP_PartPK__c = 'AAAAA-';
            myQuote.Quote_Price__c = 50.15;
            myQuote.Xometry_ERP_ID__C = 'AAAAA';
            myQuote.IS_Generic__c = False;
            myQuote.Quote_Email__c ='johndoe@superaccount.com';
            myQuote.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
        Test.startTest();
        Insert myQuote;
        Test.stopTest();
        List<Quote_ERP__C> quotesDomain = [Select Account_Domain__C from Quote_ERP__C where Account_Domain__C='SuperAccount'];
    	
        System.assertEquals('SuperAccount',quotesDomain.get(0).Account_Domain__C);
    }

@isTest
    static void DatabaseError_Exc_Test() {
        List<Quote_ERP__C> quotesList = NEW List<Quote_ERP__C>();
            Quote_ERP__C myQuote = NEW Quote_ERP__C();
            myQuote.Account_Domain__C = 'SuperAccount';
            myQuote.ERP_PartPK__c = 'AAAAA-'+'111';
            myQuote.Quote_Price__c = 50.15;
            myQuote.Xometry_ERP_ID__C = 'AAAAA' +'111';
            myQuote.IS_Generic__c = False;
            myQuote.ERP_Contact_last_Name__c='Doe';
            myQuote.Quote_Email__c = 'johndoe@superaccount.com';
            myQuote.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
            quotesList.add(myQuote);
            Quote_ERP__C myQuote1 = NEW Quote_ERP__C();
            myQuote1.Account_Domain__C = 'SuperAccount';
            myQuote1.ERP_PartPK__c = 'AAAAA-'+'111';
            myQuote1.Quote_Price__c = 50.15;
            myQuote1.Xometry_ERP_ID__C = 'AAAAA' +'112';
            myQuote1.IS_Generic__c = False;
            myQuote1.ERP_Contact_last_Name__c='Does';
            myQuote1.Quote_Email__c = 'johndoe@superaccount.com';
            myQuote1.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
            quotesList.add(myQuote1);
            Test.startTest();
            Insert quotesList;
            Test.stopTest();
            Integer AccountCount = [Select count() from Account];
            Integer ContactCount = [Select count() from Contact];
            System.assertEquals(1,AccountCount);
            System.assertEquals(1,ContactCount);
    }


@isTest
    static void PrexistingAcctContact_Generic () {
        ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeID();
        //Create a generic Contact and Account
        Account a1 = New Account();
        a1.name='johndoe@gmail.com';
        a1.Email_Domain__c='johndoe@gmail.com';
        a1.Account_Owner_Type__C ='BDR';
        a1.RecordTypeID = accountCustomerRecordTypeID;
        Insert a1;
        Contact c1 = New Contact();
        c1.AccountID = a1.ID;
        c1.LastName = 'Doe';
        c1.Primary_Email__C = 'johndoe@gmail.com';
        Insert c1;

            List<Quote_ERP__C> quotesList = NEW List<Quote_ERP__C>();
            Quote_ERP__C myQuote = NEW Quote_ERP__C();
            myQuote.Account_Domain__C = 'johndoe@gmail.com';
            myQuote.ERP_PartPK__c = 'AAAAA-'+'111';
            myQuote.Quote_Price__c = 50.15;
            myQuote.Xometry_ERP_ID__C = 'AAAAA' +'111';
            myQuote.IS_Generic__c = TRUE;
            myQuote.ERP_Contact_last_Name__c='Doe';
            myQuote.Quote_Email__c = 'johndoe@gmail.com';
            myQuote.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
            quotesList.add(myQuote);      
            Quote_ERP__C myQuote2 = NEW Quote_ERP__C();
            myQuote2.Account_Domain__C = 'johndoe@gmail.com';
            myQuote2.ERP_PartPK__c = 'AAAAA-'+'111';
            myQuote2.Quote_Price__c = 50.50;
            myQuote2.Xometry_ERP_ID__C = 'AAAAA' +'112';
            myQuote2.IS_Generic__c = TRUE;
            myQuote2.Quote_Email__c = 'johndoe@gmail.com';
            myQuote2.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00); 
            quotesList.add(myQuote2);  
            Test.startTest();
            Insert quotesList;
            Test.stopTest();
            Integer AccountCount = [Select Count() from Account];
            System.assertEquals(1,AccountCount);
            Integer ContactCount = [Select Count() from Contact];
            System.assertEquals(1,ContactCount);
            Integer QuoteCount = [Select Count() from Quote_ERP__C where ContactID__C != Null];
            System.assertEquals(2,QuoteCount);


    }

//Test multiple quotes with the same information. Should create two generic contacts and accounts

@isTest
    static void MultiQuoteTest_Generic () {
            List<Quote_ERP__C> quotesList = NEW List<Quote_ERP__C>();
            Quote_ERP__C myQuote = NEW Quote_ERP__C();
            myQuote.Account_Domain__C = 'johndoe@gmail.com';
            myQuote.ERP_PartPK__c = 'AAAAA-'+'111';
            myQuote.Quote_Price__c = 50.15;
            myQuote.Xometry_ERP_ID__C = 'AAAAA' +'111';
            myQuote.IS_Generic__c = TRUE;
            myQuote.ERP_Contact_last_Name__c='Doe';
            myQuote.Quote_Email__c = 'johndoe@gmail.com';
            myQuote.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
            quotesList.add(myQuote);      
            Quote_ERP__C myQuote2 = NEW Quote_ERP__C();
            myQuote2.Account_Domain__C = 'johndoe@gmail.com';
            myQuote2.ERP_PartPK__c = 'AAAAA-'+'111';
            myQuote2.Quote_Price__c = 50.50;
            myQuote2.Xometry_ERP_ID__C = 'AAAAA' +'112';
            myQuote2.IS_Generic__c = TRUE;
            myQuote2.Quote_Email__c = 'johndoe@gmail.com';
            myQuote2.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00); 
            quotesList.add(myQuote2);  
            Test.startTest();
            Insert quotesList;
            Test.stopTest();
            Integer AccountCount = [Select Count() from Account];
            System.assertEquals(1,AccountCount);
            Integer ContactCount = [Select Count() from Contact];
            System.assertEquals(1,ContactCount);
            //Confirm two quotes created where contactis populated
            Integer QuoteCount = [Select Count() from Quote_ERP__C where ContactID__C != Null];
            System.assertEquals(2,QuoteCount);
    }

//Test multiple quotes with the same information. Should only create one contact
@isTest
    static void MultiQuoteTest_NonGeneric () {
    List<Quote_ERP__C> quotesList = NEW List<Quote_ERP__C>();
            Quote_ERP__C myQuote = NEW Quote_ERP__C();
            myQuote.Account_Domain__C = 'SuperAccount';
            myQuote.ERP_PartPK__c = 'AAAAA-'+'111';
            myQuote.Quote_Price__c = 50.15;
            myQuote.Xometry_ERP_ID__C = 'AAAAA' +'111';
            myQuote.IS_Generic__c = False;
            myQuote.ERP_Contact_last_Name__c='Doe';
            myQuote.Quote_Email__c = 'johndoe@superaccount.com';
            myQuote.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
            quotesList.add(myQuote);
            //
            Quote_ERP__C myQuote1 = NEW Quote_ERP__C();
            myQuote1.Account_Domain__C = 'SuperAccount';
            myQuote1.ERP_PartPK__c = 'AAAAA-'+'111';
            myQuote1.Quote_Price__c = 50.45;
            myQuote1.Xometry_ERP_ID__C = 'AAAAA' +'112';
            myQuote1.IS_Generic__c = False;
            myQuote1.ERP_Contact_last_Name__c='Doe';
            myQuote1.Quote_Email__c = 'johndoe@superaccount.com';
            myQuote1.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
            quotesList.add(myQuote1);
        
        Test.startTest();
        Insert quotesList;
        Test.stopTest();
        Integer AccountCreated = [Select Count() from Quote_ERP__C where AccountID__c!=Null];
        System.debug('Quotes returned from query is :' + AccountCreated);
        Integer ContactCreated = [Select Count() from Contact];
        System.debug('Contact  returned from query is :' + ContactCreated);
        }
    

    @isTest
         static void BulkQuoteTest_NonGeneric () {
        //RecordType for Customer
        ID customerAccountRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeID();
        //Create 400 hundred quotes
        //Two unique domains
        //one hundred with an existing account
        List<Quote_ERP__C> quotesList = NEW List<Quote_ERP__C>();
        Integer i;
        for(i=0; i<200; i++){
            Quote_ERP__C myQuote = NEW Quote_ERP__C();
            myQuote.Account_Domain__C = 'SuperAccount'+i;
            myQuote.ERP_PartPK__c = 'AAAAA-'+i;
            myQuote.Quote_Price__c = 50.15;
            myQuote.Xometry_ERP_ID__C = 'AAAAA' +i;
            myQuote.IS_Generic__c = False;
            myQuote.Quote_Email__c = 'johndoe@superaccount.com';
            myQuote.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
            quotesList.add(myQuote);

        }
        //Create an Account to test 
        Account existingAccount = New Account();
        existingAccount.name='Pizza Express';
        existingAccount.Email_Domain__c='pizzaexpress.com';
        existingAccount.Generic_Account__c = false;
        existingAccount.RecordTypeID = customerAccountRecordTypeID;
        Insert existingAccount;
        //Create 100 quotes with an existing Account domain
        for (i = 0; i <100; i++){
            Quote_ERP__C myQuote = NEW Quote_ERP__C();
            myQuote.Account_Domain__C = 'pizzaexpress.com';
            myQuote.ERP_PartPK__c = 'AAAAB-'+i;
            myQuote.Quote_Price__c = 50.15;
            myQuote.Xometry_ERP_ID__C = 'AAAAB' +i;
            myQuote.IS_Generic__c = False;
            myQuote.Quote_Email__c='johndoe@pizzaexpress.com';
            myQuote.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
            quotesList.add(myQuote);   
        }
        //Create 100 more quotes without an existing Account
                for (i = 0; i <100; i++){
            Quote_ERP__C myQuote = NEW Quote_ERP__C();
            myQuote.Account_Domain__C = 'partshop'+i;
            myQuote.ERP_PartPK__c = 'AAAAC-'+i;
            myQuote.Quote_Price__c = 50.15;
            myQuote.Xometry_ERP_ID__C = 'AAAAC' +i;
            myQuote.IS_Generic__c = False;
            myQuote.Quote_Email__c='johndoe@partshop.com';
            myQuote.Quote_ERP_Created_Date__c = Datetime.newInstance(2019, 06,14, 11,29,00);
            quotesList.add(myQuote);   
        }

        Test.startTest();
        Insert quotesList;
        Test.stopTest();
        Integer quotesCreated = [Select Count() from Quote_ERP__C where AccountID__c!=Null];
        System.debug('Quotes returned from query is :' + quotesCreated);
        System.assertEquals(400,quotesCreated);
    }
}