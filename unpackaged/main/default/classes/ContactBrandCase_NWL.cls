/**
* File........... : ContactBrandCase_NWL
* Jira........... : SFDC-6221
* Created by..... : Krishna Radhakrishnan
* Created Date... : 04-Apr-2019
* Description.... : Controller class for ContactBrandCase_NWL visual force page.
*                   This identifies all the related cases of this current case and displays in the VF component.
*                   User can do the merge cases button and merge the images, attachments, events, tasks etc to the parent case.
*                   Parent case is identified as the oldest case available. Also the child cases are made as child to the parent case.
*                   THe child cases are closed with reason/REsolution code as 'Merged to Parent', this way the surveys will not be called
*                   and other validation rules can be asked to exclude.
*
*               ************* Change Log *************
* JIRA No.        Modified By           Modified Date       Reasons
*
*/
public with sharing class ContactBrandCase_NWL {

    private final Case refCaseRec;
    public List<Case> csList {get; private set;}
    public List<CaseWrapper> csWrapperList {get; set;}

    private static final String C_MERGED_TO_PARENT_REASONRES = 'Merged to Parent';
    private static final String C_CASE_STATUS_CLOSED         = 'Closed';

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public class Mergeexception extends Exception {}
    
    @auraenabled
    public static List<CaseWrapper> getrelatedcases(Id recordId){
        try{
             case obj = new case(Id = recordId);
             ApexPages.StandardController sc = new ApexPages.StandardController(obj);
             ContactBrandCase_NWL ctrl = new ContactBrandCase_NWL(sc);  
             return ctrl.csWrapperList;
           }
        catch(Exception e){
              //throw new AuraHandledException('Darn it! Something went wrong: ' + e.getMessage()+ ' '+e.getStackTraceString());    
                 throw new AuraHandledException(e.getMessage());
           }
    }
    
    @auraenabled
    public static void mergecaselwc(List<CaseWrapper> wrappercasedata, Id recordId)
    {
        try{
            system.debug('wrappercasedata'+wrappercasedata);
            case obj = new case(Id = recordId);
            ApexPages.StandardController sc = new ApexPages.StandardController(obj);
            ContactBrandCase_NWL ctrl = new ContactBrandCase_NWL(sc);
            for(CaseWrapper cw : wrappercasedata)
            { 
              cw.selected =true;
            }
            ctrl.csWrapperList = wrappercasedata;
            ctrl.mergeCases();
        }
        catch(Exception e){
            //throw new AuraHandledException('Darn it! Something went wrong: ' + e.getMessage()+ ' '+e.getStackTraceString());    
            throw new AuraHandledException(e.getMessage());
        }
    }         
    
    public ContactBrandCase_NWL(ApexPages.StandardController stdController) {
        this.refCaseRec = [SELECT Id, CaseNumber, Owner.Name,Owner.Id, Contact.Name, Status,
                        Subject, Type, Brand__c,CreatedDate, SuppliedEmail, Contact.Id, ContactEmail FROM CASE WHERE Id=:stdController.getId() LIMIT 1 ];
        system.debug('this.refCaseRec'+this.refCaseRec);
        // Obtain the related cases for this case. Do not bring the related cases if the current case is closed.
        this.csList = new List<Case>();
        if(this.refCaseRec != null && this.refCaseRec.Status != C_CASE_STATUS_CLOSED){
            this.csList = fetchRelatedCases(this.refCaseRec);
        }
        System.debug('csList: '+csList);
        // Obtain the CaseWrapper
        for (Case c : csList ){
            if(csWrapperList==null){
                csWrapperList = new List<CaseWrapper>();
            }
            CaseWrapper csw = new CaseWrapper(c);
            this.csWrapperList.add(csw);
        }
        if(this.csWrapperList != null && this.csWrapperList.size() > 0){
            this.csWrapperList.sort();
        }

    }

    public PageReference mergeCases(){
        Savepoint sp = Database.setSavepoint();

        try{
            Id currUserId = UserInfo.getUserId();
            System.debug('MergeCases() UserInfo: '+currUserId);
            System.debug('CurrentCaseId: this.refCaseRec.ID : '+this.refCaseRec.Id);
            Id currCaseId = this.refCaseRec.Id;
            List<Case> csToBeUpdList = new List<Case>();
            Set<Id> csIdToBeUpdSet = new Set<Id>();
            Case parentCase;

            System.debug('his.csWrapperList:: '+this.csWrapperList);
            if(this.csWrapperList == null || this.csWrapperList.size() < 1){
                //ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.No_Cases_available_to_merge));
                //return null;
                throw new Mergeexception(System.Label.No_Cases_available_to_merge);
            }

            // Obtain the list of Cases to be merged
            // Loop through the Case list. Obtain the first case.
            for(CaseWrapper csw : this.csWrapperList) {
                if(csw.selected){
                    if(parentCase == null){
                        system.debug('casew'+csw.cs+csw.cs.CreatedDate);
                        // Identify the oldest case as the parent case.
                        if(csw.cs.CreatedDate > this.refCaseRec.CreatedDate){
                            parentCase = this.refCaseRec;
                            csToBeUpdList.add(csw.cs);
                            csIdToBeUpdSet.add(csw.cs.Id);
                        } else {
                            parentCase = csw.cs;
                            csToBeUpdList.add(this.refCaseRec);
                            csIdToBeUpdSet.add(this.refCaseRec.Id);
                        }
                    } else {
                        csToBeUpdList.add(csw.cs);
                        csIdToBeUpdSet.add(csw.cs.Id);
                    }
                }
            }
            System.debug('parentCase: '+parentCase);
            System.debug('MergeCases() csIdToBeUpdSet: '+csIdToBeUpdSet);
            System.debug('MergeCases() csToBeUpdList: '+csToBeUpdList);
            if(parentCase == null || csToBeUpdList.size() < 1){
                // If there are no parent case, Return and show the error message
                //ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,Label.No_Cases_to_be_updated));
                //return null;
                throw new Mergeexception(System.Label.No_Cases_to_be_updated);
            }

            // Clone the attachments to the parent Id and delete the existing attachments.
            List<Attachment> attchList = new List<Attachment>();
            List<ContentVersion> cvList = new List<ContentVersion>();
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            attchList = [SELECT Id, Name,Body, Description, ContentType, OwnerId, ParentId From Attachment WHERE
                IsDeleted=false AND ParentId IN : csIdToBeUpdSet];
            List<Attachment> insAttchList = new List<Attachment>();
            System.debug('attchList: '+attchList);
            List<ContentDocumentLink> links=[SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink where LinkedEntityId in :csIdToBeUpdSet];
            Set<Id> ids=new Set<Id>();	
            for(ContentDocumentLink link:links)
            {
                ids.add(link.ContentDocumentId);
            }
            List<ContentVersion> lstCV=[SELECT Id,VersionData,Title,ContentDocumentId,FileExtension,FileType FROM ContentVersion 
                                        WHERE ContentDocumentId in :ids AND IsLatest = true ORDER BY CreatedDate DESC];
            for(Attachment attch : attchList){
                /*Attachment newFile = attch.clone();
                newFile.ParentId = parentCase.Id;
                newFile.OwnerId = currUserId;
                insAttchList.add(newFile);*/
                ContentVersion cv = new ContentVersion();
                cv.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                cv.Origin          = 'C'; //C-Content Origi n. H-Chatter Origin.
                cv.PathOnClient    = attch.Name;
                cv.Title           = attch.Name;
                cv.VersionData     = attch.body;
                cvList.add(cv);
            }
             for(ContentVersion file : lstCV){
                ContentVersion cv = new ContentVersion();
                cv.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                cv.Origin          = 'C'; //C-Content Origi n. H-Chatter Origin.
                cv.PathOnClient    = file.Title +'.'+ file.FileExtension;
                cv.Title           = file.Title ;
                cv.VersionData     = file.VersionData;
                cvList.add(cv);
            }
           /* if(!insAttchList.isEmpty()){
                System.debug('insAttchList: '+insAttchList);
                insert insAttchList;
            }*/
            if ( cvList.size() > 0 ){
                try{
                    insert cvList;
                    cvList = [select id, ContentDocumentId from ContentVersion WHERE Id in :cvList];
                    for (ContentVersion cv : cvList) {
                        ContentDocumentLink cl = new ContentDocumentLink();
                        cl.ContentDocumentId = cv.ContentDocumentId;
                        cl.LinkedEntityId = parentCase.Id; //Shared with record ID
                        cl.ShareType = 'V'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                        cl.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
                        cdlList.add(cl);
                        
                    }
                    insert cdlList;
                }
                catch(Exception ex){
                    System.Debug('Error in attaching Files: '+ ex.getStackTraceString());
                    throw new Mergeexception('Error in attaching Files: '+ex.getMessage());
                }
            }



            // List the tasks and update teh what id to parent case.
            List<Task> tskList = new List<Task>();
            tskList = [SELECT Id, Subject, Revised_Date__c, Status, OwnerId, WhatId, ActivityDate,
                What.Name,Priority, WhatIdPrefix__c from Task where WhatId in : csIdToBeUpdSet and isClosed != :true];
            System.debug('tskList: '+tskList);
            for(Task tsk : tskList){
                tsk.WhatId = parentCase.Id;
            }
            if(!tskList.isEmpty()){
                System.debug('updated tskList: '+tskList);
                update tskList;
            }

            // List the event tasks and update the what Id to parent case.
            List<Event> evtList = new List<Event>();
            evtList = [SELECT Id, WhatId, Subject, Type, Location, Description FROM Event where
                WhatId IN :csIdToBeUpdSet];
            System.debug('evtList: '+evtList);
            for(Event evt : evtList){
                evt.WhatId = parentCase.Id;
            }
            if(!evtList.isEmpty()){
                System.debug('updated evtList: '+evtList);
                update evtList;
            }

            // Update the child cases and make the parent id as teh aprent case id.
            List<Case> finalCsToUpd = new List<Case>();
            List<String> childCsNbrs = new List<String>();
            for(Case csToUpd : csToBeUpdList){
                csToUpd.Reason__c = C_MERGED_TO_PARENT_REASONRES;
                csToUpd.Resolution__c = C_MERGED_TO_PARENT_REASONRES;
                if(csToUpd.Owner.Id != currUserId) {
                    csToUpd.OwnerId = currUserId;
                }
                csToUpd.ParentId = parentCase.Id;
                csToUpd.SAP_Notes__c = C_MERGED_TO_PARENT_REASONRES;
                csToUpd.Subject = C_MERGED_TO_PARENT_REASONRES;
                csToUpd.Status = C_CASE_STATUS_CLOSED;
                childCsNbrs.add(csToUpd.CaseNumber);
                finalCsToUpd.add(csToUpd);
            }
            if(parentCase.Owner.Id != currUserId){
                parentCase.OwnerId = currUserId;
                finalCsToUpd.add(parentCase);
            }
            System.debug('finalCsToUpd: '+finalCsToUpd);
            if(!finalCsToUpd.isEmpty()){
                update finalCsToUpd;
            }
            String finChldCs = '(';
            for(Integer i=0; i<childCsNbrs.size(); i++){
                finChldCs = finChldCs + childCsNbrs[i];
                if(i < childCsNbrs.size()-1){
                    finChldCs = finChldCs + ', ';
                }
            }
            finChldCs = finChldCs + ')';
            //ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, Label.Cases_successfully_merged + Label.Parent_Case_ContactBrandCase_NWL+' #: '+parentCase.CaseNumber+'; '+Label.Child_Case_ContactbrandCase_NWL+': '+finChldCs));
        } catch(Exception ex){
            Database.rollback(sp);
            //ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Exception_while_merging_Cases +' : '+ex.getMessage()));
            throw new Mergeexception(System.Label.Exception_while_merging_Cases+' : '+ex.getMessage());
        }
        return null;
    }


    private List<Case> fetchRelatedCases(Case caseRec){
        List<Case> rltCsList = new List<Case>();
        Id caseRecId = caseRec.Id;
        String caseBrand = caseRec.Brand__c;
        Id caseContactId = null;
        if(caseRec.Contact != null){
            caseContactId = caseRec.Contact.Id;
        }
        String suppEmailAdd = caseRec.SuppliedEmail;
        Integer lastDays = 30;
        try{
            if(GlobalValuesNWL__c.getInstance('ContactBrandOldCaseLastDays') != null){
                lastDays= Integer.valueOf(GlobalValuesNWL__c.getInstance('ContactBrandOldCaseLastDays').Value__c);
            }
        }catch(Exception ex){
            lastDays = 30;
        }
        Date d = System.today() - lastDays;
        Set<Id> exCsIds = new Set<Id>(); // Set variable to denote the case Id's to be excluded.
        // Adding the current case to the exclusion list.
        exCsIds.add(caseRecId);
        if(String.isNotEmpty(caseContactId)) {
            rltCsList = [SELECT Id, CaseNumber, Owner.Name,Owner.Id, Contact.Name, Status,
                        Subject, Type, Brand__c,CreatedDate, SuppliedEmail, Contact.Id, ContactEmail
                        FROM Case
                        WHERE
                        isClosed=false AND
                        Contact.Id = :caseContactId AND
                        Brand__c =: caseBrand AND
                        RecordType.Name NOT IN ('EMEA RM Risk','RM Risk') AND
                        CreatedDate >= :d AND
                        Id != :caseRecId];
            for(Case cs : rltCsList){
                exCsIds.add(cs.Id);
            }
        }


        // 2nd Query If Contact is prsent for the current case, retrieve all the cases whose supplied
        // Email address is same as the current case Contact email address
        if(String.isNotEmpty(caseRec.ContactEmail)){
            String contEmailAdd = caseRec.ContactEmail;
            List<Case> qryTwoCsList = [SELECT Id, CaseNumber, Owner.Name,Owner.Id, Contact.Name, Status,
                                            Subject, Type, Brand__c,CreatedDate, SuppliedEmail, Contact.Id, ContactEmail
                                            FROM Case
                                            WHERE
                                            IsClosed = false AND
                                            SuppliedEmail = :contEmailAdd AND
                                            Brand__c =: caseBrand AND
                                            RecordType.Name NOT IN ('EMEA RM Risk','RM Risk') AND
                                            CreatedDate >= :d AND
                                            Id NOT IN : exCsIds];
            rltCsList.addAll(qryTwoCsList);
            for(Case cs : qryTwoCsList){
                exCsIds.add(cs.Id);
            }

        }

        //3rd Query. No Contact but case has Supplied email address, retieve all cases whose
        // supplied email address is same as curent case supplied email address
        if(String.isEmpty(caseContactId) && String.isNotEmpty(suppEmailAdd)){
            List<Case> qryThreeCsList = [SELECT Id, CaseNumber, Owner.Name,Owner.Id, Contact.Name, Status,
                                            Subject, Type, Brand__c,CreatedDate, SuppliedEmail, Contact.Id, ContactEmail
                                            FROM Case
                                            WHERE
                                            IsClosed = false AND
                                            SuppliedEmail = :suppEmailAdd AND
                                            Brand__c =: caseBrand AND
                                            RecordType.Name NOT IN ('EMEA RM Risk','RM Risk') AND
                                            CreatedDate >= :d AND
                                            Id NOT IN : exCsIds];
            rltCsList.addAll(qryThreeCsList);
        }
        System.debug('fetchRElatedCases final rltCsList : '+rltCsList);
        return rltCsList;
    }

    /*
    * Wrapper class implementing Comparable interface. This is for sorting in
    * ascending order of created Date.
    */
    public class CaseWrapper implements Comparable{
        @auraenabled
        public Case cs {get; set;}
        @auraenabled
        public Boolean selected {get; set;}
        @auraenabled
        public DateTime createdDateTime {get; set;}
        
        public CaseWrapper(){}
        public CaseWrapper(Case c){
            cs = c;
            selected = false;
            createdDateTime = c.CreatedDate;
        }
        
        public Integer CompareTo(Object otherObj) {
            CaseWrapper compareToCW = (CaseWrapper)otherObj;
            if(this.createdDateTime == compareToCW.CreatedDateTime) return 0;
            if(this.createdDateTime > compareToCW.CreatedDateTime) return 1;
            return -1;
        }


    }

}