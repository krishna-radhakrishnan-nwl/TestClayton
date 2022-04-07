/**
 * 1E Account WebService Test Class
* 
* @author: Syed Jaffar
*/
@isTest
private class Account1EWebservice_NWL_T {
	
	private static final String ACCOUNT_NAME_PREFIX = '01-0001 WAL*MART SUPERCENTER';
	private static final String SHIP_COUNTRY_PREFIX = 'United States';
	private static final String NEW_NEWELL_ID       = 'XX1234';
	private static final String SAP_ACCOUNT_NO      = '875150';

	@isTest 
	static void positiveTest() {
		GenerateTestData_NWL_T genTestData = new GenerateTestData_NWL_T();
		genTestData.usrNwlIdPrifix = 'AB1234';
		genTestData.accSAP = '675150';
		
		System.test.startTest();	
			Account account = genTestData.account( 1, ACCOUNT_NAME_PREFIX, SHIP_COUNTRY_PREFIX, 'S')[0];
		    String result = Account1EWebservice_NWL.update1EAccount(account.SAP_Account_Num__c, account.Newell_ID__c, NEW_NEWELL_ID);
	    	System.debug('--->> firstTest::result [' +result+']');
	    	List<Account> aList = [Select Id, SAP_Account_Num__c, Newell_ID__c FROM 
													Account WHERE Newell_ID__c = :NEW_NEWELL_ID LIMIT 1 ];
			System.assert(aList.size() == 1);
		System.test.stopTest();
		List<Account> accList = [Select Id,Name From Account Limit 100];
	}
	
	@isTest 
	static void negativeTest() {
		GenerateTestData_NWL_T genTestData = new GenerateTestData_NWL_T();
		genTestData.usrNwlIdPrifix = 'AB1234';
		genTestData.accSAP = '675150';

		System.test.startTest();	
			Account account = genTestData.account( 1, ACCOUNT_NAME_PREFIX, SHIP_COUNTRY_PREFIX, 'S')[0];
		    String result = Account1EWebservice_NWL.update1EAccount(SAP_ACCOUNT_NO, account.Newell_ID__c, NEW_NEWELL_ID);
	    	System.debug('--->> firstTest::result [' +result+']');
	    	List<Account> aList = [Select Id, SAP_Account_Num__c, Newell_ID__c FROM 
													Account WHERE Newell_ID__c = :NEW_NEWELL_ID LIMIT 1 ];
			System.assert(aList.size() == 0);
		System.test.stopTest();
	}
	
	@isTest 
	static void nullSAPAccountTest() {
		GenerateTestData_NWL_T genTestData = new GenerateTestData_NWL_T();
		genTestData.usrNwlIdPrifix = 'AB1234';
		genTestData.accSAP = '675150';

		System.test.startTest();	
			Account account = genTestData.account( 1, ACCOUNT_NAME_PREFIX, SHIP_COUNTRY_PREFIX, 'S')[0];
		    String result = Account1EWebservice_NWL.update1EAccount(null, account.Newell_ID__c, NEW_NEWELL_ID);
	    	System.debug('--->> firstTest::result [' +result+']');
	    	List<Account> aList = [Select Id, SAP_Account_Num__c, Newell_ID__c FROM 
													Account WHERE Newell_ID__c = :NEW_NEWELL_ID LIMIT 1 ];
			System.assert(aList.size() == 0);
		System.test.stopTest();
	}

}
