/**
* File........... : ConsumerServiceButtonsController_NWL
* Created by..... : Jnanesh Avaradi
* Created Date... : 19-July-2021
* Description.... : Controller class for all the consumer custom lightning buttons
*
*               ************* Change Log *************
* JIRA No.        Modified By           Modified Date       Reason
* SFDC-10088      Jnanesh Avaradi       19-July-2021        New class*              
*
*/
public class ConsumerServiceButtonsController_NWL {
    @AuraEnabled
    public static String sendPaymentEmail( String caseId, String caseStatus ){
        String msg;
        Id paymentAccId;
        if( caseStatus == 'Waiting For Payment' ){
            List<Case_Order__c> coList = [SELECT Id, Case__c, Case__r.ContactId, Order__c, Order__r.DeliveryBlockKey__c,
                                          Order__r.RecordType.Name
                                          FROM Case_Order__c
                                          WHERE Case__c = :caseId];
            if(coList.size() == 0){               
                throw new AuraHandledException('No order found. Please check case orders');
            }else if(coList.size() > 1){                
                throw new AuraHandledException('Multiple orders found. Please check case orders');
            }else{
                if( coList[0].Order__r.RecordType.Name == 'OMS Order' ){
                    // Check if Payment Account record exists for this order with no errors
                    List<PaymentAccount__c> paList = [SELECT Id, Token__c, Name
                                                      FROM PaymentAccount__c
                                                      WHERE OrderIndex__c =: coList[0].Order__c
                                                      AND OrderIndex__r.RecordType.Name = 'OMS Order'
                                                      AND Inactive__c = false];
                    // If no record exists , create a new record.
                    if(paList.isEmpty()){
                        try{
                            // Create a Payment Account record
                            PaymentAccount__c pa = new PaymentAccount__c();
                            pa.Case__c       = coList[0].Case__c;
                            pa.OrderIndex__c = coList[0].Order__c;
                            pa.Contact__c    = coList[0].Case__r.ContactId;
                            insert pa;
                            paymentAccId = pa.Id;
                        }catch(Exception ex){                           
                            throw new AuraHandledException(ex.getMessage());
                        }
                    }else{
                        // If a record exists checked if consumer has already submitted the payment.
                        // If yes then issue a erorr.
                        if( String.isNotBlank(paList[0].Token__c) ){
                            msg = 'Counsumer has already submitted the payment information. Payment Account : ' + paList[0].Name;                           
                            throw new AuraHandledException(msg);
                        }else{
                            paymentAccId = paList[0].Id;
                        }
                    }
                    
                    try{
                        // Create a Payment Account record
                        EmailNotification__c en = new EmailNotification__c();
                        en.RecordTypeId      = Schema.SObjectType.EmailNotification__c.RecordTypeInfosByName.get('Consumer Cybersource Email').RecordTypeId;
                        en.Case__c           = coList[0].Case__c;
                        en.OrderIndex__c     = coList[0].Order__c;
                        en.EmailContact__c   = coList[0].Case__r.ContactId;
                        en.PaymentAccount__c = paymentAccId;
                        insert en;
                        msg = 'Email sent successfully';
                    }catch(Exception ex){                        
                        throw new AuraHandledException(ex.getMessage());
                    }
                }else{
                    if(coList[0].Order__r.DeliveryBlockKey__c == 'C2'){
                        // Check if Payment Account record exists for this order with no errors
                        List<PaymentAccount__c> paList = [SELECT Id, Token__c, Name FROM PaymentAccount__c
                                                          WHERE OrderIndex__c =: coList[0].Order__c AND Inactive__c = false];
                        // If no record exists , create a new record.
                        if(paList.isEmpty()){
                            try{
                                // Create a Payment Account record
                                PaymentAccount__c pa = new PaymentAccount__c();
                                pa.Case__c       = coList[0].Case__c;
                                pa.OrderIndex__c = coList[0].Order__c;
                                pa.Contact__c    = coList[0].Case__r.ContactId;
                                insert pa;
                                paymentAccId = pa.Id;
                            }catch(Exception ex){                               
                                throw new AuraHandledException(ex.getMessage());
                            }
                        }else{
                            // If a record exists checked if consumer has already submitted the payment.
                            // If yes then issue a erorr.
                            if( String.isNotBlank(paList[0].Token__c) ){
                                msg = 'Counsumer has already submitted the payment information. Payment Account : '+paList[0].Name ;                              
                                throw new AuraHandledException(msg);
                            }else{
                                paymentAccId = paList[0].Id;
                            }
                        }
                        
                        try{
                            // Create a Payment Account record
                            EmailNotification__c en = new EmailNotification__c();
                            en.RecordTypeId      = Schema.SObjectType.EmailNotification__c.RecordTypeInfosByName.get('Consumer Payment Email').RecordTypeId;
                            en.Case__c           = coList[0].Case__c;
                            en.OrderIndex__c     = coList[0].Order__c;
                            en.EmailContact__c   = coList[0].Case__r.ContactId;
                            en.PaymentAccount__c = paymentAccId;
                            insert en;
                            msg = 'Email sent successfully';
                        }catch(Exception ex){                           
                            throw new AuraHandledException(ex.getMessage());
                        }
                    }else{
                        msg = 'Incorrect order delivery block : ' + coList[0].Order__r.DeliveryBlockKey__c + '. Block should be C2.';
                        throw new AuraHandledException(msg);
                    }
                }
            }
        }else{          
            throw new AuraHandledException('Incorrect case status. Please change case status to : Waiting For Payment and try again.');
        }
        return msg;
    }
    
