/**
 * Trigger for End User Distributor when Insert new record
 */
trigger EUDistributor_NWL on End_User_Distributor__c (before insert) {

    (new Base_NWL.TriggerExecutionManager())
        .addExecutor( 
        	Base_NWL.BEFORE_INS_TRIGGER_CAT,
        	new EUDistributorExecutor_NWL( Trigger.new )
        )
        .execute(); 
}