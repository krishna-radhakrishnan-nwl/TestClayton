/**
 * CarelineUpdCaseExecutor_NWL
 * Purpose: Update Case from Careline Alert
 *             AFTER_INS_TRIGGER_CAT
 *
 * @author Harshal Gajare
 * @version 1.0 04-August-2017
 */
public class CarelineUpdCaseExecutor_NWL implements Base_NWL.Executor{
	List<CarelineAlert__c> newCarelineAlerts = new List<CarelineAlert__c>();
	private static boolean isFirst = false;

// Constructor
	public CarelineUpdCaseExecutor_NWL( List<CarelineAlert__c> newValues ){
		this.newCarelineAlerts = newValues;
	}
// Executor
    public void execute(){
    	List<Case> csList = new List<Case>();
	    System.debug( '--->>> CarelineUpdCaseExecutor_NWL::execute() isFirst ' + isFirst );
	    if ( !isFirst ){
	      	isFirst = true;
	    }else{
	      	return;
	    }
    	for( CarelineAlert__c ca : this.newCarelineAlerts ){
    		if(ca.RecordTypeId == Schema.SObjectType.CarelineAlert__c.RecordTypeInfosByName.get('Potential Safety').RecordTypeId
    			&& ca.CaseStatus__c != 'Closed'){
    			if(ca.CaseId__c != null){
	    			Case c = new Case();
	    			c.Id = ca.CaseId__c;
	    			c.LabelYourReference__c = 'HOLD FOR INSPECTION';
	    			csList.add(c);
    			}
    		}
    	}
    	if( !csList.isEmpty() ){
    		update csList;
    	}
    }
}