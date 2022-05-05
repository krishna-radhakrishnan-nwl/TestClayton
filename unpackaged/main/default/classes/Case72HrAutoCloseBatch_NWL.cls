/**
* File.......... : Case72HrAutoCloseBatch_NWL
* @author....... : Krishna Radhakrishnan
* @version...... : 1.0
* @createdDate.. : 19-Feb-2019
* Description... : Batch job to move the functionality of the Process Builder Service - Case - EMEA reminder email for Waiting For Consumer
* 				   to a batch job. Obtain all the cases whose record type has 72 Hr auto close option enabled in REcordTypeSetting custom settings
*				   to close the case
*
*/
global class Case72HrAutoCloseBatch_NWL implements Database.Batchable<sObject>, Database.Stateful{

	private static Log_NWL l = Log_NWL.getInstance(Log_NWL.LogType.AUTO_CLOSE_72_HOUR);

  public static final String C_WAITING_ON_CONSUMER       = 'Waiting on Consumer';
	public static final String C_CASE_STATUS_CLOSED 	   = 'Closed';
	public static final String C_CASE_RESOLUTION_SYS_AUTO_CLOSE   = 'System Auto Close';
	public static final String C_CASEGROUP_CONSUMER		   = 'Consumer';
	public static final String C_CASE_REASON_INFORMATION   = 'Information';
	public static final String C_CASE_STATUS_WAIT_INT_DATA = 'Waiting on Internal Data';

	global Database.QueryLocator start(Database.BatchableContext bc) {

		// Only selecting the RecordTypes that have the X72HourAutoClose__c custom setting
		Set<String> caseRecTypesSet = new Set<String>();
        List<Record_Type_Settings_NWL__c> rtsList = Record_Type_Settings_NWL__c.getAll().values();
        for(Record_Type_Settings_NWL__c rts : rtsList){
            if(rts.X72HourAutoClose__c){
                caseRecTypesSet.add(rts.Record_Type__c);
            }
        }

        return Database.getQueryLocator([ SELECT Id, Status, CaseGroup__c, Resolution__c, Reason__c, AutoFollowUpEmailDate__c
                                            FROM Case
                                            WHERE REcordType.DeveloperName IN: caseRecTypesSet
                                              AND Status =: C_WAITING_ON_CONSUMER
                                              AND AutoFollowUpEmailDate__c <= :DateTime.now()
                                              AND New_Email_From_Customer__c = false
                                            ORDER BY CreatedDate ASC]);
	}

   	global void execute(Database.BatchableContext bc, List<sObject> scope) {
   		List<Case> cList = (List<Case>)scope;
        Set<Id> origCIds = new Set<Id>();
        // Map of Case Id to its Case record
        Map<Id, Case> cIdToCaseMap = new Map<Id, Case>();
   		// Update the status, CaseGroup, Resolution and Reason
   		for(Case c : cList){
   			c.Status 		= C_CASE_STATUS_CLOSED;
   			c.CaseGroup__c	= C_CASEGROUP_CONSUMER;
   			c.Resolution__c = C_CASE_RESOLUTION_SYS_AUTO_CLOSE;
            if( String.isBlank(c.Reason__c) ){
                c.Reason__c   = C_CASE_REASON_INFORMATION;
            }
   			origCIds.add(c.Id);
   			cIdToCaseMap.put(c.Id, c);
   		}
        Set<Id> notSuccessIds = new Set<Id>();

   		// Do the Database.SaveResult
   		if(!cList.isEmpty()) {
   			List<Database.SaveResult> dbResList = Database.update(cList, false);

            for(Integer i=0; i<dbResList.size(); i++ ){
                if( dbResList.get(i).isSuccess() ){
                    //log.Trace__c += '\n' + 'CO Id : ' + caseOrdersToUpdList[i].Id + ' || Msg : Success';
                    l.addTrace('Case : ' + cList[i].Id + ' || Success');
                }else{
                    Database.Error err = dbResList.get(i).getErrors().get(0);
                    l.addTrace('Case : ' + cList[i].Id + ' || Error : ' + err.getMessage());
                    l.setIsError();
                    notSuccessIds.add(cList[i].Id);
                }
            }
            l.addNewLineToTrace();
            l.addTrace('----- Case Closing Error Updates -----');
            l.addNewLineToTrace();
            // If there are records that were not successful, update the status to Waiting for Internal Data
            if(!notSuccessIds.isEmpty()) {
                List<Case> updCsList = new List<Case>();
                for(Id i : notSuccessIds){
                	Case c = cIdToCaseMap.get(i);
                	updCsList.add(c);
                }
                for(Case c : updCsList){
                    c.Status = C_CASE_STATUS_WAIT_INT_DATA;
                }
                if(!updCsList.isEmpty()) {
                    List<Database.SaveResult> dbResList2 = Database.update(updCsList, false);
                    for(Integer i=0; i<dbResList2.size(); i++){
                        if(dbResList2.get(i).isSuccess()) {
                            l.addTrace('Case : ' + updCsList[i].Id + ' || Success : Waiting On Data');
                        } else {
                            Database.Error err = dbResList2.get(i).getErrors().get(0);
                            l.addTrace('Case : ' + updCsList[i].Id + ' || Error : ' + err.getMessage());
                            l.setIsError();
                        }
                    }
                }
            }
   		}
   		l.createLog(false);
	}

	global void finish(Database.BatchableContext BC) {
	}

}