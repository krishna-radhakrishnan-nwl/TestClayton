trigger AnnouncementTrigger_NWL on Announcement__c (before insert, before update) 
{
	(new Base_NWL.TriggerExecutionManager())
// BEFORE_UPD_TRIGGER_CAT
    .addExecutor(
        Base_NWL.BEFORE_UPD_TRIGGER_CAT,
        new UpdateConnectedUsersCountExecutor_NWL ( Trigger.new)    
    )
    .addExecutor(
        Base_NWL.BEFORE_UPD_TRIGGER_CAT,
        new AnnouncementValidationExecutor_NWL ( Trigger.new, Trigger.oldMap)    
    )
// BEFORE_INS_TRIGGER_CAT
    .addExecutor(
        Base_NWL.BEFORE_INS_TRIGGER_CAT,
        new UpdateConnectedUsersCountExecutor_NWL ( Trigger.new)  
    )
    .execute();
}