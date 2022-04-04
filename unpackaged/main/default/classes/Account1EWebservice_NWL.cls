/**
 * 1E Account WebService 
* 
* @author: Syed Jaffar
*/
global class Account1EWebservice_NWL {

//  Return messages
	private static final String C_SUCCESS = 'Success : ';
    private static final String C_FAILURE = 'Failure : ';	

/**
 * Upadte 1E Account
 */
	webservice static String update1EAccount(String sapAccountNo, String oldUserID, String newUserID){
		
		String result;

		System.debug( 'Account1EWebservice_NWL::update1EAccount::sapAccountNo {' + sapAccountNo +'}' );
		System.debug( 'Account1EWebservice_NWL::update1EAccount::oldUserID {' + oldUserID +'}' );
		System.debug( 'Account1EWebservice_NWL::update1EAccount::newUserID {' + newUserID +'}' );

		if(sapAccountNo !=null && sapAccountNo !=''){
			List<Account> aList = [Select Id, SAP_Account_Num__c, Newell_ID__c FROM 
												Account WHERE SAP_Account_Num__c = :sapAccountNo LIMIT 1 ];
			for(Account a:aList){
				a.Newell_ID__c = newUserID;
			}
			try{
        		upsert aList;
            	result = C_SUCCESS + sapAccountNo + ' : 1E Account Object updated';
            } catch( DMLException de ){
            	result = C_FAILURE + sapAccountNo + ' : 1E Account Object updated : ' + de.getMessage();
            }
		}else{ 
			result = C_FAILURE + ' Invalid SAP Account Number : ' + sapAccountNo ;  
		} 

		System.debug( 'Account1EWebservice_NWL::update1EAccount::result {' + result + '}');
		System.debug( 'Account1EWebservice_NWL::update1EAccount::result {' + result + '}');
		return result;
	}
}