    @AuraEnabled
    public static String sendAttachEmail( String caseId ){
        String msg;
        List<Case> cList = [SELECT Id, AttachmentUrlGuid__c, ContactId, Contact.Email FROM Case WHERE Id = :caseId LIMIT 1];
        if(cList.size() == 0){           
            throw new AuraHandledException('No Case found. Please contact your system administrator');
        }else{
            if( cList[0].ContactId == null ){               
                throw new AuraHandledException('No Contact found');
            }else if( cList[0].Contact.Email == null ){               
                throw new AuraHandledException('No Email address found for the contact');
            }else{
                // Setup the save point for rollback
                Savepoint sp = Database.setSavepoint();
                try{
                    cList[0].AttachmentUrlGuid__c = Utility_NWL.generateNewGuid();
                    if( String.isNotBlank(cList[0].AttachmentUrlGuid__c) ){
                        update cList;
                        String caseAttUrl = CaseAttUploadEmailController_NWL.buildUrl(Date.today(), String.valueOf(cList[0].Id), cList[0].AttachmentUrlGuid__c);
                        if( String.isNotBlank(caseAttUrl) ){
                            EmailNotification__c en = new EmailNotification__c();
                            en.RecordTypeId               = Schema.SObjectType.EmailNotification__c.RecordTypeInfosByName.get('Consumer Case Attachment Email').RecordTypeId;
                            en.Case__c                    = cList[0].Id;
                            en.EmailContact__c            = cList[0].ContactId;
                            en.CaseAttachmentUploadUrl__c = caseAttUrl;
                            insert en;
                            msg = 'Email notification created successfully';
                        }else{                          
                            throw new AuraHandledException('Unable to generate attachment page url. Please contact your system administrator');
                        }
                    }else{                       
                        throw new AuraHandledException('Unable to generate GUID. Please contact your system administrator');
                    }
                }catch(Exception ex){                   
                    // Roll everything back in case of error
                    Database.rollback(sp);
                    throw new AuraHandledException(ex.getMessage());
                }
            }
        }
        return msg;
    }
    
