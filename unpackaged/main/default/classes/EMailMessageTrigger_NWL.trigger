trigger EMailMessageTrigger_NWL on EmailMessage (after delete, after insert, after update,
                                    before delete, before insert, before update) {
    (new Base_NWL.TriggerExecutionManager())
    //    BEFORE INSERT

    //    BEFORE DELETE  - SFDC-10490-Kumar K
         .addExecutor(
            Base_NWL.BEFORE_DEL_TRIGGER_CAT,
            new CaseEmailExecutor_NWL ( Trigger.newMap, Trigger.oldMap, Base_NWL.BEFORE_DEL_TRIGGER_CAT )
        )
                                        
    //    AFTER INSERT
         .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new CaseEmailExecutor_NWL ( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        )

    //    AFTER UPDATE
         .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new CaseEmailExecutor_NWL ( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT )
        )
    //    AFTER DELETE

        .execute();
}