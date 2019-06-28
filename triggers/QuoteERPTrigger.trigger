trigger QuoteERPTrigger on Quote_ERP__C (before insert) {
    //Call the handler to process logic. In future more 
    if (Trigger.isBefore) {
    if (Trigger.isInsert){
         //Call the handler to process logic. In future more methods may be added
         //Create a version of the handler
         QuoteERPHandler.processERPQuotes(trigger.new);
        // QuoteERPHandler.createLeadAndOpt(trigger.new);
    }
    }
}