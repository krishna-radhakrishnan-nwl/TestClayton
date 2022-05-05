trigger AccountSalesAreaTrigger_NWL on Account_Sales_Area__c ( before insert, before update, before delete, 
															   after insert, after update, after delete, after undelete) {

    (new Base_NWL.TriggerExecutionManager())
// AFTER INSERT
        .addExecutor( 
        	Base_NWL.AFTER_INS_TRIGGER_CAT,
        	new StrategicAccountUpdateExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        )
// AFTER UPDATE        
        .addExecutor( 
        	Base_NWL.AFTER_UPD_TRIGGER_CAT, 
        	new StrategicAccountUpdateExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT) 
        )
// AFTER DELETE        
        .addExecutor( 
            Base_NWL.AFTER_DEL_TRIGGER_CAT, 
            new StrategicAccountUpdateExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_DEL_TRIGGER_CAT)            
        )
        .execute();  	

}