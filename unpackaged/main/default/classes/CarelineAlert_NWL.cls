/**
 * CarelineAlert_NWL.cls
 *
 * Class to set Careline Alerts for Case product values
 *
 * @author: Harshal Gajare
 * @version: 1.0 - Initial Development
 *   		 2.0 - Complete redesign of the carline functionality.
 */
public with sharing class CarelineAlert_NWL implements Base_NWL.Executor {

    private List<Case_Product__c> newCpList;
    private static boolean isFirst = false;

    private static final String C_CARELINE = 'Careline';

	public CarelineAlert_NWL( List<Case_Product__c> newValList, Map<Id, Case_Product__c> oldValMap, Base_NWL.TriggerCategory cat ) {
        this.newCpList = newValList;
	    if( Test.isRunningTest() ){
	    	isFirst = false;
	    }
	}

	public void execute(){
	    System.debug( LoggingLevel.FINE, '--->>> CarelineAlert_NWL::execute() isFirst ' + isFirst );
	    if ( !isFirst ){
	      	isFirst = true;
	    }else{
	      	return;
	    }
	    List<Id> cpIdList = new List<Id>();
	    List<Id> prodIdList = new List<Id>();
		List<String> brandList = new List<String>();
		List<String> disp1List = new List<String>();
		List<String> disp2List = new List<String>();
		List<String> disp3List = new List<String>();
		List<String> disp4List = new List<String>();
		List<String> compositeKeyList = new List<String>();
		List<Case_Product__c> checkCarelineCpList = new List<Case_Product__c>();
		Map<String, CarelineAlertStat__c> keyStatMap = new Map<String, CarelineAlertStat__c>();
		Map<Id, CarelineAlert__c> cpToPQMap = new Map<Id, CarelineAlert__c>();
		Map<Id, CarelineAlert__c> cpToPSMap = new Map<Id, CarelineAlert__c>();
		Map<String, Map<String, Map<String, Map<String, Map<String, Product_Disposition__c>>>>> dpMap =
			new Map<String, Map<String, Map<String, Map<String, Map<String,Product_Disposition__c>>>>>();
// Check if careline alerts functionlaity is turned on.
		if( Utility_NWL.checkSwitch( C_CARELINE ) == true ){
			System.debug( LoggingLevel.FINE, 'CarelineAlert_NWL:Switch = ON' );
			for( Case_Product__c ncp : this.newCpList ){
// Check if record status is complete. 1 means complete.
				System.debug( LoggingLevel.FINE, 'ncp.RecordStatusCount__c : ' + ncp.RecordStatusCount__c );
				if( ncp.RecordStatusCount__c == 1 ){
					cpIdList.add(ncp.Id);
                    prodIdList.add( ncp.Product__c);
					brandList.add(ncp.Brand__c);
					compositeKeyList.add( ncp.Composite__c );
					disp1List.add(ncp.ProductDisposition1__c);
					disp2List.add(ncp.ProductDisposition2__c);
					disp3List.add(ncp.ProductDisposition3__c);
					disp4List.add(ncp.ProductDisposition4__c);
					checkCarelineCpList.add( ncp );
				}
			}
			System.debug( LoggingLevel.FINE, 'checkCarelineCpList.size() : ' + checkCarelineCpList.size() );

			if( !checkCarelineCpList.isEmpty() ){
				dpMap = this.buildDpMap( brandList, disp1List, disp2List, disp3List, disp4List );
			}
			System.debug( LoggingLevel.FINE, 'dpMap : ' + dpMap );
			System.debug( LoggingLevel.FINE, 'compositeKeyList : ' + compositeKeyList );

			for( CarelineAlert__c ca : [SELECT Id, CaseProduct__c, RecordType.Name FROM CarelineAlert__c WHERE CaseProduct__c IN: cpIdList ] ){
				if( ca.RecordType.Name == 'Potential Quality' ){
					cpToPQMap.put( ca.CaseProduct__c, ca );
				}else if( ca.RecordType.Name == 'Potential Safety' ){
					cpToPSMap.put( ca.CaseProduct__c, ca );
				}
			}

			for( CarelineAlertStat__c cas : [SELECT Id, Product__c, Composite__c, ProductDisposition1__c, ProductDisposition2__c,
												ProductDisposition3__c, ProductDisposition4__c, Counter__c
											FROM CarelineAlertStat__c
											WHERE Composite__c IN :compositeKeyList
                                                AND Product__c IN :prodIdList] ){
				keyStatMap.put( cas.Composite__c, cas );
			}
			System.debug( LoggingLevel.FINE, 'keyStatMap : ' + keyStatMap );

			for( Case_Product__c ncp : checkCarelineCpList ){
				Product_Disposition__c pd;
				if( ncp.NonSpecificSKU__c == true ){
					continue;
				}
				String status = '';
				String rt;
				Boolean checkPQ = true;
				try{
					pd = dpMap.get( ncp.Brand__c )
								.get( ncp.ProductDisposition1__c )
								.get( ncp.ProductDisposition2__c )
								.get( ncp.ProductDisposition3__c )
								.get( ncp.ProductDisposition4__c );
				}catch(Exception e){
					continue;
				}
				System.debug( LoggingLevel.FINE, 'pd : ' + pd );

				// Check is Careline Alert Parent Stat record exists
				CarelineAlertStat__c cas = keyStatMap.get( ncp.Composite__c );
				System.debug( LoggingLevel.FINE, 'cas : ' + cas );
				if( cas == null ){
					// No Careline Alert Parent Stat record exists
					// Create Careline Alert Parent Stat record
					cas = this.setCarelineAlertStat( ncp );
				}else if( cas != null && ncp.ChildCase__c == true){
					// No careline alert records should be generated for
					// child cases with same product and disposition as parent cases
					checkPQ = false;
				}
				if( checkPQ == true && String.isNotBlank( pd.CarelineOperator__c ) ){
					rt = 'Potential Quality';
// IF Yes create careline alert record
					if( cas.Counter__c != null ){
						System.debug( LoggingLevel.FINE, 'cas.Counter__c : ' + cas.Counter__c );
						if( pd.CarelineOperator__c == 'EQ'){
							if( pd.CarelineCount__c == ( cas.Counter__c + 1 ) ){
// Set alert in review
								status = 'In Review';
							}
						}else if( pd.CarelineOperator__c == 'GT'){
							if( pd.CarelineCount__c < ( cas.Counter__c + 1 ) ){
// Set alert in review
								status = 'In Review';
							}
						}else if( pd.CarelineOperator__c == 'LT'){
							if( pd.CarelineCount__c > ( cas.Counter__c + 1 ) ){
// Set alert in review
								status = 'In Review';
							}
						}
						if( String.isBlank( status) ){
// Set alert not in review
								status = 'Not For Review';
						}
						this.setCarelineAlerts( cas.Id, ncp, status, rt, cpToPQMap );
					}else{
						if( pd.CarelineOperator__c == 'EQ' && pd.CarelineCount__c == 1 ){
							status = 'In Review';
						}else if( pd.CarelineOperator__c == 'LT' && pd.CarelineCount__c > 1 ){
							status = 'In Review';
						}else{
							status = 'Not For Review';
						}
// Create careline alert record
						this.setCarelineAlerts( cas.Id, ncp, status, rt, cpToPQMap );
					}
				}
				if( ncp.Highlight__c == true ){
					status = 'In Review';
					rt = 'Potential Safety';
					this.setCarelineAlerts( cas.Id, ncp, status, rt, cpToPSMap );
				}
			}
		}else{
			System.debug( LoggingLevel.FINE, 'CarelineAlert_NWL:Switch = OFF' );
		}
	}
/**
 * Method to create careline alert Statistic records.
 * @param  bList
 * @param  d1List
 * @param  d2List
 * @param  d3List
 * @param  d4List
 * @return
 */
	private Map<String, Map<String, Map<String, Map<String, Map<String, Product_Disposition__c>>>>> buildDpMap(
					List<String> bList, List<String>d1List, List<String>d2List, List<String>d3List, List<String>d4List ){

		Map<String, Map<String, Map<String, Map<String, Map<String, Product_Disposition__c>>>>> dispositionMap =
			new Map<String, Map<String, Map<String, Map<String, Map<String,Product_Disposition__c>>>>>();

		System.debug( LoggingLevel.FINE, 'bList : ' + bList );
		System.debug( LoggingLevel.FINE, 'd1List : ' + d1List );
		System.debug( LoggingLevel.FINE, 'd2List : ' + d2List );
		System.debug( LoggingLevel.FINE, 'd3List : ' + d3List );
		System.debug( LoggingLevel.FINE, 'd4List : ' + d4List );

		for( Product_Disposition__c pd : [SELECT Id, Brand__r.Name, ProductDisposition1Text__c, ProductDisposition2Text__c,
												ProductDisposition3Text__c, ProductDisposition4Text__c, CarelineOperator__c, CarelineCount__c
											FROM Product_Disposition__c
											WHERE Brand__r.Name IN :bList
												AND ProductDisposition1Text__c IN :d1List
												AND ProductDisposition2Text__c IN :d2List
												AND ProductDisposition3Text__c IN :d3List
												AND ProductDisposition4Text__c IN :d4List ] ){

			String brand = pd.Brand__r.Name;

			if(!dispositionMap.containsKey(brand)) {
				dispositionMap.put(brand, new Map<String, Map<String, Map<String, Map<String, Product_Disposition__c>>>>());
			}
			Map<String, Map<String, Map<String, Map<String, Product_Disposition__c>>>> brandMap = dispositionMap.get(brand);

			if(!brandMap.containsKey(pd.ProductDisposition1Text__c)) {
				brandMap.put(pd.ProductDisposition1Text__c, new Map<String, Map<String, Map<String, Product_Disposition__c>>>());
			}

			Map<String, Map<String, Map<String, Product_Disposition__c>>> disp1Map = brandMap.get(pd.ProductDisposition1Text__c);

			if(!disp1Map.containsKey(pd.ProductDisposition2Text__c)) {
				disp1Map.put(pd.ProductDisposition2Text__c, new Map<String, Map<String, Product_Disposition__c>>());
			}

			Map<String, Map<String, Product_Disposition__c>> disp2Map = disp1Map.get(pd.ProductDisposition2Text__c);

			if(!disp2Map.containsKey(pd.ProductDisposition3Text__c)) {
				disp2Map.put(pd.ProductDisposition3Text__c, new Map<String, Product_Disposition__c>());
			}

			Map<String, Product_Disposition__c> disp3Map = disp2Map.get(pd.ProductDisposition3Text__c);

			if(!disp3Map.containsKey(pd.ProductDisposition4Text__c)) {
				disp3Map.put(pd.ProductDisposition4Text__c, pd);
			}
		}
		return dispositionMap;
	}
/**
 * Method to create careline alert Statistic records.
 * @param  cp
 * @return
 */
	private CarelineAlertStat__c setCarelineAlertStat( Case_Product__c cp ){
		CarelineAlertStat__c newCsa = new CarelineAlertStat__c(
			Product__c             = cp.Product__c,
			ProductDisposition1__c = cp.ProductDisposition1__c,
			ProductDisposition2__c = cp.ProductDisposition2__c,
			ProductDisposition3__c = cp.ProductDisposition3__c,
			ProductDisposition4__c = cp.ProductDisposition4__c
		);
		insert newCsa;
		return newCsa;
	}
/**
 * Method to create careline alert records.
 * @param  casId
 * @param  cp
 * @param  status
 * @param  rt
 * @param  cpToPQMap
 */
	private void setCarelineAlerts( Id casId, Case_Product__c cp, String status, String rt, Map<Id, CarelineAlert__c> cpToCaMap ){
		System.debug( LoggingLevel.FINE, 'status : ' + status );
		System.debug( LoggingLevel.FINE, 'rt : ' + rt );
		if( cpToCaMap != null ){
			CarelineAlert__c oldCa = cpToCaMap.get( cp.Id );
			if( oldCa != null ){
				return;
			}
		}

		CarelineAlert__c ca = new CarelineAlert__c(
			RecordTypeId         = Schema.SObjectType.CarelineAlert__c.RecordTypeInfosByName.get( rt ).RecordTypeId,
			CarelineAlertStat__c = casId,
			CaseProduct__c       = cp.Id,
			CaseId__c            = cp.Case__c,
			OriginalPD1__c       = cp.ProductDisposition1__c,
			OriginalPD2__c       = cp.ProductDisposition2__c,
			OriginalPD3__c       = cp.ProductDisposition3__c,
			OriginalPD4__c       = cp.ProductDisposition4__c,
			Status__c            = status
		);
		insert ca;
	}
}
//*********************************************** END OF CLASS *******************************************************//