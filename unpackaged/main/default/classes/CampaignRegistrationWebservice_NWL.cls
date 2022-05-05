/**
 * CampaignRegistrationWebservice_NWL
 * Purpose: Webservice to create campaign registration records
 *
 * @author Harshal Gajare
 * @version 1.0 23-Nov-2016
 */
global class CampaignRegistrationWebservice_NWL{
    // Constant values
    private static final String C_SUCCESS              = 'Success';
    private static final String C_ERROR                = 'Error';
    private static final String C_KEY_STATUS           = 'status';
    private static final String C_KEY_MESSAGE          = 'message';
    private static final String C_KEY_CONTACT_ID       = 'contactId';
    private static final String C_CAM_TYPE_CASHBACK    = 'Cashback';
    private static final String C_CAM_TYPE_FULFILLMENT = 'Fulfillment';
    private static final String C_CAM_TYPE_TOTAL_CASHBACK = 'Total Cashback';

    // List to collect call messages
    private static List<String> msgList = new List<String>();
    private static Boolean error = false;

    global class ProductData{
        webservice Integer counter;
        webservice String countryCode;
        webservice String materialNumber;
        webservice Integer quantity;
        webservice String serialNumber;
        webservice String pricePaidPerUnit;
        webservice String curr;
        webservice Date dateOfPurchase; // YYYY-MM-DD
        webservice String dealerName;
        webservice String replacementMaterialNumber;
        webservice String replacementQuantity;
        webservice String webCalculatedCashbackValue;
    }
    global class OrderProductData{
        webservice Integer counter;
        webservice String countryCode;
        webservice String materialNumber;
        webservice Integer quantity;
    }
    global class AttachmentsData{
        webservice Integer counter;
        webservice String name;
        webservice String mimeType;
        webservice Blob base64Body; // Base64 Encoded
    }
    // Class for input data
    global class InputData{
        webservice String brand;
        webservice String campaignType;
        webservice String campaignId;
        webservice String salutation;
        webservice String firstName;
        webservice String lastName;
        webservice String email;
        webservice String phone;
        webservice String mailingStreet;
        webservice String mailingCity;
        webservice String mailingStateCode;
        webservice String mailingPostalCode;
        webservice String mailingCountryCode;
        webservice String accountNumber;
        webservice String sortCode;
        webservice String ibanCode;
        webservice String bicCode;
        webservice String keyValuePairs;
        webservice List<ProductData> productList;
        webservice List<OrderProductData> orderProductList;
        webservice List<attachmentsData> attachmentsList;
    }

    webservice static String register( InputData inp ){
        String jsonStr;
        String region;
        String phoneFormatted;
        String companyName;
        Id campaignRecordTypeId;
        Map<String, String> retStrMap = new Map<String, String>();


        try{
            Map<String, String> keyValMap = (Map<String, String>)JSON.deserialize( inp.keyValuePairs, Map<String, String>.Class );
            if( !keyValMap.containsKey('locale') ){
                retStrMap.put( C_KEY_STATUS, C_ERROR );
                error = true;
                msgList.add( 'locale missing in KVP' );
            }else{
                // Get Region value
                region = RegionDetermination_NWL.getRegionByBrand( inp.brand, keyValMap.get( 'locale' ), true );
                // Get Case Record Type
                try{
                    campaignRecordTypeId = Schema.SObjectType.Campaign.RecordTypeInfosByName.get( inp.campaignType ).RecordTypeId;
                }catch(Exception e){}
                if( campaignRecordTypeId == null ){
                    retStrMap.put( C_KEY_STATUS, C_ERROR );
                    error = true;
                    msgList.add( 'Invalid Campaign Type : ' + inp.campaignType );
                }else{
                    GCASettingsNWL__c gcas = GCASettingsNWL__c.getInstance( GenericConsumerAccount_NWL.determineAccType( region, 'Consumer' ) );
                    if( gcas == null ){
                        retStrMap.put( C_KEY_STATUS, C_ERROR );
                        error = true;
                        msgList.add( 'Generic consumer account settings not found : ' + region );
                    }else{
                        if( !String.isEmpty( inp.phone ) ){
                            phoneFormatted = inp.phone.replaceAll('[\\D]', '');
                        }
                        String language = Utility_NWL.getLanguageText( keyValMap.get( 'locale' ).left(2) );
                        // Check if there is a existing contact
                        DuplicateContact_NWL.ReturnConData con = DuplicateContact_NWL.check( inp.email, phoneFormatted, inp.firstName, inp.lastName );
                        // Check if exisitng contact was found or if a new one should be created
                        if( con.existingContactId != null ){
                            msgList.add( 'Existing contact found : ' + con.existingContactId );
                            retStrMap.put( C_KEY_CONTACT_ID, con.existingContactId );
                            if( keyValMap.containsKey('companyName') ){
                                companyName = keyValMap.get('companyName');
                            }

                            if( con.existingContactList[0].GenericContactName__c == true){
                                con.existingContactList[0].Firstname      = inp.firstName;
                                con.existingContactList[0].LastName       = inp.lastName;
                            }
                            con.existingContactList[0].Language__c        = language;
                            con.existingContactList[0].Mailingstreet      = inp.mailingstreet;
                            con.existingContactList[0].MailingCity        = inp.mailingCity;
                            con.existingContactList[0].MailingStateCode   = Utility_NWL.formatStateCode(inp.mailingStateCode,inp.mailingCountryCode);
                            con.existingContactList[0].MailingPostalCode  = inp.mailingPostalCode;
                            con.existingContactList[0].MailingCountryCode = inp.mailingCountryCode;
                            update con.existingContactList;

                            retStrMap.putAll( CampaignRegistrationWebservice_NWL.create( campaignRecordTypeId, con.existingContactId, inp, region ) );
                        }else{
                            Contact newContact = new Contact();
                            newContact.Contact_Type__c     = 'Consumer';
                            newContact.Salutation          = inp.salutation;
                            newContact.FirstName           = inp.firstName;
                            newContact.LastName            = inp.lastName;
                            newContact.Company_Name_rem__c = companyName;
                            newContact.Email               = inp.email;
                            newContact.Phone               = phoneFormatted;
                            newContact.Region__c           = region;
                            newContact.Language__c         = language;
                            newContact.Mailingstreet       = inp.mailingstreet;
                            newContact.MailingCity         = inp.mailingCity;
                            newContact.MailingStateCode    = Utility_NWL.formatStateCode(inp.mailingStateCode,inp.mailingCountryCode);
                            newContact.MailingPostalCode   = inp.mailingPostalCode;
                            newContact.MailingCountryCode  = inp.mailingCountryCode;

                            DuplicateContact_NWL.NewConReturnData conRes = DuplicateContact_NWL.createNewContact(newContact);
                            if(conRes.isSuccess == true){
                                retStrMap.put( C_KEY_CONTACT_ID, conRes.contactId );
                                msgList.addAll( conRes.msgList );
                                retStrMap.putAll( CampaignRegistrationWebservice_NWL.create( campaignRecordTypeId, conRes.contactId, inp, region ) );
                            }else{
                                error = true;
                                retStrMap.put( C_KEY_STATUS, C_ERROR );
                                msgList.addAll( conRes.msgList );
                            }

                            //Database.SaveResult sr = Database.insert(newContact, false);
                            //// Operation was successful, so get the ID of the record that was processed
                            //if( sr.isSuccess() ){
                            //    msgList.add( 'Contact created successfully');
                            //    retStrMap.put( C_KEY_CONTACT_ID, sr.getId() );
                            //    retStrMap.putAll( CampaignRegistrationWebservice_NWL.create( campaignRecordTypeId, newContact.Id, inp, region ) );
                            //}else{
                            //    // Operation failed, so get all errors
                            //    retStrMap.put( C_KEY_STATUS, C_ERROR );
                            //    error = true;
                            //    for(Database.Error err : sr.getErrors() ) {
                            //        msgList.add('Error creating new contact');
                            //        msgList.add( err.getStatusCode() + ' : ' + err.getMessage() );
                            //        msgList.add('Fields in this error : ' + err.getFields());
                            //    }
                            //}
                        }
                    }
                }
            }
            // Add all collected messaged to return Map
            for( Integer i = 0; i < msgList.size(); i++ ){
                retStrMap.put( C_KEY_MESSAGE + '-' + i, msgList[i] );
            }
            msgList.clear();
        }Catch(Exception e){
            retStrMap.put( C_KEY_STATUS, C_ERROR );
            error = true;
            retStrMap.put( C_KEY_MESSAGE + '-' + '0', e.getMessage()  );
            retStrMap.put( C_KEY_MESSAGE + '-' + '1', 'Line No : ' + e.getLineNumber() );
            retStrMap.put( C_KEY_MESSAGE + '-' + '2', e.getStackTraceString() );
            retStrMap.put( C_KEY_MESSAGE + '-' + '3', e.getTypeName() );
        }
        System.debug( 'retStrMap : ' + retStrMap );

        String conId;
        String camRegId;

        if( retStrMap.containsKey(C_KEY_CONTACT_ID) ){
            conId = retStrMap.get(C_KEY_CONTACT_ID);
        }
        if( retStrMap.containsKey( 'campaignRegistrationId' ) ){
            camRegId = retStrMap.get('campaignRegistrationId');
        }
        // Log incomming data and result
        String elNum = CampaignRegistrationWebservice_NWL.logData( inp, JSON.serialize( retStrMap ), conId, error, camRegId, region );

        // Add Log Number in the return message
        retStrMap.put( 'errorLogNumber', elNum );
        jsonStr = JSON.serialize( retStrMap );

        return jsonStr;
    }

/**
 * Method to create a case
 *
 * @param recTyId       ID of the record type
 * @param conId         ID on the contact record to associate
 * @param inpDt         Incoming Data
 * @param region        Region
 *
 * @return Message logged in a key value map
 */
    private static Map<String, String> create( Id recTyId, Id conId, InputData i, String region ){
        Map<String, String> keyValMap = (Map<String, String>)JSON.deserialize( i.keyValuePairs, Map<String, String>.Class );
        Map<String, String> resMap = new Map<String, String>();
        Map<String, CampaignProduct__c> cpNameToCpMap = new Map<String, CampaignProduct__c>();
        Map<String, CampaignOrderProduct__c> copNameToCopMap = new Map<String, CampaignOrderProduct__c>();
        Set<String> srNumSet = new Set<String>();
        Set<String> prodNameSet = new Set<String>();
        Set<String> ordProdNameSet = new Set<String>();
        String countryCode;
        CampaignRegistration__c newCr;
        // Check if the campaign ID is valid
        List<Campaign> cList = [SELECT Id, StartDate, EndDate, PurchaseStartDate__c, PurchaseEndDate__c,
                                        PostalPOPAllowed__c, DuplicateSerialNumberCheck__c
                                    FROM Campaign
                                    WHERE Id = :Id.valueOf(i.campaignId)
                                      AND IsActive = true];
        if( cList.size() == 0 ){
            resMap.put( C_KEY_STATUS, C_ERROR );
            error = true;
            msgList.add( 'Invalid Campaign Id : [' + i.campaignId + ']. No active campaign found');
            return resMap;
        }
        // Check if the campaign requires website to send POP attachments
        if( cList[0].PostalPOPAllowed__c == 'No' && i.attachmentsList.size() == 0 ){
            resMap.put( C_KEY_STATUS, C_ERROR );
            error = true;
            msgList.add( 'Missing Attachment for Proof Of Purchase. This Campaign requires a Proof Of Purchase to be uploaded on the site');
            return resMap;
        }
        // Check if date of purchase if valid
        if( system.today() < cList[0].StartDate || system.today() > cList[0].EndDate ){
            resMap.put( C_KEY_STATUS, C_ERROR );
            error = true;
            msgList.add( 'Invalid Request. Campaign has ended on ' + cList[0].EndDate );
            return resMap;
        }
        // Check if products already registerd based on S/N
        for( ProductData pd : i.productList ){
            // Check if Date of purchase if not null
            if( pd.dateOfPurchase == null ){
                resMap.put( C_KEY_STATUS, C_ERROR );
                error = true;
                msgList.add( 'Date of Purchase cannot be blank. Product : ' + pd.materialNumber );
                return resMap;
            }
            // Check if date of purchase if valid
            if( pd.dateOfPurchase < cList[0].PurchaseStartDate__c || pd.dateOfPurchase > cList[0].PurchaseEndDate__c ){
                resMap.put( C_KEY_STATUS, C_ERROR );
                error = true;
                msgList.add( 'Date of Purchase outside Campaign Date of Purchase of ' +
                                Utility_NWL.formatDate(cList[0].PurchaseStartDate__c) +
                                ' And ' +
                                Utility_NWL.formatDate(cList[0].PurchaseEndDate__c) +
                                ' for product ' + pd.materialNumber );
                return resMap;
            }
            // TODO : Add logic and code for serial number validation rules
            // Check if Serial Number is blank
            if( cList[0].DuplicateSerialNumberCheck__c == true ){
                if( String.isBlank(pd.serialNumber) ){
                    resMap.put( C_KEY_STATUS, C_ERROR );
                    error = true;
                    msgList.add( 'Serial Number cannot be blank. Product : ' + pd.materialNumber );
                    return resMap;
                }else{
                    if( srNumSet.contains(pd.serialNumber) ){
                        resMap.put( C_KEY_STATUS, C_ERROR );
                        error = true;
                        msgList.add( 'Duplicate Serial Number in the incomming payload : ' + pd.serialNumber );
                        return resMap;
                    }else{
                        srNumSet.add(pd.serialNumber);
                    }
                }
            }
            prodNameSet.add(pd.materialNumber);
            // Campaign Registion will always be for 1 country at a time.
            countryCode = pd.CountryCode.toUpperCase();
        }
        // Check if the product is already  registered for the campaign with the same serial number
        List<CampaignRegistrationItems__c> oldRegList = [SELECT Id, SerialNumber__c FROM CampaignRegistrationItems__c
                                                            WHERE SerialNumber__c IN :srNumSet
                                                              AND CampaignRegistration__r.Campaign__c = :i.campaignId
                                                              AND ProductSerialNumber__c != null
                                                              LIMIT 1];
        if( oldRegList.size() > 0 ){
            resMap.put( C_KEY_STATUS, C_ERROR );
            error = true;
            for( CampaignRegistrationItems__c oCri : oldRegList){
                msgList.add( 'Campaign Registration : ' + oCri.Id + ' already exists for Serial Number : ' + oCri.SerialNumber__c );
                resMap.put( 'duplicateSerialNumber', oCri.SerialNumber__c );
            }
            return resMap;
        }
        // Check for Matching Order Products attached to the campaign setup. If products are not found as a part of the
        // fulfillment campaign setup, return error.
        if( i.campaignType == C_CAM_TYPE_FULFILLMENT){
            for( OrderProductData pd : i.orderProductList ){
                ordProdNameSet.add(pd.materialNumber);
            }
            if( !ordProdNameSet.isEmpty() ){
                for( CampaignOrderProduct__c cp : [SELECT Id, Product__r.Name, RecordType.Name
                                                    FROM CampaignOrderProduct__c
                                                    WHERE RecordTypeId = :Schema.SObjectType.CampaignOrderProduct__c.RecordTypeInfosByName.get(countryCode).RecordTypeId
                                                      AND Product__r.Name IN :ordProdNameSet
                                                      AND Campaign__c = :i.campaignId] ){
                    copNameToCopMap.put(cp.Product__r.Name, cp);
                }
                if( copNameToCopMap.values().size() == 0 ){
                    resMap.put( C_KEY_STATUS, C_ERROR );
                    error = true;
                    msgList.add( 'No valid order products found for campaign' );
                    return resMap;
                }
            }else{
                resMap.put( C_KEY_STATUS, C_ERROR );
                error = true;
                msgList.add( 'No order products selected in payload. For fulfillment campaign Order Products are mandatory.' );
                return resMap;
            }

        }

        // Check for Matching Products attached to the campaign setup. If products are not found as a part of the campaign
        // setup, return error.
        for( CampaignProduct__c cp : [SELECT Id, Product__r.Name, CashbackAmount__c
                                            FROM CampaignProduct__c
                                            WHERE RecordTypeId = :Schema.SObjectType.CampaignProduct__c.RecordTypeInfosByName.get(countryCode).RecordTypeId
                                              AND Product__r.Name IN :prodNameSet
                                              AND Campaign__c = :i.campaignId] ){
            cpNameToCpMap.put(cp.Product__r.Name, cp);
        }
        if( cpNameToCpMap.values().size() == 0 ){
            resMap.put( C_KEY_STATUS, C_ERROR );
            error = true;
            msgList.add( 'No valid products found for campaign' );
            return resMap;
        }

        CampaignRegistration__c cr = new CampaignRegistration__c();
        cr.Campaign__c  = Id.valueOf(i.campaignId);
        cr.Contact__c   = conId;
        cr.PopStatus__c = 'Not Submitted For Approval';
        cr.Country__c   = countryCode;
        if( i.campaignType == C_CAM_TYPE_CASHBACK || i.campaignType == C_CAM_TYPE_TOTAL_CASHBACK){
            cr.BankAccountNumber__c = i.accountNumber;
            cr.BICCode__c           = i.bicCode;
            cr.IBANCode__c          = i.ibanCode;
            cr.SortCode__c          = i.sortCode;
            cr.CashbackStatus__c    = 'Pending POP Approval';
        }else if( i.campaignType == 'Fullfilment'){
            cr.CashbackStatus__c  = 'No Payment Required';
        }

        // Insert new Campaign Registration record
        Database.SaveResult sr = Database.insert(cr, false);
        // Iterate through each returned result
        if ( sr.isSuccess() ) {
            newCr = [SELECT Id, Name FROM CampaignRegistration__c WHERE Id = :sr.getId()];
            // Operation was successful, so get the ID of the record that was processed
            resMap.put( 'campaignRegistrationId', newCr.Id );
            resMap.put( 'campaignRegistrationNumber', newCr.Name );
            msgList.add( 'Campaign Registration Header created successfully' );
            List<CampaignRegistrationItems__c> criList = new List<CampaignRegistrationItems__c>();
            // Create Campaign Registration Item records
            for( ProductData pd : i.productList ){
                CampaignRegistrationItems__c nCri = new CampaignRegistrationItems__c();
                nCri.CampaignRegistration__c = newCr.Id;
                nCri.CampaignProduct__c      = cpNameToCpMap.get(pd.materialNumber).Id;
                nCri.DateOfPurchase__c       = pd.dateOfPurchase;
                nCri.DealerName__c           = pd.dealerName;
                nCri.SerialNumber__c         = pd.serialNumber;
                nCri.Quantity__c             = pd.quantity;
                if( i.campaignType == C_CAM_TYPE_CASHBACK || i.campaignType == C_CAM_TYPE_TOTAL_CASHBACK){
                    nCri.CurrencyIsoCode         = pd.curr;
                    if( pd.webCalculatedCashbackValue != null ){
                        nCri.WebCashbackAmmount__c   = Decimal.valueOf(pd.webCalculatedCashbackValue);
                    }
                    nCri.PricePaidPerUnit__c     = Decimal.valueOf(pd.pricePaidPerUnit);
                    System.debug( 'nCri.PricePaidPerUnit__c : ' + nCri.PricePaidPerUnit__c );
                }else if( i.campaignType == 'Fullfilment' ){

                }
                criList.add(nCri);
            }
            // Insert Campaign Registration Item records, if there are errors do not create any entries.
            List<Database.SaveResult> srList = Database.insert(criList, false);
            for (Database.SaveResult srCri : srList){
                if ( !srCri.isSuccess() ){
                    msgList.add('Error creating Campaign Registration Item record');
                    // Operation failed, so get all errors
                    for(Database.Error err : srCri.getErrors()) {
                        msgList.add( err.getStatusCode() + ' : ' + err.getMessage() );
                        msgList.add('Fields in this error : ' + err.getFields());
                    }
                    resMap.put( C_KEY_STATUS, C_ERROR );
                    error = true;
                    return resMap;
                }
            }
            msgList.add( 'Campaign Registration Items created successfully' );

            if( i.campaignType == C_CAM_TYPE_FULFILLMENT){
                List<CampaignRegistrationOrderItem__c> croiList = new List<CampaignRegistrationOrderItem__c>();
                // Create Campaign Registration Item records
                for( OrderProductData opd : i.orderProductList ){
                    CampaignRegistrationOrderItem__c croi = new CampaignRegistrationOrderItem__c();
                    croi.CampaignRegistration__c = newCr.Id;
                    System.debug('opd.materialNumber : ' + opd.materialNumber );
                    croi.CampaignOrderProduct__c = copNameToCopMap.get(opd.materialNumber).Id;
                    croi.Quantity__c             = opd.quantity;
                    croiList.add(croi);
                }
                // Insert Campaign Registration Item records, if there are errors do not create any entries.
                srList.clear();
                srList = Database.insert(croiList, false);
                for (Database.SaveResult srCri : srList){
                    if ( !srCri.isSuccess() ){
                        msgList.add('Error creating Campaign Registration Order Item record');
                        // Operation failed, so get all errors
                        for(Database.Error err : srCri.getErrors()) {
                            msgList.add( err.getStatusCode() + ' : ' + err.getMessage() );
                            msgList.add('Fields in this error : ' + err.getFields());
                        }
                        resMap.put( C_KEY_STATUS, C_ERROR );
                        error = true;
                        return resMap;
                    }
                }
                msgList.add( 'Campaign Registration Order Items created successfully' );
            }
            // Insert attachments, if there are errors do not create any entries.
            if( i.attachmentsList != null ){
                List<Attachment> atList = new List<Attachment>();
                for( AttachmentsData atd : i.attachmentsList ){
                    if( atd.base64Body.size() > 0 && String.isNotBlank( atd.name ) ){
                        Attachment att  = new Attachment();
                        att.ParentId    = newCr.Id;
                        att.Name        = atd.name;
                        att.Body        = atd.base64Body;
                        att.ContentType = atd.mimeType;
                        atList.add( att );
                    }
                }
                if( !atList.isEmpty() ){
                    try{
                        insert atList;
                        msgList.add( 'Attachments created successfully' );
                    }catch( Exception e ){
                        resMap.put( C_KEY_STATUS, C_ERROR );
                        error = true;
                        msgList.add( 'Error creating attchments');
                        msgList.add( 'Ex Msg : ' + e.getMessage()  );
                        msgList.add( 'Line No : ' + e.getLineNumber() );
                    }
                }
                // Initiate the approval process
                try{
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setComments('New Campaign Registration submitted for approval. Please review and approve/reject.');
                    req.setObjectId(newCr.Id);
                    Approval.ProcessResult result = Approval.process(req);
                    if( result.isSuccess() ){
                        msgList.add( 'Approval process request submitted Successfully' );
                    }else{
                        for(Database.Error err : result.getErrors() ) {
                            msgList.add('Error submitting Approval process request');
                            msgList.add( err.getStatusCode() + ' : ' + err.getMessage() );
                            msgList.add('Fields in this error : ' + err.getFields());
                        }
                    }
                }catch(Exception ex){
                     msgList.add('Approval Process Ex : ' + ex.getMessage());
                }
            }
        }else{
            msgList.add( 'Error creating Campaign Registration Header record' );
            // Operation failed, so get all errors
            for(Database.Error err : sr.getErrors() ) {
                msgList.add( err.getStatusCode() + ': ' + err.getMessage() );
            }
            resMap.put( C_KEY_STATUS, C_ERROR );
            error = true;
            return resMap;
        }
        resMap.put( C_KEY_STATUS, C_SUCCESS );
        return resMap;
    }

    global class Header{
        public String campaignId;
        public String campaignType;
        public String brand;
        public String startDate;
        public String endDate;
        public String purchaseStartDate;
        public String purchaseEndDate;
        public String maxProductsPerRegistration;
        public List<Items> campaignProducts;
        public List<OrderItems> orderProductsList;
        public List<CampaignCountry> campaignCountries;
    }

    global class CampaignCountry{
        public String country;
        public CountryDetails countryCashbackDetails;

    }

    global class CountryDetails{
        public Decimal thresholdHighRange1;
        public Decimal thresholdLowRange1;
        public Decimal cashbackPercentageforRange1;
        public Decimal thresholdHighRange2;
        public Decimal thresholdLowRange2;
        public Decimal cashbackPercentageforRange2;
        public Decimal thresholdHighRange3;
        public Decimal thresholdLowRange3;
        public Decimal cashbackPercentageforRange3;
        public Decimal thresholdHighRange4;
        public Decimal thresholdLowRange4;
        public Decimal cashbackPercentageforRange4;
        public Decimal thresholdHighRange5;
        public Decimal thresholdLowRange5;
        public Decimal cashbackPercentageforRange5;
        public Decimal maxCashbackAmount;
        public String cashbackCurrency;

    }

    global class Items{
        public String country;
        public List<ProductDetials> products;
    }

    global class ProductDetials{
        public String webProductName;
        public String webProductImageName;
        public String sapProductNumber;
        public Decimal cashbackAmount;
        public String cashbackCurrency;
        public Decimal cashbackPercentage;
        public String cashbackCalcPref;
        public String productCategory;
        public String productRange;
    }

    global class OrderItems{
        public String country;
        public List<OrderProductDetials> orderProducts;
    }

    global class OrderProductDetials{
        public String webProductName;
        public String webProductImageName;
        public String sapProductNumber;
        public String stockStatus;
    }

    webservice static String sendCampaignData( Id camId ){
        String result;
        Header h = new Header();
        List<CampaignProduct__c> cpList;
        List<CampaignOrderProduct__c> copList;
        List<CampaignCountries__c> ccList;

        Map<String, List<CampaignProduct__c>> countryToCampaignProdMap = new Map<String, List<CampaignProduct__c>>();
        Map<String, List<CampaignOrderProduct__c>> countryToCampaignOrdProdMap = new Map<String, List<CampaignOrderProduct__c>>();
        Map<String, List<CampaignCountries__c>> countryToCampaignCountryMap = new Map<String, List<CampaignCountries__c>>();

        List<Campaign> cList = [SELECT Id, RecordType.Name, CampaignBrand__r.Name, StartDate, EndDate,
                                        PurchaseStartDate__c, PurchaseEndDate__c, SentToWebsite__c,
                                        MaxProductsPerRegistration__c
                                    FROM Campaign
                                    WHERE Id = :camId
                                      AND IsActive = true
                                      AND SentToWebsite__c = null
                                      LIMIT 1];
        if( cList.size() == 1 ){

            // Obtain the map for CampaignProducts
            for( CampaignProduct__c cp1 : [SELECT Id, RecordType.Name, WebProductName__c, Product__r.Name, WebProductImageName__c,
                                                    CashbackAmount__c, CurrencyIsoCode, CashbackCalculationPreference__c,
                                                    CashbackPercentage__c, ProductCategory__c,ProductSubCategory__c
                                            FROM CampaignProduct__c
                                            WHERE Campaign__c = : camId]){
                if( countryToCampaignProdMap.containsKey(cp1.RecordType.Name) ){
                    cpList = countryToCampaignProdMap.get(cp1.RecordType.Name);
                }else{
                    cpList = new List<CampaignProduct__c>();
                }
                cpList.add(cp1);
                countryToCampaignProdMap.put(cp1.RecordType.Name,  cpList);
            }
            List<Items> iList = new List<Items>();
            for( String s : countryToCampaignProdMap.keySet() ){
                Items i = new Items();
                i.country = s;
                List<ProductDetials> pdList = new List<ProductDetials>();
                for( CampaignProduct__c cp2 : countryToCampaignProdMap.get(s) ){
                    ProductDetials pd = new ProductDetials();
                    pd.webProductName             = cp2.WebProductName__c;
                    pd.webProductImageName        = cp2.WebProductImageName__c;
                    pd.sapProductNumber           = cp2.Product__r.Name;
                    if( cList[0].RecordType.Name == C_CAM_TYPE_CASHBACK || cList[0].RecordType.Name == C_CAM_TYPE_TOTAL_CASHBACK){
                        pd.cashbackAmount     = cp2.CashbackAmount__c;
                        pd.cashbackCurrency   = cp2.CurrencyIsoCode;
                        if ( cp2.CashbackPercentage__c != null ) {
                            pd.cashbackPercentage = cp2.CashbackPercentage__c / 100;
                        }
                        pd.cashbackCalcPref   = cp2.CashbackCalculationPreference__c;
                        pd.productCategory    = cp2.ProductCategory__c;
                        pd.productRange       = cp2.ProductSubCategory__c;
                    }
                    pdList.add(pd);
                }
                i.products = pdList;
                iList.add( i );
            }

            List<OrderItems> oiList = new List<OrderItems>();
            if( cList[0].RecordType.Name == C_CAM_TYPE_FULFILLMENT ){
                for( CampaignOrderProduct__c cop1 : [SELECT Id, RecordType.Name, WebProductName__c, Product__r.Name,
                                                            WebProductImageName__c, StockStatus__c
                                                        FROM CampaignOrderProduct__c
                                                        WHERE Campaign__c = :camId]){
                    if( countryToCampaignOrdProdMap.containsKey(cop1.RecordType.Name) ){
                        copList = countryToCampaignOrdProdMap.get(cop1.RecordType.Name);
                    }else{
                        copList = new List<CampaignOrderProduct__c>();
                    }
                    copList.add(cop1);
                    countryToCampaignOrdProdMap.put(cop1.RecordType.Name, copList);
                }
                for( String s : countryToCampaignOrdProdMap.keySet() ){
                    OrderItems oi = new OrderItems();
                    oi.country = s;
                    List<OrderProductDetials> opdList = new List<OrderProductDetials>();
                    for( CampaignOrderProduct__c cop2 : countryToCampaignOrdProdMap.get(s) ){
                        OrderProductDetials opd = new OrderProductDetials();
                        opd.webProductName      = cop2.WebProductName__c;
                        opd.webProductImageName = cop2.WebProductImageName__c;
                        opd.sapProductNumber    = cop2.Product__r.Name;
                        opd.stockStatus         = cop2.StockStatus__c;
                        opdList.add(opd);
                    }
                    oi.orderProducts = opdList;
                    oiList.add(oi);
                }
            }

            List<CampaignCountry> iCList = new List<CampaignCountry>();
            if(cList[0].RecordType.Name == C_CAM_TYPE_TOTAL_CASHBACK){
                //Obtain the map for CampaignCountries
                for( CampaignCountries__c cc1 : [SELECT Id, RecordType.Name, CashbackPercentageForRange1__c, CashbackPercentageForRange2__c, CashbackPercentageForRange3__c,
                                                        CashbackPercentageForRange4__c, CashbackPercentageForRange5__c,
                                                        ThresholdHighRange1__c, ThresholdHighRange2__c, ThresholdHighRange3__c, ThresholdHighRange4__c, ThresholdHighRange5__c,
                                                        ThresholdLowRange1__c, ThresholdLowRange2__c, ThresholdLowRange3__c, ThresholdLowRange4__c, ThresholdLowRange5__c,
                                                        MaxCashbackAmount__c, CurrencyIsoCode
                                                FROM CampaignCountries__c
                                                WHERE Campaign__c = : camId]){

                    CampaignCountry iC = new CampaignCountry();
                    iC.country = cc1.RecordType.Name;

                    CountryDetails cd = new CountryDetails();
                    cd.thresholdLowRange1         = cc1.ThresholdLowRange1__c;
                    cd.thresholdLowRange2         = cc1.ThresholdLowRange2__c;
                    cd.thresholdLowRange3         = cc1.ThresholdLowRange3__c;
                    cd.thresholdLowRange4         = cc1.ThresholdLowRange4__c;
                    cd.thresholdLowRange5         = cc1.ThresholdLowRange5__c;

                    cd.thresholdHighRange1        = cc1.ThresholdHighRange1__c;
                    cd.thresholdHighRange2        = cc1.ThresholdHighRange2__c;
                    cd.thresholdHighRange3        = cc1.ThresholdHighRange3__c;
                    cd.thresholdHighRange4        = cc1.ThresholdHighRange4__c;
                    cd.thresholdHighRange5        = cc1.ThresholdHighRange5__c;

                    cd.cashbackPercentageforRange1 = cc1.CashbackPercentageForRange1__c;
                    if( cc1.CashbackPercentageForRange1__c  != null ){
                     cd.cashbackPercentageforRange1 = cc1.CashbackPercentageForRange1__c / 100;
                    }

                    cd.cashbackPercentageforRange2 = cc1.CashbackPercentageForRange2__c;
                    if( cc1.CashbackPercentageForRange2__c  != null ){
                     cd.cashbackPercentageforRange2 = cc1.CashbackPercentageForRange2__c / 100;
                    }

                    cd.cashbackPercentageforRange3 = cc1.CashbackPercentageForRange3__c;
                    if( cc1.CashbackPercentageForRange3__c  != null ){
                     cd.cashbackPercentageforRange3 = cc1.CashbackPercentageForRange3__c / 100;
                    }

                    cd.cashbackPercentageforRange4 = cc1.CashbackPercentageForRange4__c;
                    if( cc1.CashbackPercentageForRange4__c  != null ){
                     cd.cashbackPercentageforRange4 = cc1.CashbackPercentageForRange4__c / 100;
                    }

                    cd.cashbackPercentageforRange5 = cc1.CashbackPercentageForRange5__c;
                    if( cc1.CashbackPercentageForRange5__c  != null ){
                     cd.cashbackPercentageforRange5 = cc1.CashbackPercentageForRange5__c / 100;
                    }
                    cd.maxCashbackAmount  = cc1.MaxCashbackAmount__c;
                    cd.cashbackCurrency   = cc1.CurrencyIsoCode;

                    iC.countryCashbackDetails = cd;
                    iCList.add( iC );
                }
            }


            h.campaignId                 = String.valueOf(cList[0].Id);
            h.campaignType               = cList[0].RecordType.Name;
            h.brand                      = cList[0].CampaignBrand__r.Name;
            h.startDate                  = Utility_NWL.formatDate( cList[0].StartDate, '-' );
            h.endDate                    = Utility_NWL.formatDate( cList[0].EndDate, '-' );
            h.purchaseStartDate          = Utility_NWL.formatDate( cList[0].PurchaseStartDate__c, '-' );
            h.purchaseEndDate            = Utility_NWL.formatDate( cList[0].PurchaseEndDate__c, '-' );
            h.maxProductsPerRegistration = String.valueOf(Integer.valueOf(cList[0].MaxProductsPerRegistration__c));

            h.campaignProducts = iList;
            h.orderProductsList = oiList;
            h.campaignCountries = iCList;

            String jsonStr  = JSON.serializePretty( h );
            System.debug( 'jsonStr : ' + jsonStr );
            if( String.isNotBlank(jsonStr) ){
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:ECOMM_CampaignSetup');
                req.setMethod('POST');
                req.setHeader('Content-Type','application/json');
                req.setBody( jsonStr ) ;
                try{
                    Http http = new Http();
                    HttpResponse response = http.send(req);
                    result = 'StatusCode : ' + response.getStatusCode() + ' Body : ' +  response.getBody();
                    System.debug('response.getStatusCode() : '  + response.getStatusCode() );
                    System.debug('response.getBody() : '  + response.getBody() );
                    if( response.getBody().toLowercase().contains('success') ){
                        cList[0].SentToWebsite__c = System.now();
                        update cList;
                        result  = 'SUCCESS : Data sent successfully.' ;
                    }
                }catch( Exception e ){
                    System.debug('ERROR : '+ e);
                    result = 'ERROR : ' + e.getMessage();
                }
            }
        }else{
            result  = 'ERROR : No active campaign found or already sent to the website. Please contact your system admin if you want to resend the data.' ;
        }
        return result;
    }

    webservice static String trackStatus( String camRegNumber ){
        String jsonStr;
        Map<String, String> retStrMap = new Map<String, String>();
        List<CampaignRegistration__c> crhList = [SELECT Id, PopStatus__c, CashbackStatus__c, Contact__r.FirstName,
                                                        Contact__r.LastName, Contact__r.Mailingstreet, Contact__r.MailingCity,
                                                        Contact__r.MailingStateCode, Contact__r.MailingPostalCode,
                                                        Contact__r.MailingCountryCode, Contact__r.Email, CreatedDate,
                                                        TotalCashbackAmount__c, CurrencyIsoCode, Campaign__r.RecordType.Name,
                                                        TrackStatus__c, SapOrderNumber__c
                                                    FROM CampaignRegistration__c
                                                    WHERE Name = :camRegNumber.toUpperCase()
                                                    LIMIT 1];
        if( crhList.size() == 0 ){
            retStrMap.put( C_KEY_STATUS, C_ERROR );
            error = true;
            msgList.add( 'Invalid Campaign Registration Number : [' + camRegNumber + '].');
        }else{
            retStrMap.put( C_KEY_STATUS, C_SUCCESS );
            retStrMap.put( 'campaignType', crhList[0].Campaign__r.RecordType.Name );
            retStrMap.put( 'contactFirstName', crhList[0].Contact__r.FirstName );
            retStrMap.put( 'contactLastName', crhList[0].Contact__r.LastName );
            retStrMap.put( 'contactMailingstreet', crhList[0].Contact__r.Mailingstreet );
            retStrMap.put( 'contactMailingCity', crhList[0].Contact__r.MailingCity );
            retStrMap.put( 'contactMailingStateCode', crhList[0].Contact__r.MailingStateCode );
            retStrMap.put( 'contactMailingPostalCode', crhList[0].Contact__r.MailingPostalCode );
            retStrMap.put( 'contactMailingCountryCode', crhList[0].Contact__r.MailingCountryCode );
            retStrMap.put( 'registrationStatus', crhList[0].TrackStatus__c );
            retStrMap.put( 'registrationDate', Utility_NWL.formatDate( crhList[0].CreatedDate ) ); //YYYY-MM-DD
            if( crhList[0].Campaign__r.RecordType.Name == C_CAM_TYPE_CASHBACK || crhList[0].Campaign__r.RecordType.Name == C_CAM_TYPE_TOTAL_CASHBACK ){
                retStrMap.put( 'contactCashbackAmount', crhList[0].TotalCashbackAmount__c.setScale(2, RoundingMode.HALF_UP) + ' ' + crhList[0].CurrencyIsoCode );
            }else if( crhList[0].Campaign__r.RecordType.Name == C_CAM_TYPE_FULFILLMENT){
                retStrMap.put( 'sapOrderNumber', crhList[0].SapOrderNumber__c );
            }
        }
        jsonStr = JSON.serialize( retStrMap );
        return jsonStr;
    }

/**
 * Log incoming webservice data to the log object with type CONUS
 *
 * @param inp Input data for the webserivce call
 */
    private static String logData( InputData inp, String result, String conId, Boolean err, String camId, String region){
        Log_NWL l = Log_NWL.getInstance(Log_NWL.LogType.CAMRG);
        l.setBrand( inp.brand );
        if( conId != null ){l.setContact( conId );}
        if( camId != null ){l.setCampaignRegId( camId );}
        l.addTrace('region : [' + region + ']' );
        l.addTrace('brand : [' + inp.brand + ']' );
        l.addTrace('campaignType : [' + inp.campaignType + ']' );
        l.addTrace('campaignId : [' + inp.campaignId + ']' );
        l.addTrace('salutation : [' + inp.salutation + ']' );
        l.addTrace('firstName : [' + inp.firstName + ']');
        l.addTrace('lastName : [' + inp.lastName + ']');
        l.addTrace('email : [' + inp.email + ']');
        l.addTrace('phone : [' + inp.phone + ']');
        l.addTrace('mailingStreet : [' + inp.mailingStreet + ']');
        l.addTrace('mailingCity : [' + inp.mailingCity + ']');
        l.addTrace('mailingStateCode : [' + inp.mailingStateCode + ']');
        l.addTrace('mailingPostalCode : [' + inp.mailingPostalCode + ']');
        l.addTrace('mailingCountryCode : [' + inp.mailingCountryCode + ']');
        l.addTrace('accountNumber : [' + inp.accountNumber + ']');
        l.addTrace('sortCode : [' + inp.sortCode + ']');
        l.addTrace('ibanCode : [' + inp.ibanCode + ']');
        l.addTrace('bicCode : [' + inp.bicCode + ']');
        l.addNewLineToTrace();
        l.addTrace('keyValuePairs : [' + inp.keyValuePairs + ']');
        l.addNewLineToTrace();
        l.addTrace('productList : [' + inp.productList + ']');
        l.addNewLineToTrace();
        l.addTrace('orderProductList : [' + inp.orderProductList + ']');
        l.addNewLineToTrace();
        if( inp.attachmentsList != null ){
            for( AttachmentsData ad : inp.attachmentsList ){
                l.addTrace('att : [ ' + ad.name + ' - ' + ad.mimeType + ' - ' + ad.base64Body.size() + ' ]');
            }
        }
        l.addNewLineToTrace();
        l.addTrace('result : [' + result + ']');
        if(err){ l.setIsError(); }
        Id elId = l.createLog(true);
        String elNum = [SELECT Name FROM Email_Log__c WHERE Id = :elId LIMIT 1][0].Name;
        return elNum;
    }
}
//*************************************************** END OF CLASS ***************************************************//