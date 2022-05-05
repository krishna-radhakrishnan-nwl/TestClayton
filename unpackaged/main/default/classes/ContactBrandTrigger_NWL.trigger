trigger ContactBrandTrigger_NWL on ContactBrand__c (after delete, after insert, after update,
                                                            before delete, before insert, before update){
       (new Base_NWL.TriggerExecutionManager())
// BEFORE_INS_TRIGGER_CAT

// BEFORE_UPD_TRIGGER_CAT

// BEFORE_DEL_TRIGGER_CAT


// AFTER_INS_TRIGGER_CAT
        .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new ProRegistrationExecutor_NWL( Trigger.new, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        )
// AFTER_UPD_TRIGGER_CAT
        .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new ProRegistrationExecutor_NWL( Trigger.new, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT )
        )
// AFTER_DEL_TRIGGER_CAT


        .execute();
}