    /**
    * Webservice to send customer payment email
    *
    * @param - i : CaseId
    * @param - s : Case Status
    * @return - void
    */
    @AuraEnabled
    public static String sendEmailAR( String caseId, String caseStatus ){
        String msg;
        Id paymentAccId;

        List<Case> csList = [SELECT Id, ContactId,  Contact.Email, Brand__c
                                        FROM Case
                                        WHERE Id = :caseId];
        if(csList.size() == 0){          
            throw new AuraHandledException('No Case found. Contact your system Administrator');
        }else{
            // Check if Payment Account record exists for this order with no errors
            List<PaymentAccount__c> paList = [SELECT Id, Token__c, Name
                                                FROM PaymentAccount__c
                                                WHERE Case__c =: csList[0].Id
                                                   AND Inactive__c = false];
            // If no record exists , create a new record.
            if(paList.isEmpty()){
                try{
                    if( csList[0].ContactId != null && String.isNotBlank(csList[0].Contact.Email) ){
                        // Create a Payment Account record
                        PaymentAccount__c pa = new PaymentAccount__c();
                        pa.Case__c       = csList[0].Id;
                        pa.Contact__c    = csList[0].ContactId;
                        insert pa;
                        paymentAccId = pa.Id;
                    }else{                       
                        throw new AuraHandledException('No contact or contact email address found');                       
                    }
                }catch(Exception ex){                  
                    throw new AuraHandledException(ex.getMessage());                   
                }
            }else{
                // If a record exists checked if consumer has already submitted the payment.
                // If yes then issue a erorr.
                if( String.isNotBlank(paList[0].Token__c) ){
                    msg = 'Counsumer has already submitted the payment information. Payment Account : ' + paList[0].Name ;                   
                    throw new AuraHandledException(msg);
                }else{
                    paymentAccId = paList[0].Id;
                }
            }

            try{
                // Create a Payment Account record
                EmailNotification__c en = new EmailNotification__c();
                en.RecordTypeId      = Schema.SObjectType.EmailNotification__c.RecordTypeInfosByName.get('AR Payment Email').RecordTypeId;
                en.Case__c           = csList[0].Id;
                en.EmailContact__c   = csList[0].ContactId;
                en.PaymentAccount__c = paymentAccId;
                en.EmailSent__c      = false;
                insert en;
                msg = 'Email message request submitted successfully !' ;
            }catch(Exception ex){        
                throw new AuraHandledException(ex.getMessage());
            }
        }
        return msg;
    }
    
     /*
    * Button press for Order Acknowledgement in Case layout.
    *
    */
    @AuraEnabled
    public static String sendOrdAckEmail( String c ){
        String msg = '';
        List<Case_Order__c> coList = [SELECT Id, Case__c, Case__r.ContactId, Order__c,
                                            Order__r.Distribution_Channel__c, Order__r.POTypeKey__c, Case__r.CaseGroup__c
                                            FROM Case_Order__c WHERE Case__c = :c];

        if( coList.size() > 0 && coList[0].Case__r.CaseGroup__c == 'Customer' ){            
            throw new AuraHandledException('Order Acknowledgement email functionality is not valid for Customer Case');
        } else{
            if(coList.size() == 0){                               
                throw new AuraHandledException('No order found. Please check case orders');
            }else if(coList.size() > 1){                                
                throw new AuraHandledException('Multiple orders found. Please check case orders');
            }
            else{
                if(Utility_NWL.checkSwitch( 'SendOrderAck' ) == true) {
                    EmailNotification__c en = insertEmailNotOrdAck(coList[0].Order__r.Distribution_Channel__c,
                        coList[0].Order__r.POTypeKey__c, coList[0].Case__r.Id, coList[0].Order__r.Id,
                        coList[0].Case__r.ContactId);
                    if(en != null){
                        insert en;
                        msg = 'Order Acknowledgement email sent';
                    } else {                       
                        throw new AuraHandledException('Criteria not met');
                    }
                } else{                   
                    throw new AuraHandledException('SendOrderAck switch is not enabled');
                }
            }
        }
        return msg;
    }
        
    private static EmailNotification__c insertEmailNotOrdAck( String dc, String poType, Id cId, Id oiId, Id ecId){
        Set<String> poTypeSet = new Set<String>{ 'ZSF', 'ZGCR'};
        EMailNotification__c en = null;
        if(dc == '04' && poTypeSet.contains(poType)){
            en = new EmailNotification__c();
            en.RecordTypeId      = Schema.SObjectType.EmailNotification__c.RecordTypeInfosByName.get('Consumer Order Acknowledgement').RecordTypeId;
            en.Case__c           = cId;
            en.OrderIndex__c     = oiId;
            en.EmailContact__c   = ecId;

        }
        return en;
    }
    
