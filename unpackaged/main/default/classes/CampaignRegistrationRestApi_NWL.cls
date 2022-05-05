/**
* File........... : CampaignRegistrationRestApi_NWL
* Created by..... : Harshal Gajare
* Created Date... : 01-Dec-2019
* Description.... : REST API for contacts
*
*               ************* Change Log *************
* JIRA No.        Modified By           Modified Date       Reason
*                 Harshal Gajare        01-Dec-2019         New class
*
*/
@RestResource(urlMapping='/nwl/api/campaign/registration/*')
global with sharing class CampaignRegistrationRestApi_NWL{

    // @HttpGet Read    Reads or retrieves records.
    @HttpGet
    global static void getCampaignRegistrationData(){
        Log_NWL l = Log_NWL.getInstance(Log_NWL.LogType.REST_CAM_REG_API);
        l.setGroup('Consumer');

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        Utility_NWL.RestResponseUtilClass rr = new Utility_NWL.RestResponseUtilClass();
        l.setRestReq(req);

        try{
            rr.isSuccess     = true;
            rr.statusMessage = 'Campaign registration created successfully';
            rr.data          = '{}';

            res.responseBody = Blob.valueOf(JSON.serialize(rr, GlobalConstants_NWL.C_SUPRESS_NULLS));
            res.statusCode = 200;
        }catch(Exception ex){
            rr.isSuccess     = false;
            rr.statusMessage = 'Error : ' + ex.getMessage();
            rr.data          = null;

            res.responseBody = Blob.valueOf(JSON.serialize(rr));
            res.statusCode = 500;

            l.addExceptionToTrace(ex, l);
        }

        l.setRestRes(res);
        l.createLog(true);
    }

    // @HttpPost   Create  Creates records.
    @HttpPost
    global static void postCampaignRegistrationData(){
        Log_NWL l = Log_NWL.getInstance(Log_NWL.LogType.REST_CAM_REG_API);
        l.setGroup('Consumer');

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        Utility_NWL.RestResponseUtilClass rr = new Utility_NWL.RestResponseUtilClass();
        l.setRestReq(req);

        try{
            String jsonStr = req.requestBody.toString();
            CampaignRegistrationRestApi_NWL.RegistrationData rd = new CampaignRegistrationRestApi_NWL.RegistrationData();
            rd = (CampaignRegistrationRestApi_NWL.RegistrationData)JSON.deserialize(jsonStr, CampaignRegistrationRestApi_NWL.RegistrationData.class);

            l.setBrand(rd.brand);

            l.addTraceHeader(' Contact Data ');
            l.addTrace('salutation : ' + rd.contactData.salutation);
            l.addTrace('firstName : ' + rd.contactData.firstName);
            l.addTrace('lastName : ' + rd.contactData.lastName);
            l.addTrace('email : ' + rd.contactData.email);
            l.addTrace('phone : ' + rd.contactData.phone);
            l.addTrace('mailingstreet : ' + rd.contactData.mailingstreet);
            l.addTrace('mailingCity : ' + rd.contactData.mailingCity);
            l.addTrace('mailingStateCode : ' + rd.contactData.mailingStateCode);
            l.addTrace('mailingPostalCode : ' + rd.contactData.mailingPostalCode);
            l.addTrace('mailingCountryCode : ' + rd.contactData.mailingCountryCode);
            l.addNewLineToTrace();

            // validate data
            Utility_NWL.StatusMessage sm = CampaignRegistrationRestApi_NWL.validateInputRegistrationData(rd);
            l.addTraceHeader(' Input Data Validation ');
            l.addTrace('Validate Reg Data : ' + sm.isSuccess );
            l.addTrace('Validate Reg Data Message : ' + sm.message );
            l.addNewLineToTrace();
            if(sm.isSuccess == true){
                CampaignRegistrationRestApi_NWL.RegistrationReturnData rrd = new CampaignRegistrationRestApi_NWL.RegistrationReturnData();
                rrd.warningMessageList = new List<String>();
                String language = CampaignRegistrationRestApi_NWL.determineLanguage(rd);
                String region = CampaignRegistrationRestApi_NWL.determineRegion(rd);

                Map<String, Ebiz_Mapping__c> regKeyFieldMap = new Map<String, Ebiz_Mapping__c>();
                Map<String, Ebiz_Mapping__c> contactKeyFieldMap = new Map<String, Ebiz_Mapping__c>();
                Map<String, String> keyValPairMap = new Map<String, String>();

                String phoneFormatted;
                if( !String.isEmpty( rd.contactData.phone ) ){
                    phoneFormatted = rd.contactData.phone.replaceAll('[\\D]', '');
                }
                // Check for existing contact
                DuplicateContact_NWL.ReturnConData rcd = DuplicateContact_NWL.check(
                    rd.contactData.email, phoneFormatted, rd.contactData.firstName, rd.contactData.lastName
                );
                rrd.warningMessageList.add( 'Existing Contact Id : ' + rcd.existingContactId  );
                l.addNewLineToTrace();
                
                if(rd.additionalDataList != null){
                    for(AdditionalData ad : rd.additionalDataList){
                        keyValPairMap.put(ad.key, ad.value);
                    }
                }
                // Get the webservice key to sf object/field name mapping detials
                for( Ebiz_Mapping__c e : [ SELECT Key_Lowercase__c, Object__c, Field_Api_Name__c, TransformationIdentifier__c
                                          FROM Ebiz_Mapping__c
                                          WHERE Interface_Name__c = 'Campaign Registration'] ){
                                              // Build Map for webservice Key to fieldname
                                              if( e.Object__c == 'CampaignRegistration' ){
                                                  regKeyFieldMap.put( e.Key_Lowercase__c, e );
                                              }else if( e.Object__c == 'Contact' ){
                                                  contactKeyFieldMap.put(e.Key_Lowercase__c, e);
                                              }
                                          }
                if( rcd.existingContactId != null){
                    l.addTrace( 'Existing Contact Found : ' + rcd.existingContactId  );
                    rrd.contactId = rcd.existingContactId;
                    if( !rcd.existingContactList.isEmpty() ){
                        Boolean updateCon = false;
                        if( rcd.existingContactList[0].GenericContactName__c == true &&
                            String.isNotBlank(rd.contactData.firstName) &&
                            String.isNotBlank(rd.contactData.lastName)
                        ){
                            rcd.existingContactList[0].Firstname = rd.contactData.firstName;
                            rcd.existingContactList[0].LastName  = rd.contactData.lastName;
                            updateCon = true;
                            l.addTrace('Existing contact Name to be updated');
                        }

                        if( String.isNotBlank(rd.contactData.mailingstreet) &&
                            String.isNotBlank(rd.contactData.mailingCity) &&
                            String.isNotBlank(rd.contactData.mailingStateCode) &&
                            String.isNotBlank(rd.contactData.mailingPostalCode) &&
                            String.isNotBlank(rd.contactData.mailingCountryCode)
                        ){
                            rcd.existingContactList[0].Language__c        = language;
                            rcd.existingContactList[0].Mailingstreet      = rd.contactData.mailingstreet;
                            rcd.existingContactList[0].MailingCity        = rd.contactData.mailingCity;
                            rcd.existingContactList[0].MailingStateCode   = rd.contactData.mailingStateCode;
                            rcd.existingContactList[0].MailingPostalCode  = rd.contactData.mailingPostalCode;
                            rcd.existingContactList[0].MailingCountryCode = rd.contactData.mailingCountryCode;
                            rcd.existingContactList[0].Region__c          = region;
                            updateCon = true;
                            l.addTrace( 'Existing Contact address to be updated' );
                        }

                        if( String.isNotBlank(phoneFormatted) ){
                            if(rcd.existingContactList[0].Phone_Raw__c == phoneFormatted ||
                                rcd.existingContactList[0].OtherPhone_Raw__c == phoneFormatted ||
                                rcd.existingContactList[0].MobilePhone_Raw__c == phoneFormatted ||
                                rcd.existingContactList[0].HomePhone_Raw__c == phoneFormatted ){
                                l.addTrace( 'Existing Contact Phone Matched' );
                            }else{
                                if( String.isBlank(rcd.existingContactList[0].Phone_Raw__c) ){
                                    rcd.existingContactList[0].Phone = phoneFormatted;
                                    l.addTrace( 'Existing Contact Phone Updated' );
                                    updateCon = true;
                                }else if( String.isBlank(rcd.existingContactList[0].OtherPhone_Raw__c) ){
                                    rcd.existingContactList[0].OtherPhone = phoneFormatted;
                                    l.addTrace( 'Existing Contact Other Phone Updated' );
                                    updateCon = true;
                                }else if( String.isBlank(rcd.existingContactList[0].HomePhone_Raw__c) ){
                                    rcd.existingContactList[0].HomePhone = phoneFormatted;
                                    l.addTrace( 'Existing Contact Home Phone Updated' );
                                    updateCon = true;
                                }else if( String.isBlank(rcd.existingContactList[0].MobilePhone_Raw__c) ){
                                    rcd.existingContactList[0].MobilePhone = phoneFormatted;
                                    l.addTrace( 'Existing Contact Mobile Phone Updated' );
                                    updateCon = true;
                                }else{
                                    l.addTrace( 'Existing Contact Phone Not Updated' );
                                }
                            }
                        }

                        UpdContactData ucd = new UpdContactData();
                        ucd = CampaignRegistrationRestApi_NWL.updContactFromKvp(rcd.existingContactList[0], keyValPairMap, contactKeyFieldMap, updateCon );
                        updateCon = ucd.updateCon;
                        rcd.existingContactList[0] = ucd.con;

                        if(updateCon == true){
                            try{
                                update rcd.existingContactList;
                                l.setContact(rcd.existingContactList[0].Id);
                                l.addTrace( 'Existing Contact updated successfully' );
                            }catch(Exception ex){
                                l.setIsError();
                                l.addTrace( 'Existing Contact update failed' );
                                l.addTrace( 'Contact Update Exception : ' + ex.getMessage() );
                            }
                        }
                    }
                }else{
                    try{
                        Contact newContact = new Contact();
                        newContact.Contact_Type__c    = 'Consumer';
                        newContact.Salutation         = rd.contactData.salutation;
                        newContact.FirstName          = rd.contactData.firstName;
                        newContact.LastName           = rd.contactData.lastName;
                        newContact.Email              = rd.contactData.email;
                        newContact.Phone              = phoneFormatted;
                        newContact.Region__c          = region;
                        newContact.Language__c        = language;
                        newContact.Mailingstreet      = rd.contactData.mailingstreet;
                        newContact.MailingCity        = rd.contactData.mailingCity;
                        newContact.MailingStateCode   = rd.contactData.mailingStateCode;
                        newContact.MailingPostalCode  = rd.contactData.mailingPostalCode;
                        newContact.MailingCountryCode = rd.contactData.mailingCountryCode;

                        newContact = CampaignRegistrationRestApi_NWL.updContactFromKvp(newContact, keyValPairMap, contactKeyFieldMap, false ).con;

                        DuplicateContact_NWL.NewConReturnData conRes = DuplicateContact_NWL.createNewContact(newContact, l);
                        if(conRes.isSuccess == true){
                            rrd.contactId = conRes.contactId;
                            l.setContact(rrd.contactId);
                            for(String s : conRes.msgList){
                                l.addTrace( s );
                            }
                        }else{
                            for(String s : conRes.msgList){
                                l.addTrace( s );
                            }
                            rrd.errorMessage = conRes.message;
                        }
                    }catch(Exception ex){
                        l.addTrace( 'New Contact Create failed : ' + ex.getMessage() );
                        l.addExceptionToTrace(ex, l);
                        rrd.errorMessage = ex.getMessage();
                    }
                }
                if( rrd.contactId != null ){
                    List<CampaignRegistration__c> crList = new List<CampaignRegistration__c>();
                    l.addTrace( 'CampaignId : ' + rd.campaignId);

                    // Check if the campaign ID is valid
                    List<Campaign> cList = [SELECT Id, StartDate, EndDate, PurchaseStartDate__c, PurchaseEndDate__c,
                                                    PostalPOPAllowed__c, DuplicateSerialNumberCheck__c, RecordType.Name,
                                                    POPApprovalRequired__c
                                                FROM Campaign
                                                WHERE Id = :Id.valueOf(rd.campaignId)
                                                  AND IsActive = true];
                    Utility_NWL.StatusMessage csm = CampaignRegistrationRestApi_NWL.validateCampaign(rd, cList);
                    if(csm.isSuccess == true){
                        crList = [SElECT Id, CreatedDate
                                    FROM CampaignRegistration__c
                                    WHERE Campaign__c = :cList[0].Id
                                      AND Contact__c = :rrd.ContactId
                                              LIMIT 1];
                        if(crList.size() < 1){
                            CampaignRegistration__c cr = new CampaignRegistration__c();

                            cr.Campaign__c       = Id.valueOf(rd.campaignId);
                            cr.Contact__c        = rrd.contactId;
                            cr.Country__c        = rd.contactData.mailingCountryCode;
                            if(cList[0].RecordType.Name == 'Gift With Purchase'){
                                cr.RecordTypeId      =  Schema.SObjectType.CampaignRegistration__c.getRecordTypeInfosByName().get('Gift With Purchase').getRecordTypeId();
                                cr.PopStatus__c      = 'Not Submitted For Approval';
                                cr.CashbackStatus__c = 'Not Applicable';
                                cr.GiftItem__c       = rd.giftData.giftItem;
                                cr.Question__c       = rd.giftData.question;
                                cr.Answer__c         = rd.giftData.answer;
                                if( rd.productData != null ){
                                    cr.ProductText__c = rd.productData.productNumber;
                                }
                            }

                            Map<String,String> unusedKeyValPairMap = new Map<String, String>();
                            
                            for( String os : keyValPairMap.keySet() ){
                                String s = os.toLowerCase();
                                // Check if Key form webservice is mapped to a Salesforce object and field
                                if( regKeyFieldMap.containsKey( s ) ){
                                    // If yes, get the detials relavent for the current key
                                    Ebiz_Mapping__c e = regKeyFieldMap.get( s );
                                    // Check if this key needs to be transformed
                                    if( e.TransformationIdentifier__c != null ){
                                        cr = CampaignRegistrationRestApi_NWL.transformValue(e, cr, keyValPairMap.get( os ) );
                                    }else{
                                        cr.put( e.Field_Api_Name__c , keyValPairMap.get( os ) );
                                    }
                                }else{
                                    unusedKeyValPairMap.put(os, keyValPairMap.get( os ));
                                }
                            }

                            Insert cr;
                            rrd.registrationId = cr.Id;

                            l.addTrace('POP Approval Required : ' + cList[0].POPApprovalRequired__c);
                            if(cList[0].POPApprovalRequired__c == true){
                                Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
                                psr.setComments('Campaign registration : ' + cr.Id + ' submitted for approval. Please approve the request');
                                psr.setObjectId(cr.Id);
                                Approval.ProcessResult result = Approval.process(psr);
                                l.addTrace('Approval.ProcessResult : ' + result);
                            }

                            if( rd.attachmentData != null ){
                                if( String.isNotBlank(rd.attachmentData.fileBodyBase64) && String.isNotBlank(rd.attachmentData.fileName) ){
                                    try{
                                        Attachment att  = new Attachment();
                                        att.Name        = rd.attachmentData.fileName;
                                        att.Body        = EncodingUtil.base64Decode(rd.attachmentData.fileBodyBase64);
                                        att.ContentType = rd.attachmentData.fileMimeType;
                                        att.ParentId    = rrd.registrationId;
                                        insert att;

                                        //ContentVersion cv = new ContentVersion();

                                        //cv.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                                        //cv.Origin          = 'H'; //C-Content Origi n. H-Chatter Origin.
                                        //cv.PathOnClient    = rd.attachmentData.fileName;
                                        //cv.Title           = rd.attachmentData.fileName;
                                        ////cv.FileType        = rd.attachmentData.fileMimeType;
                                        //cv.VersionData     = EncodingUtil.base64Decode(rd.attachmentData.fileBodyBase64);
                                        //insert cv;

                                        //ContentDocumentLink cdl = new ContentDocumentLink();
                                        //cdl.ContentDocumentId   = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
                                        //cdl.LinkedEntityId      = cv.Id;
                                        //cdl.ShareType           = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                                        //cdl.Visibility          = 'InternalUsers'; //AllUsers, InternalUsers, SharedUsers
                                        //insert cdl;

                                        l.addTrace('Campaign Reg attachments created successfully');
                                    }catch( Exception ex ){
                                        l.addTrace('Error creating attachments');
                                        rrd.warningMessageList.add( 'Error creating attachments : ' + ex.getMessage() );
                                        l.addExceptionToTrace(ex, l);
                                    }
                                }
                            }else{
                                l.addTrace(' No Attachments sent');
                            }

                            rr.isSuccess     = true;
                            rr.statusMessage = 'Campaign registration created successfully';
                            rr.data          = rrd;
                        }else{
                            l.addTrace('Duplicate Campaign registration found');
                            rrd.registrationId = crList[0].Id;

                            rr.isSuccess     = false;
                            rr.statusMessage = 'Existing campaign registration found';
                            rr.data          = rrd;

                            res.responseBody = Blob.valueOf(JSON.serialize(rr));
                            res.statusCode = 400;

                            l.setIsError();
                        }
                    }else{
                        l.addTrace('Campaign data validation failed');
                        rr.isSuccess     = false;
                        rr.statusMessage = csm.message;
                        rr.data          = null;

                        res.responseBody = Blob.valueOf(JSON.serialize(rr));
                        res.statusCode = 400;

                        l.setIsError();
                    }
                }else{
                    rr.isSuccess     = false;
                    rr.statusMessage = 'Error creating Contact record';
                    rr.data          = rrd;
                }
                res.responseBody = Blob.valueOf(JSON.serialize(rr));
                res.statusCode = 200;
            }else{
                l.addTrace('Input data validation failed');
                rr.isSuccess     = false;
                rr.statusMessage = sm.message;
                rr.data          = null;

                res.responseBody = Blob.valueOf(JSON.serialize(rr));
                res.statusCode = 400;

                l.setIsError();
            }
        }catch(Exception ex){
            rr.isSuccess     = false;
            rr.statusMessage = 'Error : ' + ex.getMessage();
            rr.data          = null;

            res.responseBody = Blob.valueOf(JSON.serialize(rr));
            res.statusCode = 500;

            l.addExceptionToTrace(ex, l);
        }

        l.setRestRes(res);
        l.createLog(true);
    }

    private static Utility_NWL.StatusMessage validateCampaign( CampaignRegistrationRestApi_NWL.RegistrationData inp, List<Campaign> cList ){
        Utility_NWL.StatusMessage res = new Utility_NWL.StatusMessage();

        if( cList.size() == 0 ){
            res.isSuccess = false;
            res.message = 'Invalid Campaign Id : [' + inp.campaignId + ']. No active campaign found';
        }else if( cList[0].PostalPOPAllowed__c == 'No' && inp.attachmentData == null ){
            res.isSuccess = false;
            res.message = 'Missing Attachment for Proof Of Purchase. This Campaign requires a Proof Of Purchase to be uploaded on the site';
        }else if( cList[0].PostalPOPAllowed__c == 'No' && String.isBlank(inp.attachmentData.fileBodyBase64) == true ){
            res.isSuccess = false;
            res.message = 'Missing Attachment for Proof Of Purchase. This Campaign requires a Proof Of Purchase to be uploaded on the site';
        }else if( system.today() < cList[0].StartDate || system.today() > cList[0].EndDate ){
            res.isSuccess = false;
            res.message = 'Invalid Request. Campaign has ended on ' + cList[0].EndDate;
        }else if( cList[0].RecordType.Name == 'Gift With Purchase' && String.isBlank(inp.giftData.giftItem) == true ){
            res.isSuccess = false;
            res.message = 'Gift With Purchase campaigns need gift item detials';
        }else{
            res.isSuccess = true;
        }
        return res;
    }


    private static Utility_NWL.StatusMessage validateInputRegistrationData( CampaignRegistrationRestApi_NWL.RegistrationData inp ){
        Utility_NWL.StatusMessage res = new Utility_NWL.StatusMessage();
        Set<String> legalBrandSet = new Set<String>{'graco', 'baby jogger'};

        if( inp != null ){
            StateCountry_NWL__c sc = StateCountry_NWL__c.getInstance( inp.contactData.mailingCountryCode + '-' + inp.contactData.mailingStateCode );
            if(String.isBlank(inp.contactData.email) && String.isBlank(inp.contactData.phone) && !legalBrandSet.contains(inp.brand.toLowerCase()) ){
                res.isSuccess = false;
                res.message = 'Email or phone is required for a contact';
            }else if(String.isBlank(inp.source) ){
                res.isSuccess = false;
                res.message = 'Registration source is required field';
            }else if(String.isBlank(inp.contactData.firstName) ){
                res.isSuccess = false;
                res.message = 'First Name is required for a contact';
            }else if(String.isBlank(inp.contactData.lastName) ){
                res.isSuccess = false;
                res.message = 'Last Name is required for a contact';
            }else if( String.isBlank(inp.contactData.mailingCountryCode) && String.isNotBlank(inp.contactData.mailingStateCode) ){
                res.isSuccess = false;
                res.message = 'State Code ' + inp.contactData.mailingStateCode + ' is invalid with blank Country Code';
            }else if(String.isNotBlank(inp.contactData.mailingCountryCode) && String.isNotBlank(inp.contactData.mailingStateCode) && sc == null ){
                res.isSuccess = false;
                res.message = 'State Code ' + inp.contactData.mailingStateCode + ' and Country Code ' + inp.contactData.mailingCountryCode + ' is invalid';
            //}else if( inp.productData == null ){
            //    res.isSuccess = false;
            //    res.message = 'Product Data cannot be blank';
            //}else if( String.isBlank(inp.productData.productNumber) ){
            //    res.isSuccess = false;
            //    res.message = 'Product Number cannot be blank';
            }else{
                res.isSuccess = true;
                res.message = 'Registration input data validated successfully';
            }
        }else{
            res.isSuccess = false;
            res.message = 'Invalid input. Null Data';
        }

        return res;
    }

/**
 * Determine Language
 */
    private static String determineLanguage( CampaignRegistrationRestApi_NWL.RegistrationData inp ){
        String language;
        if( String.isNotBlank(inp.languageIsoCode) ){
            language = Utility_NWL.getLanguageText( inp.languageIsoCode );
        }else if( String.isNotBlank(inp.locale) ){
            language = Utility_NWL.getLanguageText( inp.locale.left(2) );
        }else{
            language = 'English';
        }
        return language;
    }

/**
 * Determine Region
 */
    private static String determineRegion( CampaignRegistrationRestApi_NWL.RegistrationData inp ){
        String region;
        if( String.isNotBlank(inp.locale) ){
            region = RegionDetermination_NWL.getRegion( inp.brand, inp.locale );
        }else if( String.isNotBlank(inp.languageIsoCode) && String.isNotBlank(inp.contactData.mailingCountryCode) ){
            String locale = inp.languageIsoCode + '_' + inp.contactData.mailingCountryCode;
            region = RegionDetermination_NWL.getRegionByBrand( inp.brand, locale, true );
        }else{
            if( String.isNotBlank(inp.contactData.mailingCountryCode) ){
                if( inp.contactData.mailingCountryCode.toLowercase() == 'us' ||
                    inp.contactData.mailingCountryCode.toLowercase() == 'ca' ){
                    region = 'US';
                }else{
                    region = 'EMEA';
                }
            }else{
                region = [SELECT Region__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1][0].Region__c;
            }
            if( String.isBlank( region ) ){
                region = 'US';
            }
        }
        return region;
    }

/**
 * Format values based on transformation identifiers
 *
 * @param em Ebiz Mapping Data
 * @param reg Registration Data
 * @param val Value to be transformed
 */
    private static CampaignRegistration__c transformValue( Ebiz_Mapping__c em, CampaignRegistration__c reg, String val ){
        if( em.TransformationIdentifier__c == 'Date' ){
// Assuming Date format being sent is YYYY-MM-DDTHH-MM-SS
            List<String> strList = val.split( 'T' );
            if( strList.size() == 2 ){
                List<String> dateList = new List<String>();
                dateList = strList[0].split('-');
                if( dateList.size() != 3 ){ dateList = strList[0].split('/'); }
                if( dateList.size() != 3 ){ dateList = strList[0].split('.'); }
                if( dateList.size() == 3 ){
                    Date d = Date.newInstance( integer.valueOf( dateList[0] ),    // Year
                                                integer.valueOf( dateList[1] ),   // Month
                                                integer.valueOf( dateList[2] ) ); // Date
                    reg.put( em.Field_Api_Name__c , d );
                }
            }
        }else if( em.TransformationIdentifier__c == 'DateTime' ){
// Assuming DateTime format being sent is YYYY-MM-DDTHH-MM-SS
        }else if( em.TransformationIdentifier__c == 'Number' ){
            reg.put( em.Field_Api_Name__c , Integer.valueOf(val) );
        }
        else if( em.TransformationIdentifier__c == 'Boolean' ){
            reg.put( em.Field_Api_Name__c , Boolean.valueOf(val) );
        }
        return reg;
    }


    private class UpdContactData{
        public Boolean updateCon = false;
        public Contact con;
    }

    private static UpdContactData updContactFromKvp( Contact c, Map<String, String> keyValPairMap, Map<String, Ebiz_Mapping__c> contactKeyFieldMap, Boolean updateCon ){
        UpdContactData ucd = new UpdContactData();
        ucd.updateCon = updateCon;
        ucd.con = c;
        if( !contactKeyFieldMap.keySet().isEmpty() ){
            for( String os : keyValPairMap.keySet() ){
                // Convert webservice incoming keys to lower case
                String s = os.toLowerCase();
                // Check if the key is present in the mapping Salesforce Ebiz Object
                if( contactKeyFieldMap.containsKey( s ) ){
                    // If yes, get the detials relavent for the current key
                    Ebiz_Mapping__c e = contactKeyFieldMap.get( s );
                    ucd.con.put( e.Field_Api_Name__c , keyValPairMap.get( os ) );
                    ucd.updateCon = true;
                }
            }
        }
        return ucd;
    }



    public class RegistrationData{
        public List<AdditionalData> additionalDataList;
        public String brand;
        public String campaignType;
        public String campaignId;
        public String campaignName;
        public ContactData contactData;
        public String locale;
        public String languageIsoCode;
        public ProductData productData;
        public String source;
        public AttachmentData attachmentData;
        public BankData bankData;
        public GiftData giftData;
    }

    public class ContactData{
        public String email;
        public String firstName;
        public String lastName;
        public String mailingCity;
        public String mailingCountryCode;
        public String mailingPostalCode;
        public String mailingStateCode;
        public String mailingstreet;
        public String phone;
        public String salutation;
    }

    public class GiftData{
        public String giftItem;
        public String question;
        public String answer;
    }

    public class ProductData{
        public String productNumber;
        public Integer quantity;
    }

    public class BankData{
        public String accountNumber;
        public String sortCode;
        public String ibanCode;
        public String bicCode;
    }

    public class AttachmentData{
        public String fileBodyBase64;
        public String fileMimeType;
        public String fileName;
    }

    public class AdditionalData{
        public String key;
        public String value;
    }

    public class RegistrationReturnData{
        public String contactId;
        public String registrationId;
        public String errorMessage;
        public List<String> warningMessageList;
    }

}
//*************************************************** END OF CLASS ***************************************************//