trigger AttachmentTrigger_NWL on Attachment (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

   (new Base_NWL.TriggerExecutionManager())
// BEFORE_INS_TRIGGER_CAT

// BEFORE_UPD_TRIGGER_CAT

// AFTER_INS_TRIGGER_CAT
        .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new MoveUpsLabelToCase_NWL( Trigger.new, Base_NWL.AFTER_INS_TRIGGER_CAT )
        )
// AFTER_UPD_TRIGGER_CAT

        .execute();
}