     /*
    * Returns custom setting record based on Record Type for a Case Object
    *
    */
    @AuraEnabled(Cacheable=true)
    public static Record_Type_Settings_NWL__c getCustomSettingByRecordType(String recordId){       
        Record_Type_Settings_NWL__c custSetting;
        try{  
            List<Case> csRecordType = [SELECT Id, RecordType.DeveloperName
                                        FROM Case
                                        WHERE Id = :recordId];
            if(csRecordType.size() > 0 && csRecordType[0].RecordType.DeveloperName != null){ 
                List<String> fields = new List<String>(Record_Type_Settings_NWL__c.SObjectType.getDescribe().fields.getMap().keySet());
                String recordType = csRecordType[0].RecordType.DeveloperName;
                String soql = ''
                        + ' SELECT ' + String.join(fields, ',')
                        + ' FROM Record_Type_Settings_NWL__c'
                        + ' WHERE Record_Type__c =:recordType Limit 1';
                custSetting = Database.query(soql);
            }            
        }catch(Exception ex){        
            throw new AuraHandledException(ex.getMessage());
        }        
        return custSetting;
    }

    /*
    * BMT Search for Product Records
    *
    */
    @AuraEnabled
    public static List<Product2> searchProducts(String materialNumber,  String materialDesc, String jamaterialDesc, String brandDesc, String upc, String modelNumber, String color, String size, String region, String materialStatus, String consumerProductName, String webProductName, String productCategory, String countryLanguage, String materialType, String moldNumber, String catalogNumber, String oldMaterialNumber, String division ,String productRT){

        String query;
        String selectClause = 'SELECT Id,Name,Description,ja_Description__c,EAN11__c,Brand_Description__c,X_Plant_Material_Status_Description__c,OMSProductImageURL__c,RecordType.Name FROM Product2 ' ;
        String whereClause;
        String limitClause = ' LIMIT 10';
        List<String> whereClauseList = new List<String>();

        if(String.isNotBlank(materialNumber)){            
            whereClauseList.add('Name LIKE  \''+materialNumber+'%\'');
        }
        if(String.isNotBlank(materialDesc)){
            whereClauseList.add('Description LIKE  \'%'+materialDesc+'%\'');
        }
        if(String.isNotBlank(jamaterialDesc)){
            whereClauseList.add('ja_Description__c LIKE  \'%'+jamaterialDesc+'%\'');
        }
        if(String.isNotBlank(brandDesc)){            
            whereClauseList.add('Brand_Description__c LIKE  \''+brandDesc+'%\'');
        }
        if(String.isNotBlank(upc)){            
            whereClauseList.add('EAN11__c LIKE  \''+upc+'%\'');
        }
        if(String.isNotBlank(modelNumber)){            
            whereClauseList.add('ModelNumber__c LIKE  \''+modelNumber+'%\'');
        }
        if(String.isNotBlank(color)){            
            whereClauseList.add('Color__c LIKE  \''+color+'%\'');
        }
        if(String.isNotBlank(size)){            
            whereClauseList.add('Size__c LIKE  \''+size+'%\'');
        }
        if(String.isNotBlank(region)){            
            whereClauseList.add('Region__c LIKE  \''+region+'%\'');
        }
        if(String.isNotBlank(materialStatus)){            
            whereClauseList.add('X_Plant_Material_Status__c LIKE  \''+materialStatus+'%\'');
        }
        if(String.isNotBlank(consumerProductName)){            
            whereClauseList.add('ConsumerProductName__c LIKE  \'%'+consumerProductName+'%\'');
        }
        if(String.isNotBlank(webProductName)){            
            whereClauseList.add('WebProductName__c LIKE  \'%'+webProductName+'%\'');
        } 
        if(String.isNotBlank(productCategory)){            
            whereClauseList.add('Category__c LIKE  \''+productCategory+'%\'');
        }
        if(String.isNotBlank(countryLanguage)){            
            whereClauseList.add('CountryLanguage__c LIKE  \''+countryLanguage+'%\'');
        }
        if(String.isNotBlank(materialType)){            
            whereClauseList.add('MTART__c LIKE  \''+materialType+'%\'');
        }
        if(String.isNotBlank(moldNumber)){            
            whereClauseList.add('Mold__c LIKE  \''+moldNumber+'%\'');
        }
        if(String.isNotBlank(catalogNumber)){            
            whereClauseList.add('Catalog__c LIKE  \''+catalogNumber+'%\'');
        }
        if(String.isNotBlank(oldMaterialNumber)){            
            whereClauseList.add('Old_Material_Num__c LIKE  \''+oldMaterialNumber+'%\'');
        }
        if(String.isNotBlank(division)){            
            whereClauseList.add('Division__c LIKE  \''+division+'%\'');
        }
        if(String.isNotBlank(productRT)){
            whereClauseList.add('RecordType.Name = \''+productRT+'\'');
        }
        
        if(!whereClauseList.isEmpty()){
             whereClause = ' WHERE '+String.join(whereClauseList, ' AND ') + ' AND IsActive = TRUE';
        
            query = string.join(new List<String>{selectClause,whereClause,limitClause}, ' '); 
            system.debug('Query : '+query);
            List<Product2> products = database.Query(query);
            if(!products.isEmpty()){
                return products;
            }
            
        }
       
        return null;
    }

