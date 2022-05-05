/**
 * CampaignRegCloneController_NWL.cls
 *
 * Controller to clone Campaign Registration and its items
 *
 * @author: Harshal Gajare
 * @version: 1.0
 */
public with sharing class CampaignRegCloneController_NWL{

    // Added an instance varaible for the standard controller
    private ApexPages.StandardController controller {get; set;}
    // Add the instance for the variables being passed by id on the url
    private CampaignRegistration__c cr {get;set;}
    // set the id of the record that is created -- ONLY USED BY THE TEST CLASS
    public ID newRecordId {get;set;}

    private class NoRegistrationItemsException extends Exception{}
    private class NoRegistrationOrderItemsException extends Exception{}

    // Initialize the controller
    public CampaignRegCloneController_NWL(ApexPages.StandardController controller) {
        // Initialize the stanrdard controller
        this.controller = controller;
        // Load the current record
        cr = (CampaignRegistration__c)controller.getRecord();
    }

/**
 * Method called from the VF's action attribute to clone the Campaign Registration
 * Return PageReference
 */
    public PageReference cloneWithItems(){
        // Setup the save point for rollback
        Savepoint sp = Database.setSavepoint();
        CampaignRegistration__c newCr;

        try{
            //Copy the Campaign Registration - ONLY INCLUDE THE FROMIELDS YOU WANT TO CLONE
            cr = [SELECT Id, Campaign__c, Contact__c, Country__c, Campaign__r.Type, BankAccountNumber__c, BICCode__c,
                        IBANCode__c, SortCode__c,Campaign__r.RecordType.Name
                    FROM CampaignRegistration__c
                    WHERE Id = :cr.id];
            newCr = cr.clone(false);
            newCr.ParentCampaignRegistration__c = cr.Id;
            insert newCr;

            // Set the id of the new Campaign Registration created for testing
            newRecordId = newCr.id;

            // Copy over the Campaign Registration items - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
            List<CampaignRegistrationItems__c> criList = new List<CampaignRegistrationItems__c>();
            for (CampaignRegistrationItems__c cri : [SELECT Id, CampaignProduct__c, CashbackAmount__c, DateOfPurchase__c,
                                                            DealerName__c, PricePaidPerUnit__c, Quantity__c, SerialNumber__c,
                                                            WebCashbackAmmount__c
                                                        FROM CampaignRegistrationItems__c
                                                        WHERE CampaignRegistration__c = :cr.id]){
                CampaignRegistrationItems__c newCri = cri.clone(false);
                newCri.CampaignRegistration__c = newCr.id;
                criList.add(newCri);
            }
            if( !criList.isEmpty() ){
                insert criList;
            }else{
                throw new NoRegistrationItemsException('Campaign cannot be cloned. No registration items found');
            }

            // Check if campaign
            if( cr.Campaign__r.RecordType.Name == 'Fulfillment'){
                // Copy over the Campaign Registration items - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
                List<CampaignRegistrationOrderItem__c> croiList = new List<CampaignRegistrationOrderItem__c>();
                for (CampaignRegistrationOrderItem__c croi : [SELECT Id, CampaignOrderProduct__c, Quantity__c
                                                                FROM CampaignRegistrationOrderItem__c
                                                                WHERE CampaignRegistration__c = :cr.id]){
                    CampaignRegistrationOrderItem__c newCroi = croi.clone(false);
                    newCroi.CampaignRegistration__c = newCr.id;
                    croiList.add(newCroi);
                }
                if( !croiList.isEmpty() ){
                    insert croiList;
                }else{
                    throw new NoRegistrationOrderItemsException('Campaign cannot be cloned. No registration order items found');
                }
            }
            // Obtain the attachment of the current campaign Registration Record.
            List<Attachment> crAttList = new List<Attachment>(); 
            for (Attachment crAtt : [SELECT Body, Bodylength, ContentType, Description, Id, Name
                                        FROM Attachment 
                                        WHERE ParentId = :cr.id
                                          AND IsDeleted = false]) {
                Attachment newcrAtt = crAtt.clone(false);
                newCrAtt.parentId = newCr.Id;
                crAttList.add(newCrAtt);   
            }
            if( !crAttList.isEmpty() ) {
                insert crAttList;
            }
        }catch(Exception ex){
            // Roll everything back in case of error
            Database.rollback(sp);
            ApexPages.addMessages(ex);
            return null;
        }
        return new PageReference('/'+newCr.id+'/e?retURL=%2F'+newCr.id);
    }
}
//*********************************************** END OF CLASS *******************************************************//