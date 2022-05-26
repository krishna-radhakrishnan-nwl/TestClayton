trigger CampaignRegistrationItemsTrigger_NWL on CampaignRegistrationItems__c ( after delete, after insert, after update,
                                       			 					before delete, before insert, before update){

    (new Base_NWL.TriggerExecutionManager())
// BEFORE_INS_TRIGGER_CAT
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new CalculateCashback_NWL( Trigger.new, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        )
// BEFORE_UPD_TRIGGER_CAT
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new CalculateCashback_NWL( Trigger.new, Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        )
// BEFORE_DEL_TRIGGER_CAT

// AFTER_INS_TRIGGER_CAT

// AFTER_UPD_TRIGGER_CAT

// AFTER_DEL_TRIGGER_CAT

        .execute();
}