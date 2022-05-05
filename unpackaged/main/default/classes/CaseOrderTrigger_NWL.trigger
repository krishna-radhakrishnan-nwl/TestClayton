trigger CaseOrderTrigger_NWL on Case_Order__c (after delete, after insert, after update,
                                                            before delete, before insert, before update){

       (new Base_NWL.TriggerExecutionManager())
// BEFORE_INS_TRIGGER_CAT

            .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new CaseOrderCurrencyUpdate_NWL (Trigger.new, Base_NWL.BEFORE_INS_TRIGGER_CAT)
            )
// BEFORE_UPD_TRIGGER_CAT

// BEFORE_DEL_TRIGGER_CAT

// AFTER_INS_TRIGGER_CAT
            .addExecutor(
                Base_NWL.AFTER_INS_TRIGGER_CAT,
                new AddCaseNoteExecutor_NWL ( Trigger.new, Base_NWL.AFTER_INS_TRIGGER_CAT )
            )
            .addExecutor(
                Base_NWL.AFTER_INS_TRIGGER_CAT,
                new OrderToCaseUpdExecutor_NWL ( Trigger.new,  Base_NWL.AFTER_INS_TRIGGER_CAT)
            )

// AFTER_UPD_TRIGGER_CAT

// AFTER_DEL_TRIGGER_CAT


        .execute();
}