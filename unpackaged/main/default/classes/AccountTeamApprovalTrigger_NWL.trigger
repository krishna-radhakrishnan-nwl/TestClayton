/**
 * Account Team Approval Trigger
 */
trigger AccountTeamApprovalTrigger_NWL on Account_Team_Approval__c (after delete, after insert, after update, 
									before delete, before insert, before update) {

    (new Base_NWL.TriggerExecutionManager())
        .addExecutor( 
            Base_NWL.AFTER_UPD_TRIGGER_CAT, 
            new AccountTeamApprovalExecutor_NWL(Trigger.newMap, Trigger.oldMap, Base_NWL.AFTER_UPD_TRIGGER_CAT) 
        )
    .execute();   
    
}