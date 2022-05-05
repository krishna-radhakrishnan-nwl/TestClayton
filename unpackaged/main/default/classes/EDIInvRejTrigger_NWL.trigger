trigger EDIInvRejTrigger_NWL on EDI_Inv_Rej_Details__c (after insert, after update) {

	 (new Base_NWL.TriggerExecutionManager())

// BEFORE_DEL_TRIGGER_CAT
	.addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new EdiInvRejExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT)
        )
// AFTER_INS_TRIGGER_CAT

// AFTER_UPD_TRIGGER_CAT
        .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new EdiInvRejExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT)
        )
         
// AFTER_DEL_TRIGGER_CAT
        .execute();

	
		
}