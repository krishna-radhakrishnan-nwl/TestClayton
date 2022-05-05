trigger CaseCommentTrigger_NWL on CaseComment (after delete, after insert, after update,
                                    before delete, before insert, before update){
   (new Base_NWL.TriggerExecutionManager())
// BEFORE_INS_TRIGGER_CAT

        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new caseCommentSummary_NWL( trigger.new, Base_NWL.BEFORE_INS_TRIGGER_CAT)
        )



// BEFORE_UPD_TRIGGER_CAT

        

// AFTER_INS_TRIGGER_CAT

        
        .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new caseCommentSummary_NWL( trigger.new, Base_NWL.AFTER_INS_TRIGGER_CAT)
        )
     

// AFTER_UPD_TRIGGER_CAT


// AFTER_DEL_TRIGGER_CAT

        .execute();
}