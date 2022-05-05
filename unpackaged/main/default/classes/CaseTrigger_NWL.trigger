trigger CaseTrigger_NWL on Case (after delete, after insert, after update,
                                    before delete, before insert, before update){
   (new Base_NWL.TriggerExecutionManager())
// BEFORE_INS_TRIGGER_CAT
        //.addExecutor(
        //    Base_NWL.BEFORE_INS_TRIGGER_CAT,
        //    new CaseStrategicAccountExecutor_NWL( Trigger.new, Base_NWL.AFTER_INS_TRIGGER_CAT )
        //)
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new CaseAssignExecutor_NWL( Trigger.new, Trigger.oldMap, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        )
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new CaseDefaultUser_NWL( Trigger.new, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        )
        .addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new HRCaseAutomations_GS( Trigger.new, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        ).addExecutor(
            Base_NWL.BEFORE_INS_TRIGGER_CAT,
            new HRClientServices_CaseOriginator_GS( Trigger.new )
        )   
        //.addExecutor(
        //    Base_NWL.BEFORE_INS_TRIGGER_CAT,
        //    new CaseProductTypeSetExecutor_NWL( Trigger.new, null, null, Base_NWL.BEFORE_INS_TRIGGER_CAT )
        //)

// BEFORE_UPD_TRIGGER_CAT
        //.addExecutor(
        //    Base_NWL.BEFORE_UPD_TRIGGER_CAT,
        //    new CaseStrategicAccountExecutor_NWL( Trigger.new, Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        //)
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new CaseAssignExecutor_NWL( Trigger.new, Trigger.oldMap, Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        )
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new CaseSapNotesExecutor_NWL( Trigger.newMap, Trigger.oldMap, Trigger.new )
        )
        .addExecutor(
            Base_NWL.BEFORE_UPD_TRIGGER_CAT,
            new HRCase_updateCaseValidationStatus_GS( Trigger.new, Trigger.oldMap)
        )
        
        //.addExecutor(
        //    Base_NWL.BEFORE_UPD_TRIGGER_CAT,
        //    new CaseProductTypeSetExecutor_NWL( null, Trigger.newMap, Trigger.oldMap,Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        //)
        //.addExecutor(
        //    Base_NWL.BEFORE_UPD_TRIGGER_CAT,
        //    new CaseSendSurveyExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.BEFORE_UPD_TRIGGER_CAT )
        //)

// AFTER_INS_TRIGGER_CAT
        //.addExecutor(
        //    Base_NWL.AFTER_INS_TRIGGER_CAT,
        //    new CasePointExecutor_NWL( trigger.new, Trigger.newMap, Trigger.oldMap , Base_NWL.AFTER_INS_TRIGGER_CAT)
        //)
        //.addExecutor(
        //    Base_NWL.AFTER_INS_TRIGGER_CAT,
        //    new ProductOnCaseExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT )
        //)
        .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new RiskCaseCountExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT)
        )
        .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new RiskCaseNotificationExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT)
        )
        .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new GTONotificationExecutor_NWL( Trigger.new, Trigger.oldMap )
        )
        .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new HRClientServices_CaseAssignment_GS( Trigger.new )
        )
        .addExecutor(
            Base_NWL.AFTER_INS_TRIGGER_CAT,
            new HRCase_AddTeamMembers_GS( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_INS_TRIGGER_CAT)
        )        

// AFTER_UPD_TRIGGER_CAT
        //.addExecutor(
        //    Base_NWL.AFTER_UPD_TRIGGER_CAT,
        //    new CasePointExecutor_NWL( Trigger.new, Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT )
        //)
        //.addExecutor(
        //    Base_NWL.AFTER_UPD_TRIGGER_CAT,
        //    new ProductOnCaseExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT )
        //)
        .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new CaseTaskOwnershipExecutor_NWL( Trigger.newMap, Trigger.oldMap )
        )
        //.addExecutor(
        //    Base_NWL.AFTER_UPD_TRIGGER_CAT,
        //    new CaseSendSurveyExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT )
        //)
        .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new RiskCaseCountExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT)
        )
        .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new CaseBrandExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT)
        )
        .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new RiskCaseNotificationExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT)
        )
        .addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new GTONotificationExecutor_NWL( Trigger.new, Trigger.oldMap )
        ).addExecutor(
            Base_NWL.AFTER_UPD_TRIGGER_CAT,
            new HRCase_AddTeamMembers_GS( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT)
        )
// AFTER_DEL_TRIGGER_CAT
        //.addExecutor(
        //    Base_NWL.AFTER_DEL_TRIGGER_CAT,
        //    new ProductOnCaseExecutor_NWL( Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_DEL_TRIGGER_CAT )
        //)
        .execute();
}