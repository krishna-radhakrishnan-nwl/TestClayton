/**
* Lead Trigger
**/
trigger LeadTrigger_NWL on Lead (after delete, after insert, after update, 
									before delete, before insert, before update) {

    (new Base_NWL.TriggerExecutionManager())
    	.addExecutor( 
        	Base_NWL.BEFORE_INS_TRIGGER_CAT,
        	new LeadExecutor_NWL( Trigger.new, Trigger.newMap, Trigger.oldMap, Base_NWL.BEFORE_INS_TRIGGER_CAT)
        )
    	.addExecutor( 
        	Base_NWL.BEFORE_UPD_TRIGGER_CAT,
        	new LeadExecutor_NWL( Trigger.new, Trigger.newMap, Trigger.oldMap, Base_NWL.BEFORE_UPD_TRIGGER_CAT)
        )
        .execute();
}