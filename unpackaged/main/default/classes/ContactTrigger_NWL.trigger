trigger ContactTrigger_NWL on Contact ( after delete, after insert, after update,
                                        before delete, before insert, before update){

    (new Base_NWL.TriggerExecutionManager())
// BEFORE_INS_TRIGGER_CAT
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new ContactFuzzyExecutor_NWL( Trigger.new )
        )
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new GenericConsumerAccount_NWL( Trigger.new )
        )
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new ContactRecTyAssignment_NWL( Trigger.new )
        )
// BEFORE_UPD_TRIGGER_CAT
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new ContactFuzzyExecutor_NWL( Trigger.new )
        )
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new ContactRecTyAssignment_NWL( Trigger.new, Trigger.oldMap )
        )
// BEFORE_DEL_TRIGGER_CAT

// AFTER_INS_TRIGGER_CAT
 		.addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new UserKnowledgePemissionSetHandler_GS( Trigger.newMap, null,Base_NWL.AFTER_INS_TRIGGER_CAT)
        )

// AFTER_UPD_TRIGGER_CAT
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new ContactUpdCasesExecutor_NWL( Trigger.newMap, Trigger.oldMap )
        )
         .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new ContactUpdUserExecutor_NWL( Trigger.newMap, Trigger.oldMap )
        )
        .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new UserKnowledgePemissionSetHandler_GS( Trigger.newMap, Trigger.oldMap,Base_NWL.AFTER_UPD_TRIGGER_CAT )
        )
// AFTER_DEL_TRIGGER_CAT
        .execute();
}