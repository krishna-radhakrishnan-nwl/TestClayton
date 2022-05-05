trigger FamilyTrigger_NWL on Family__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

	   (new Base_NWL.TriggerExecutionManager())
// BEFORE_INS_TRIGGER_CAT
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new FamilyFormatExecutor_NWL( Trigger.new, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        )
// BEFORE_UPD_TRIGGER_CAT
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new FamilyFormatExecutor_NWL( Trigger.new, Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        )
// BEFORE_DEL_TRIGGER_CAT


// AFTER_INS_TRIGGER_CAT

// AFTER_UPD_TRIGGER_CAT
//
// AFTER_DEL_TRIGGER_CAT

        .execute();
}