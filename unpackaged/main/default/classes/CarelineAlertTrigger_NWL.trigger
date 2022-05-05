trigger CarelineAlertTrigger_NWL on CarelineAlert__c (after delete, after insert, after update,
                                                    before delete, before insert, before update) {
    (new Base_NWL.TriggerExecutionManager())
// BEFORE INSERT
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new AddSAPNotesToCarelineAlert_NWL( Trigger.new )
        )
// BEFORE UPDATE
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new UpdateLastCarelineCase_NWL( Trigger.new )
        )
// BEFORE DELETE
// AFTER INSERT
        .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new CarelineUpdCaseExecutor_NWL( Trigger.new )
        )
// AFTER UPDATE
// AFTER DELETE
    .execute();
}