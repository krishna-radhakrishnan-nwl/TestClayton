trigger ContactSalesAreasTrigger_NWL on ContactSalesAreas__c (after update,after insert) {
    
     (new Base_NWL.TriggerExecutionManager())        
        
        .addExecutor( 
          Base_NWL.AFTER_INS_TRIGGER_CAT,
          new ContactSalesAreasExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        )
        
        .addExecutor( 
          Base_NWL.AFTER_UPD_TRIGGER_CAT, 
          new ContactSalesAreasExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT) 
        )        
        .execute();    
}