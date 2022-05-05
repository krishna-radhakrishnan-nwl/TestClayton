/**
* EventTrigger_NWL
*
* Trigger for Event object
*
* @author: Jane Chlastawa
*/
trigger EventTrigger_NWL on Event ( after delete, after insert, after update, 
    before delete, before insert, before update) 
{
   (new Base_NWL.TriggerExecutionManager())
   
        .addExecutor( 
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new EventRecapMtg_NWL( Trigger.new, Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        )   
        .addExecutor( 
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new EventRecapMtg_NWL( Trigger.new, Trigger.newMap, Trigger.oldMap, Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        )
        .addExecutor( 
            Base_NWL.AFTER_DEL_TRIGGER_CAT, 
            new EventRecapMtg_NWL( Trigger.new, Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_DEL_TRIGGER_CAT) 
        )                
                     
   .execute();
}