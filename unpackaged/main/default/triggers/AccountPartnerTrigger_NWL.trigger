trigger AccountPartnerTrigger_NWL on Account_Partner__c (after delete, after insert, after update, 
									before delete, before insert, before update)  {

    (new Base_NWL.TriggerExecutionManager())
        .addExecutor( 
        	Base_NWL.AFTER_INS_TRIGGER_CAT,
        	new AccountPartnerExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        )
        .addExecutor( 
        	Base_NWL.AFTER_UPD_TRIGGER_CAT, 
        	new AccountPartnerExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT) 
        )
        .addExecutor( 
            Base_NWL.AFTER_DEL_TRIGGER_CAT, 
            new AccountPartnerExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_DEL_TRIGGER_CAT)            
        )
        .execute();    
}