    /*
    * BMT Create Case Product
    *
    */
    @AuraEnabled
    public static String createCaseProduct(String productId, String caseId){
        Case_Product__c cp = new Case_Product__c();
        cp.case__c = caseId;
        cp.product__c = productId;

        insert cp;
        return 'Success';
        
    }

    /*
    * BMT Search for Contact Records
    * SFDC-11327
    */
    @AuraEnabled
    public static List<Contact> searchContacts(String firstName, String lastName, String email, String phone, String postalCode, String countryCode, String stateCode, String city, String region, String language, String kanaLast, String kanaFirst){

        String query;
        String selectClause = 'SELECT Id,Name,FirstName,LastName,Email,Phone,MailingPostalCode,MailingCountryCode,MailingStateCode,MailingCity,Region__c,Language__c,CreatedDate FROM contact ' ;
        String whereClause;
        String limitClause = 'ORDER BY CreatedDate desc LIMIT 100';
        List<String> whereClauseList = new List<String>();

        
        if(String.isNotBlank(firstName)){            
            whereClauseList.add('FirstName LIKE  \''+firstName+'%\'');
        }
        if(String.isNotBlank(lastName)){            
            whereClauseList.add('LastName LIKE  \''+lastName+'%\'');
        }
        if(String.isNotBlank(email)){            
            whereClauseList.add('Email LIKE  \''+email+'%\'');
        }
        if(String.isNotBlank(phone)){            
            whereClauseList.add('( Phone_Raw__c LIKE  \''+phone.replaceAll('\\D', '')+'%\'' 
                            + ' OR HomePhone_Raw__c LIKE  \''+phone.replaceAll('\\D', '')+'%\'' 
                            + ' OR OtherPhone_Raw__c LIKE  \''+phone.replaceAll('\\D', '')+'%\'' 
                            + ' OR MobilePhone_Raw__c LIKE  \''+phone.replaceAll('\\D', '')+'%\')');
        }

        if(String.isNotBlank(postalCode)){            
            whereClauseList.add('MailingPostalCode LIKE  \''+postalCode+'%\'');
        }
        if(String.isNotBlank(countryCode)){            
            whereClauseList.add('MailingCountryCode =  \''+countryCode+'\'');
        }
        if(String.isNotBlank(stateCode)){            
            whereClauseList.add('MailingStateCode =  \''+stateCode+'\'');
        }
        if(String.isNotBlank(city)){
            whereClauseList.add('MailingCity LIKE \''+city+'%\'');
        }
        if(String.isNotBlank(region)){
            whereClauseList.add('Region__c = \''+region+'\'');
        }
        if(String.isNotBlank(language)){
            whereClauseList.add('Language__c = \''+language+'\'');
        }
        if(String.isNotBlank(kanaLast)){
            whereClauseList.add('KanaLast__c LIKE \''+kanaLast+'%\'');
        }
        if(String.isNotBlank(kanaFirst)){
            whereClauseList.add('KanaFirst__c LIKE \''+kanaFirst+'%\'');
        }

        
        if(!whereClauseList.isEmpty()){
             whereClause = ' WHERE '+String.join(whereClauseList, ' AND ');
        
            query = string.join(new List<String>{selectClause,whereClause,limitClause}, ' '); 
            system.debug('Query : '+query);
            List<Contact> contacts = database.Query(query);
            if(!contacts.isEmpty()){
                return contacts;
            }
            
        }
       
        return null;
    }

