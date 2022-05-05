trigger CaseProductTrigger_NWL on Case_Product__c (after delete, after insert, after update,
                                                    before delete, before insert, before update) {
    (new Base_NWL.TriggerExecutionManager())
// BEFORE INSERT
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new CaseProductBrandExecutor_NWL( Trigger.new, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        )
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new CaseProductSummary_NWL( Trigger.new, Trigger.oldMap, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        )
        //.addExecutor(
        //    Base_NWL.BEFORE_INS_TRIGGER_CAT,
        //    new CarelineAlert_NWL ( Trigger.new, Trigger.oldMap, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        //)
// BEFORE UPDATE
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new CaseProductSummary_NWL( Trigger.new, Trigger.oldMap, Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        )
        //.addExecutor(
        //    Base_NWL.BEFORE_UPD_TRIGGER_CAT,
        //    new CarelineAlert_NWL ( Trigger.new, Trigger.oldMap, Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        //)
// AFTER INSERT
        //.addExecutor(
        //    Base_NWL.AFTER_INS_TRIGGER_CAT,
        //    new CaseProductExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        //)
        //.addExecutor(
        //    Base_NWL.AFTER_INS_TRIGGER_CAT,
        //    new CarelineAlert_NWL ( Trigger.new, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        //)
// AFTER UPDATE
        //.addExecutor(
        //    Base_NWL.AFTER_UPD_TRIGGER_CAT,
        //    new CaseProductExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT)
        //)
        .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new CarelineAlert_NWL ( Trigger.new, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT )
        )
// AFTER DELETE
        //.addExecutor(
        //    Base_NWL.AFTER_DEL_TRIGGER_CAT,
        //    new CaseProductExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_DEL_TRIGGER_CAT)
        //)
        .execute();
}