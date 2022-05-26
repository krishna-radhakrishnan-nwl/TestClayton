trigger RegistrationTrigger_NWL on Registration__c (after delete, after insert, after update,
                                    before delete, before insert, before update) {
    (new Base_NWL.TriggerExecutionManager())
    //    BEFORE INSERT

        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new RegistrationSummary_NWL ( Trigger.new, Trigger.old, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        )

    //    BEFORE UPDATE

        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new RegistrationSummary_NWL ( Trigger.new, Trigger.old, Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        )

    //    AFTER INSERT
		.addExecutor(
        	Base_NWL.AFTER_INS_TRIGGER_CAT,
            new RegistrationEmailOptIn_NWL ( Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        )

    //    AFTER UPDATE

         .addExecutor(
        	Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new RegistrationEmailOptIn_NWL ( Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT )
        )

    //    AFTER DELETE

        .execute();
}