    /*
    * BMT Search get open cases for selected contact
    * SFDC-11327
    */
    @AuraEnabled(cacheable=true)
    public static quickCaseWrapper searchCasesfromContact(Id ContactId){


        quickCaseWrapper qcWrap = new quickCaseWrapper();

        List<Case> closedCaseList = [SELECT Id,Subject_Clipped__c,Owner.Name,CaseNumber,Origin,Brand__c,Reason__c,Record_Type_Skill__c,Status FROM Case WHERE Status = 'Closed' AND ContactId =: ContactId ORDER BY CreatedDate desc];
        List<Case> openCaseList = [SELECT Id,Subject_Clipped__c,Owner.Name,CaseNumber,Origin,Brand__c,Reason__c,Record_Type_Skill__c,Status FROM Case WHERE Status <> 'Closed' AND ContactId =: ContactId ORDER BY CreatedDate desc];
        List<Registration__c> regList = [SELECT Id,Brand__c,Product_Description__c,Product__c,Product__r.Name, Contact__c,Source__c FROM Registration__c WHERE Contact__c =: ContactId ORDER BY CreatedDate desc];
        List<Order_Index__c> orList = [SELECT Id,Name,OMSSiteCode__c, CRMOrderType__c FROM Order_Index__c WHERE Contact__c =: ContactId ORDER BY CreatedDate desc];
        List<WorkOrder> woList = [SELECT Id,WorkOrderNumber,WorkOrderStatus__c,CreatedDate,CurrencyIsoCode,OrderType__c FROM WorkOrder WHERE ContactId =: ContactId];

        qcWrap.closedCases = closedCaseList;
        qcWrap.openCases = openCaseList;
        qcWrap.regList = regList;
        qcWrap.orderList = orList;
        qcWrap.workOrdersList = woList;

        return qcWrap; 
    }

    /*
    * BMT create quick Case
    *
    */
    @AuraEnabled
    public static String createquickCase(Id contactId, string brand, string subBrand, string reason, string subject, string description, Id recordTypeId,Id orderId){

        Case newCase = new Case(
        ContactId = contactId,
        RecordTypeId = recordTypeId,
        Brand__c = brand,
        Sub_Brand__c = subBrand,
        Reason__c = reason,
        Subject = subject,
        Description = description
        );

        insert newCase;

        if( newCase.Id != null && orderId != null ){
            Case_Order__c co = new Case_Order__c(
                    Case__c = newCase.Id,
                    Order__c = orderId );
            insert co;
        }

        return newCase.Id;
        
    }
    

    @AuraEnabled
    public static String updateSpamCase(String caseId,String cBrand,String cSubject){   
        CaseComment cc = new CaseComment(CommentBody = 'Spam Case',ParentId = caseId);
        insert cc; 
        if(cBrand == null || cBrand == ''){
            cBrand = 'Newell';
        }
        if(cSubject == null || cSubject == ''){
            cSubject = 'Spam Case';
        }
        Update new Case(Id=caseId,Reason__c = 'Spam',
                          Resolution__c = 'Other Action-Spam-Auto Close',
                          Status = 'Closed',
                          Brand__c = cBrand,
                          Subject = cSubject,
                          OwnerId = UserInfo.getUserId());      
        return null;
    }


public class quickCaseWrapper{

    @AuraEnabled
    public List<Case> openCases {get; set;}
    @AuraEnabled
    public List<Case> closedCases {get; set;}
    @AuraEnabled
    public List<Registration__c> regList {get; set;}
    @AuraEnabled
    public List<Order_Index__c> orderList {get; set;}
    @AuraEnabled
    public List<WorkOrder> workOrdersList {get; set;}

}


}