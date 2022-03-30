/**
* AccountTrigger_NWL
*
* Trigger for Account object
*
* @author: Alex Shekhter
* @version: 1.0 - initial
*/
trigger AccountTrigger_NWL on Account ( after delete, after insert, after update, 
    before delete, before insert, before update) {

   (new Base_NWL.TriggerExecutionManager())
        .addExecutor( 
            Base_NWL.BEFORE_INS_TRIGGER_CAT, 
            new AccountFuzzyExecutor_NWL( Trigger.new ) 
        )
        .addExecutor( 
            Base_NWL.BEFORE_UPD_TRIGGER_CAT, 
            new AccountFuzzyExecutor_NWL( Trigger.new ) 
        )

        .addExecutor( 
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new AccountExecutor_NWL( Trigger.new, Trigger.newMap, Trigger.oldMap, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        )
        .addExecutor( 
            Base_NWL.BEFORE_UPD_TRIGGER_CAT, 
            new AccountExecutor_NWL( Trigger.new, Trigger.newMap, Trigger.oldMap, Base_NWL.BEFORE_UPD_TRIGGER_CAT) 
        ) 
        
        .addExecutor( 
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new NonSAPAccountTeamMember_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        )
        .addExecutor( 
            Base_NWL.AFTER_UPD_TRIGGER_CAT, 
            new NonSAPAccountTeamMember_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT) 
        )
        .addExecutor( 
            Base_NWL.AFTER_DEL_TRIGGER_CAT, 
            new NonSAPAccountTeamMember_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_DEL_TRIGGER_CAT) 
        )

        .execute();
}