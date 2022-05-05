@isTest
private class CarelineAlert_NWL_T {

    @testSetup
    private static void commonTestDataSetup(){
    	GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();
//  Set Careline to True.
		g.globalSwitchSettings('Careline', true );
// Generate Test Cases
		g.rtSettings( 'Repair' , 'Case', 'Consumer' );
		g.csRecordType = 'Repair';
    	List<Case> csList = g.case(2, 'Open', 'Test Careline', 'Manual', 'Other', 'DYMO' );
    	System.assertEquals( 2, csList.size() );
// Generate Products
		g.prodRecTyId = Schema.SObjectType.Product2.RecordTypeInfosByName.get('SAP Product').RecordTypeId;
    	List<Product2> pList = g.productData(2, 'Test_Prod_');
    	System.assertEquals( 2, pList.size() );
// Generate Master Values.
		List<Master_Value__c> mvList = new List<Master_Value__c>();
		for( Integer i=1; i<=4; i++){
			for( Integer j=1; j<=4; j++){
				Master_Value__c m = new Master_Value__c(
					RecordTypeId = Schema.SObjectType.Master_Value__c.RecordTypeInfosByName.get('Product Disposition ' + i).RecordTypeId,
					Value__c = 'PD' + i + '_' + j
				);
				mvList.add( m );
			}
		}
		if( !mvList.isEmpty() ){
			insert mvList;
		}
		Map<String, Id> mvValueToIdMap = new Map<String, Id>();
		for( Master_Value__c mv : [SELECT Id, Record_Type_Label__c , Value__c FROM Master_Value__c ORDER BY Record_Type_Label__c ] ){
			mvValueToIdMap.put( mv.Value__c, mv.Id );
		}
		System.assertEquals( 16, mvValueToIdMap.size() );
// Generate Brand value
		Brand__c b = g.brand( 'DYMO');
		System.assertNotEquals( null, b.Id );
		List<Product_Disposition__c> pdList = new List<Product_Disposition__c>();
// Generate Product Dispostions
// Product Dispostion with Careline Alerts = 2
		pdList.add(  new Product_Disposition__c(
			Brand__c               = b.Id,
			ProductDisposition1__c = mvValueToIdMap.get( 'PD1_1' ),
			ProductDisposition2__c = mvValueToIdMap.get( 'PD2_1' ),
			ProductDisposition3__c = mvValueToIdMap.get( 'PD3_1' ),
			ProductDisposition4__c = mvValueToIdMap.get( 'PD4_1' ),
			IsActive__c            = true,
			CarelineOperator__c    = 'EQ',
			CarelineCount__c       = 2
		));
// Product Dispostion with Careline Alerts > 2
		pdList.add(  new Product_Disposition__c(
			Brand__c               = b.Id,
			ProductDisposition1__c = mvValueToIdMap.get( 'PD1_2' ),
			ProductDisposition2__c = mvValueToIdMap.get( 'PD2_2' ),
			ProductDisposition3__c = mvValueToIdMap.get( 'PD3_2' ),
			//ProductDisposition4__c = mvValueToIdMap.get( 'PD4_2' ),
			IsActive__c            = true,
			CarelineOperator__c    = 'GT',
			CarelineCount__c       = 2
		));
// Product Dispostion with Careline Alerts < 2
		pdList.add(  new Product_Disposition__c(
			Brand__c               = b.Id,
			ProductDisposition1__c = mvValueToIdMap.get( 'PD1_3' ),
			ProductDisposition2__c = mvValueToIdMap.get( 'PD2_3' ),
			//ProductDisposition3__c = mvValueToIdMap.get( 'PD3_3' ),
			//ProductDisposition4__c = mvValueToIdMap.get( 'PD4_3' ),
			IsActive__c            = true,
			CarelineOperator__c    = 'LT',
			CarelineCount__c       = 2
		));
// Product Dispostion with NO Careline Alerts
		pdList.add(  new Product_Disposition__c(
			Brand__c               = b.Id,
			ProductDisposition1__c = mvValueToIdMap.get( 'PD1_4' ),
			ProductDisposition2__c = mvValueToIdMap.get( 'PD2_4' ),
			ProductDisposition3__c = mvValueToIdMap.get( 'PD3_4' ),
			//ProductDisposition4__c = mvValueToIdMap.get( 'PD4_4' ),
			IsActive__c            = true
		));
		if( !pdList.isEmpty() ){
			insert pdList;
		}
		System.assertEquals(4, pdList.size() );
    }

//	@isTest
//	static void shouldCreateCarelineEq2(){
//		List<Case_Product__c> cpList = new List<Case_Product__c>();
//		List<CarelineAlertStat__c> casList = new List<CarelineAlertStat__c>();
//		List<CarelineAlert__c> caList = new List<CarelineAlert__c>();

//		List<Case> csList = [SELECT Id FROM Case ORDER BY CreatedDate ];
//		System.assertEquals( 2, csList.size() );
//		Map<String, Id> prodNameToIdMap = new Map<String, Id>();
//		for( Product2 p : [SELECT Id, Name FROM Product2 ] ){
//			prodNameToIdMap.put( p.Name , p.Id );
//		}
//		System.assertEquals(2, prodNameToIdMap.size() );

//		List<Case_Product__c> newCpList = new List<Case_Product__c>();
//		for( Integer i=1; i<=4; i++){
//			newCpList.add( new Case_Product__c(
//							Case__c = csList[0].Id,
//							Product__c = prodNameToIdMap.get( 'Test_Prod_0' )
//						));
//		}
//		insert newCpList;

//		cpList = CarelineAlert_NWL_T.getCaseProductData();
//		System.assertEquals( 4, cpList.size() );
//		System.assertEquals( csList[0].Id, cpList[0].Case__c );
//		System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), cpList[0].Product__c );
//		System.assertEquals( 0, cpList[0].RecordStatusCount__c );
//		System.assertEquals( null, cpList[0].ProductDisposition1__c );
//		System.assertEquals( null, cpList[0].ProductDisposition2__c );
//		System.assertEquals( null, cpList[0].ProductDisposition3__c );
//		System.assertEquals( null, cpList[0].ProductDisposition4__c );
//		System.assertEquals( null, cpList[0].Under_Warranty__c );
//		System.assertEquals( false, cpList[0].Highlight__c );

//		System.assertEquals( newCpList[0].Id, cpList[0].Id );
//		Test.startTest();
//// Update 1st case product with Product Disposition Values
//			cpList[0].ProductDisposition1__c = 'PD1_1';
//			cpList[0].ProductDisposition2__c = 'PD2_1';
//			cpList[0].ProductDisposition3__c = 'PD3_1';
//			cpList[0].ProductDisposition4__c = 'PD4_1';
//			cpList[0].Under_Warranty__c = 'Under Warranty';
//			update cpList[0];
//// Check Case Product is correctly udpated
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[0].Id, cpList[0].Id );
//			System.assertEquals( 1, cpList[0].RecordStatusCount__c );
//			System.assertEquals( 'PD1_1', cpList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_1', cpList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_1', cpList[0].ProductDisposition3__c );
//			System.assertEquals( 'PD4_1', cpList[0].ProductDisposition4__c );
//			System.assertEquals( 'Under Warranty', cpList[0].Under_Warranty__c );
//			System.assertEquals( false, cpList[0].Highlight__c );
//// Check Careline Stat record is crated correctly.
//// Careline Alert Stat record should be created as there is no existing records
//// for this product and disposition combinations.
//// The counter should be 1 as there should only be 1 alert record tied to this
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_1', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_1', casList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_1', casList[0].ProductDisposition3__c );
//			System.assertEquals( 'PD4_1', casList[0].ProductDisposition4__c );
//			System.assertEquals( 1, casList[0].Counter__c );
//// Check Careline Alert record is crated correctly.
//// Careline Alert for Potential Quality should be created. As this is the first occurence and the alerts are set to be
//// triggered for EQ 2 the record created should be with Status "Not For Review". The record type should be Potential
//// Quality and tied back to the parent stat record .
//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 1, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[0].RecordType.Name );
//			System.assertEquals( 'Not For Review', caList[0].Status__c );
//			System.assertEquals( 'PD1_1', caList[0].OriginalPD1__c );
//			System.assertEquals( 'PD2_1', caList[0].OriginalPD2__c );
//			System.assertEquals( 'PD3_1', caList[0].OriginalPD3__c );
//			System.assertEquals( 'PD4_1', caList[0].OriginalPD4__c );
//			System.assertEquals( casList[0].Id, caList[0].CarelineAlertStat__c );

//// Update 2nd case product with Product Disposition Values
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[1].Id, cpList[1].Id );

//			cpList[1].ProductDisposition1__c = 'PD1_1';
//			cpList[1].ProductDisposition2__c = 'PD2_1';
//			cpList[1].ProductDisposition3__c = 'PD3_1';
//			cpList[1].ProductDisposition4__c = 'PD4_1';
//			cpList[1].Under_Warranty__c = 'Under Warranty';
//			update cpList[1];

//// Check Case Product is correctly udpated
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[1].Id, cpList[1].Id );
//			System.assertEquals( 1, cpList[1].RecordStatusCount__c );
//			System.assertEquals( 'PD1_1', cpList[1].ProductDisposition1__c );
//			System.assertEquals( 'PD2_1', cpList[1].ProductDisposition2__c );
//			System.assertEquals( 'PD3_1', cpList[1].ProductDisposition3__c );
//			System.assertEquals( 'PD4_1', cpList[1].ProductDisposition4__c );
//			System.assertEquals( 'Under Warranty', cpList[1].Under_Warranty__c );
//			System.assertEquals( false, cpList[1].Highlight__c );

//// Check Careline Stat record is crated correctly.
//// No new Careline stat record should be created and there should be only 1 from the earlier case product record.
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_1', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_1', casList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_1', casList[0].ProductDisposition3__c );
//			System.assertEquals( 'PD4_1', casList[0].ProductDisposition4__c );
//			System.assertEquals( 1, casList[0].Counter__c );

//// Check Careline Alert record is crated correctly.
//// Careline Alert for Potential Quality should be created. As this is the Seond occurence and the alerts are set to be
//// triggered for EQ 2 the record created should be with Status "In Review". Record should be tied back to the
//// parent stat record .
//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 2, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[1].RecordType.Name );
//			System.assertEquals( 'In Review', caList[1].Status__c );
//			System.assertEquals( 'PD1_1', caList[1].OriginalPD1__c );
//			System.assertEquals( 'PD2_1', caList[1].OriginalPD2__c );
//			System.assertEquals( 'PD3_1', caList[1].OriginalPD3__c );
//			System.assertEquals( 'PD4_1', caList[1].OriginalPD4__c );
//			System.assertEquals( casList[0].Id, caList[1].CarelineAlertStat__c );

//// Update 3rd case product with Product Disposition Values
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[2].Id, cpList[2].Id );

//			cpList[2].ProductDisposition1__c = 'PD1_1';
//			cpList[2].ProductDisposition2__c = 'PD2_1';
//			cpList[2].ProductDisposition3__c = 'PD3_1';
//			cpList[2].ProductDisposition4__c = 'PD4_1';
//			cpList[2].Under_Warranty__c = 'Under Warranty';
//			update cpList[2];

//// Check Case Product is correctly udpated
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[2].Id, cpList[2].Id );
//			System.assertEquals( 1, cpList[2].RecordStatusCount__c );
//			System.assertEquals( 'PD1_1', cpList[2].ProductDisposition1__c );
//			System.assertEquals( 'PD2_1', cpList[2].ProductDisposition2__c );
//			System.assertEquals( 'PD3_1', cpList[2].ProductDisposition3__c );
//			System.assertEquals( 'PD4_1', cpList[2].ProductDisposition4__c );
//			System.assertEquals( 'Under Warranty', cpList[2].Under_Warranty__c );
//			System.assertEquals( false, cpList[2].Highlight__c );

//// Check Careline Stat record is crated correctly.
//// No new Careline stat record should be created and there should still be only 1 from the earlier case product record
//// as In Review/Ignored records don't count as alerts
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_1', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_1', casList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_1', casList[0].ProductDisposition3__c );
//			System.assertEquals( 'PD4_1', casList[0].ProductDisposition4__c );
//			System.assertEquals( 1, casList[0].Counter__c );

//// Check Careline Alert record is crated correctly.
//// Careline Alert for Potential Quality should be created. This careline alert record should also get created with In Review status
//// as the earlier record was still "In Review" and no action was taken.  Record should be tied back to parent stat record
//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 3, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[2].RecordType.Name );
//			System.assertEquals( 'In Review', caList[2].Status__c );
//			System.assertEquals( 'PD1_1', caList[2].OriginalPD1__c );
//			System.assertEquals( 'PD2_1', caList[2].OriginalPD2__c );
//			System.assertEquals( 'PD3_1', caList[2].OriginalPD3__c );
//			System.assertEquals( 'PD4_1', caList[2].OriginalPD4__c );
//			System.assertEquals( casList[0].Id, caList[2].CarelineAlertStat__c );

//// Update 1st In Review careline to Ignored.
//			caList[1].Status__c = 'Ignored';
//// Update 2nd In Review careline to Escalated.
//			caList[2].PotentialQualityEmail__c = 'a@b.com';
//			caList[2].Status__c = 'Escalated';
//			update caList;

//// Check Careline Stat record is crated correctly.
//// The count should now be set to 2 on the stat record as there are 2 valid alerts.
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_1', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_1', casList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_1', casList[0].ProductDisposition3__c );
//			System.assertEquals( 'PD4_1', casList[0].ProductDisposition4__c );
//			System.assertEquals( 2, casList[0].Counter__c );

//// Update 3rd case product with Product Disposition Values
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[3].Id, cpList[3].Id );

//			cpList[3].ProductDisposition1__c = 'PD1_1';
//			cpList[3].ProductDisposition2__c = 'PD2_1';
//			cpList[3].ProductDisposition3__c = 'PD3_1';
//			cpList[3].ProductDisposition4__c = 'PD4_1';
//			cpList[3].Under_Warranty__c = 'Under Warranty';
//			update cpList[3];

//// Check Careline Stat record is crated correctly.
//// The count should be set to 3 on the stat record as there are 3 valid alerts and there can be more
//// alerts for this product and disp combination.
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_1', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_1', casList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_1', casList[0].ProductDisposition3__c );
//			System.assertEquals( 'PD4_1', casList[0].ProductDisposition4__c );
//			System.assertEquals( 3, casList[0].Counter__c );

//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 4, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[3].RecordType.Name );
//			System.assertEquals( 'Not For Review', caList[3].Status__c );
//			System.assertEquals( 'PD1_1', caList[3].OriginalPD1__c );
//			System.assertEquals( 'PD2_1', caList[3].OriginalPD2__c );
//			System.assertEquals( 'PD3_1', caList[3].OriginalPD3__c );
//			System.assertEquals( 'PD4_1', caList[3].OriginalPD4__c );
//			System.assertEquals( casList[0].Id, caList[3].CarelineAlertStat__c );

//		Test.stopTest();
//	}

//	@isTest
//	static void shouldCreateCarelineGT2(){
//		List<Case_Product__c> cpList = new List<Case_Product__c>();
//		List<CarelineAlertStat__c> casList = new List<CarelineAlertStat__c>();
//		List<CarelineAlert__c> caList = new List<CarelineAlert__c>();

//		List<Case> csList = [SELECT Id FROM Case ORDER BY CreatedDate ];
//		System.assertEquals( 2, csList.size() );
//		Map<String, Id> prodNameToIdMap = new Map<String, Id>();
//		for( Product2 p : [SELECT Id, Name FROM Product2 ] ){
//			prodNameToIdMap.put( p.Name , p.Id );
//		}
//		System.assertEquals(2, prodNameToIdMap.size() );

//		List<Case_Product__c> newCpList = new List<Case_Product__c>();
//		for( Integer i=1; i<=4; i++){
//			newCpList.add( new Case_Product__c(
//							Case__c = csList[0].Id,
//							Product__c = prodNameToIdMap.get( 'Test_Prod_0' )
//						));
//		}
//		insert newCpList;

//		cpList = CarelineAlert_NWL_T.getCaseProductData();
//		System.assertEquals( 4, cpList.size() );
//		System.assertEquals( csList[0].Id, cpList[0].Case__c );
//		System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), cpList[0].Product__c );
//		System.assertEquals( 0, cpList[0].RecordStatusCount__c );
//		System.assertEquals( null, cpList[0].ProductDisposition1__c );
//		System.assertEquals( null, cpList[0].ProductDisposition2__c );
//		System.assertEquals( null, cpList[0].ProductDisposition3__c );
//		System.assertEquals( null, cpList[0].ProductDisposition4__c );
//		System.assertEquals( null, cpList[0].Under_Warranty__c );
//		System.assertEquals( false, cpList[0].Highlight__c );

//		Test.startTest();
//// Update 1st case product with Product Disposition Values
//			cpList[0].ProductDisposition1__c = 'PD1_2';
//			cpList[0].ProductDisposition2__c = 'PD2_2';
//			cpList[0].ProductDisposition3__c = 'PD3_2';
//			cpList[0].Under_Warranty__c = 'Under Warranty';
//			update cpList[0];
//// Check Case Product is correctly udpated
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[0].Id, cpList[0].Id );
//			System.assertEquals( 1, cpList[0].RecordStatusCount__c );
//			System.assertEquals( 'PD1_2', cpList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_2', cpList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_2', cpList[0].ProductDisposition3__c );
//			System.assertEquals( 'Under Warranty', cpList[0].Under_Warranty__c );
//			System.assertEquals( false, cpList[0].Highlight__c );
//// Check Careline Stat record is crated correctly.
//// Careline Alert Stat record should be created as there is no existing records
//// for this product and disposition combinations.
//// The counter should be 1 as there should only be 1 alert record tied to this
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_2', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_2', casList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_2', casList[0].ProductDisposition3__c );
//			System.assertEquals( 1, casList[0].Counter__c );
//// Check Careline Alert record is crated correctly.
//// Careline Alert for Potential Quality should be created. As this is the first occurence and the alerts are set to be
//// triggered for GT 2 the record created should be with Status "Not For Review". The record type should be Potential
//// Quality and tied back to the parent stat record
//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 1, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[0].RecordType.Name );
//			System.assertEquals( 'Not For Review', caList[0].Status__c );
//			System.assertEquals( 'PD1_2', caList[0].OriginalPD1__c );
//			System.assertEquals( 'PD2_2', caList[0].OriginalPD2__c );
//			System.assertEquals( 'PD3_2', caList[0].OriginalPD3__c );
//			System.assertEquals( casList[0].Id, caList[0].CarelineAlertStat__c );

//// Update 2nd case product with Product Disposition Values
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[1].Id, cpList[1].Id );

//			cpList[1].ProductDisposition1__c = 'PD1_2';
//			cpList[1].ProductDisposition2__c = 'PD2_2';
//			cpList[1].ProductDisposition3__c = 'PD3_2';
//			cpList[1].Under_Warranty__c = 'Under Warranty';
//			update cpList[1];

//// Check Case Product is correctly udpated
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[1].Id, cpList[1].Id );
//			System.assertEquals( 1, cpList[1].RecordStatusCount__c );
//			System.assertEquals( 'PD1_2', cpList[1].ProductDisposition1__c );
//			System.assertEquals( 'PD2_2', cpList[1].ProductDisposition2__c );
//			System.assertEquals( 'PD3_2', cpList[1].ProductDisposition3__c );
//			System.assertEquals( 'Under Warranty', cpList[1].Under_Warranty__c );
//			System.assertEquals( false, cpList[1].Highlight__c );

//// Check Careline Stat record is crated correctly.
//// No new Careline stat record should be created and there should be only 1 from the earlier case product record.
//// the count for the number of careline alerts should now be 2 as new record is created.
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_2', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_2', casList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_2', casList[0].ProductDisposition3__c );
//			System.assertEquals( 2, casList[0].Counter__c );

//// Check Careline Alert record is crated correctly.
//// Careline Alert for Potential Quality should be created. As this is the Seond occurence and the alerts are set to be
//// triggered for GT 2 the record created should be with Status "Not For Review". Record should be tied back to the
//// parent stat record .
//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 2, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[1].RecordType.Name );
//			System.assertEquals( 'Not For Review', caList[1].Status__c );
//			System.assertEquals( 'PD1_2', caList[1].OriginalPD1__c );
//			System.assertEquals( 'PD2_2', caList[1].OriginalPD2__c );
//			System.assertEquals( 'PD3_2', caList[1].OriginalPD3__c );
//			System.assertEquals( casList[0].Id, caList[1].CarelineAlertStat__c );

//// Update 3rd case product with Product Disposition Values
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[2].Id, cpList[2].Id );

//			cpList[2].ProductDisposition1__c = 'PD1_2';
//			cpList[2].ProductDisposition2__c = 'PD2_2';
//			cpList[2].ProductDisposition3__c = 'PD3_2';
//			cpList[2].Under_Warranty__c = 'Under Warranty';
//			update cpList[2];

//// Check Case Product is correctly udpated
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[2].Id, cpList[2].Id );
//			System.assertEquals( 1, cpList[2].RecordStatusCount__c );
//			System.assertEquals( 'PD1_2', cpList[2].ProductDisposition1__c );
//			System.assertEquals( 'PD2_2', cpList[2].ProductDisposition2__c );
//			System.assertEquals( 'PD3_2', cpList[2].ProductDisposition3__c );
//			System.assertEquals( 'Under Warranty', cpList[2].Under_Warranty__c );
//			System.assertEquals( false, cpList[2].Highlight__c );

//// Check Careline Stat record is crated correctly.
//// No new Careline stat record should be created and there should still be only 1 from the earlier case product record
//// as In Review/Ignored records don't count as alerts
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_2', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_2', casList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_2', casList[0].ProductDisposition3__c );
//			System.assertEquals( 2, casList[0].Counter__c );

//// Check Careline Alert record is crated correctly.
//// Careline Alert for Potential Quality should be created. As this is the Seond occurence and the alerts are set to be
//// triggered for GT 2 the record created should be with Status "In Review". Record should be tied back to the
//// parent stat record.
//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 3, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[2].RecordType.Name );
//			System.assertEquals( 'In Review', caList[2].Status__c );
//			System.assertEquals( 'PD1_2', caList[2].OriginalPD1__c );
//			System.assertEquals( 'PD2_2', caList[2].OriginalPD2__c );
//			System.assertEquals( 'PD3_2', caList[2].OriginalPD3__c );
//			System.assertEquals( casList[0].Id, caList[2].CarelineAlertStat__c );

//// Set Careline alert record to Ignored status. Ignored records do not count towards valid status. Next Careline alert
//// record that will be created should still be In Review status.
//			caList[2].Status__c = 'Ignored';
//			update caList[2];

//// Update 4th case product with Product Disposition Values
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[3].Id, cpList[3].Id );

//			cpList[3].ProductDisposition1__c = 'PD1_2';
//			cpList[3].ProductDisposition2__c = 'PD2_2';
//			cpList[3].ProductDisposition3__c = 'PD3_2';
//			cpList[3].Under_Warranty__c = 'Under Warranty';
//			update cpList[3];

//// Check Case Product is correctly udpated
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[3].Id, cpList[3].Id );
//			System.assertEquals( 1, cpList[3].RecordStatusCount__c );
//			System.assertEquals( 'PD1_2', cpList[3].ProductDisposition1__c );
//			System.assertEquals( 'PD2_2', cpList[3].ProductDisposition2__c );
//			System.assertEquals( 'PD3_2', cpList[3].ProductDisposition3__c );
//			System.assertEquals( 'Under Warranty', cpList[3].Under_Warranty__c );
//			System.assertEquals( false, cpList[3].Highlight__c );

//// Check Careline Stat record is crated correctly.
//// No new Careline stat record should be created and there should still be only 1 from the earlier case product record
//// as In Review/Ignored records don't count as alerts
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_2', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_2', casList[0].ProductDisposition2__c );
//			System.assertEquals( 'PD3_2', casList[0].ProductDisposition3__c );
//			System.assertEquals( 2, casList[0].Counter__c );

//// Check Careline Alert record is crated correctly.
//// Careline Alert for Potential Quality should be created. As this is the Seond occurence and the alerts are set to be
//// triggered for GT 2 the record created should be with Status "In Review". Record should be tied back to the
//// parent stat record.
//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 4, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[3].RecordType.Name );
//			System.assertEquals( 'In Review', caList[3].Status__c );
//			System.assertEquals( 'PD1_2', caList[3].OriginalPD1__c );
//			System.assertEquals( 'PD2_2', caList[3].OriginalPD2__c );
//			System.assertEquals( 'PD3_2', caList[3].OriginalPD3__c );
//			System.assertEquals( casList[0].Id, caList[3].CarelineAlertStat__c );

//		Test.stopTest();
//	}

//	@isTest
//	static void shouldCreateCarelineLT2(){
//		List<Case_Product__c> cpList = new List<Case_Product__c>();
//		List<CarelineAlertStat__c> casList = new List<CarelineAlertStat__c>();
//		List<CarelineAlert__c> caList = new List<CarelineAlert__c>();

//		List<Case> csList = [SELECT Id FROM Case ORDER BY CreatedDate ];
//		System.assertEquals( 2, csList.size() );
//		Map<String, Id> prodNameToIdMap = new Map<String, Id>();
//		for( Product2 p : [SELECT Id, Name FROM Product2 ] ){
//			prodNameToIdMap.put( p.Name , p.Id );
//		}
//		System.assertEquals(2, prodNameToIdMap.size() );

//		List<Case_Product__c> newCpList = new List<Case_Product__c>();
//		for( Integer i=1; i<=2; i++){
//			newCpList.add( new Case_Product__c(
//							Case__c      = csList[0].Id,
//							Product__c   = prodNameToIdMap.get( 'Test_Prod_0' ),
//							Highlight__c = true
//						));
//		}
//		insert newCpList;

//		cpList = CarelineAlert_NWL_T.getCaseProductData();
//		System.assertEquals( 2, cpList.size() );
//		System.assertEquals( csList[0].Id, cpList[0].Case__c );
//		System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), cpList[0].Product__c );
//		System.assertEquals( 0, cpList[0].RecordStatusCount__c );
//		System.assertEquals( null, cpList[0].ProductDisposition1__c );
//		System.assertEquals( null, cpList[0].ProductDisposition2__c );
//		System.assertEquals( null, cpList[0].ProductDisposition3__c );
//		System.assertEquals( null, cpList[0].ProductDisposition4__c );
//		System.assertEquals( null, cpList[0].Under_Warranty__c );
//		System.assertEquals( true, cpList[0].Highlight__c );

//		Test.startTest();
//// Update 1st case product with Product Disposition Values
//			cpList[0].ProductDisposition1__c = 'PD1_3';
//			cpList[0].ProductDisposition2__c = 'PD2_3';
//			cpList[0].Under_Warranty__c = 'Under Warranty';
//			update cpList[0];
//// Check Case Product is correctly udpated
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[0].Id, cpList[0].Id );
//			System.assertEquals( 1, cpList[0].RecordStatusCount__c );
//			System.assertEquals( 'PD1_3', cpList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_3', cpList[0].ProductDisposition2__c );
//			System.assertEquals( 'Under Warranty', cpList[0].Under_Warranty__c );
//			System.assertEquals( true, cpList[0].Highlight__c );
//// Check Careline Stat record is crated correctly.
//// Careline Alert Stat record should be created as there is no existing records
//// for this product and disposition combinations.
//// The counter should be 0 as there should only be 1 alert record tied to this and that is still in IN review status
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_3', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_3', casList[0].ProductDisposition2__c );
//			System.assertEquals( 0, casList[0].Counter__c );
//// Check Careline Alert record is crated correctly.
//// Careline Alert for Potential Quality should be created. As this is the first occurence and the alerts are set to be
//// triggered for LT 2 the record created should be with Status "In Review". The record type should be Potential
//// Quality and tied back to the parent stat record
//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 2, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[0].RecordType.Name );
//			System.assertEquals( 'In Review', caList[0].Status__c );
//			System.assertEquals( 'PD1_3', caList[0].OriginalPD1__c );
//			System.assertEquals( 'PD2_3', caList[0].OriginalPD2__c );
//			System.assertEquals( casList[0].Id, caList[0].CarelineAlertStat__c );

//			System.assertEquals( 'Potential Safety', caList[1].RecordType.Name );
//			System.assertEquals( 'In Review', caList[1].Status__c );
//			System.assertEquals( 'PD1_3', caList[1].OriginalPD1__c );
//			System.assertEquals( 'PD2_3', caList[1].OriginalPD2__c );
//			System.assertEquals( casList[0].Id, caList[1].CarelineAlertStat__c );

//// Reject the careline alert record. The Rejected records count towards actual alerts.
//// next alert generated should be Not For Review as alrerts are only set for < 2
//			caList[0].Status__c = 'Rejected';
//			update caList;

//// Update 2nd case product with Product Disposition Values
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[1].Id, cpList[1].Id );

//			cpList[1].ProductDisposition1__c = 'PD1_3';
//			cpList[1].ProductDisposition2__c = 'PD2_3';
//			cpList[1].Under_Warranty__c = 'Under Warranty';
//			update cpList[1];

//// Check Case Product is correctly udpated
//			cpList = CarelineAlert_NWL_T.getCaseProductData();
//			System.assertEquals( newCpList[1].Id, cpList[1].Id );
//			System.assertEquals( 1, cpList[1].RecordStatusCount__c );
//			System.assertEquals( 'PD1_3', cpList[1].ProductDisposition1__c );
//			System.assertEquals( 'PD2_3', cpList[1].ProductDisposition2__c );
//			System.assertEquals( 'Under Warranty', cpList[1].Under_Warranty__c );
//			System.assertEquals( true, cpList[1].Highlight__c );

//// Check Careline Stat record is crated correctly.
//// No new Careline stat record should be created and there should be only 1 from the earlier case product record.
//			casList = CarelineAlert_NWL_T.getCarelineStatData();
//			System.assertEquals( 1, casList.size() );
//			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
//			System.assertEquals( 'PD1_3', casList[0].ProductDisposition1__c );
//			System.assertEquals( 'PD2_3', casList[0].ProductDisposition2__c );
//			System.assertEquals( 2, casList[0].Counter__c );

//// Check Careline Alert record is crated correctly.
//// Careline Alert for Potential Quality should be created. As this is the Seond occurence and the alerts are set to be
//// triggered for LT 2 the record created should be with Status "Not For Review". Record should be tied back to the
//// parent stat record .
//			caList = CarelineAlert_NWL_T.getCarelineAlertData();
//			System.assertEquals( 4, caList.size() );
//			System.assertEquals( 'Potential Quality', caList[2].RecordType.Name );
//			System.assertEquals( 'Not For Review', caList[2].Status__c );
//			System.assertEquals( 'PD1_3', caList[2].OriginalPD1__c );
//			System.assertEquals( 'PD2_3', caList[2].OriginalPD2__c );
//			System.assertEquals( casList[0].Id, caList[2].CarelineAlertStat__c );

//			System.assertEquals( 'Potential Safety', caList[3].RecordType.Name );
//			System.assertEquals( 'In Review', caList[3].Status__c );
//			System.assertEquals( 'PD1_3', caList[3].OriginalPD1__c );
//			System.assertEquals( 'PD2_3', caList[3].OriginalPD2__c );
//			System.assertEquals( casList[0].Id, caList[3].CarelineAlertStat__c );

//		Test.stopTest();
//	}

	@isTest
	static void shouldCrtPotentialSafety(){
		List<Case_Product__c> cpList = new List<Case_Product__c>();
		List<CarelineAlertStat__c> casList = new List<CarelineAlertStat__c>();
		List<CarelineAlert__c> caList = new List<CarelineAlert__c>();

		List<Case> csList = [SELECT Id FROM Case ORDER BY CreatedDate ];
		System.assertEquals( 2, csList.size() );
		Map<String, Id> prodNameToIdMap = new Map<String, Id>();
		for( Product2 p : [SELECT Id, Name FROM Product2 ] ){
			prodNameToIdMap.put( p.Name , p.Id );
		}
		System.assertEquals(2, prodNameToIdMap.size() );

		List<Case_Product__c> newCpList = new List<Case_Product__c>();
		for( Integer i=1; i<=2; i++){
			newCpList.add( new Case_Product__c(
							Case__c      = csList[0].Id,
							Product__c   = prodNameToIdMap.get( 'Test_Prod_0' ),
							Highlight__c = true
						));
		}
		insert newCpList;

		cpList = CarelineAlert_NWL_T.getCaseProductData();
		System.assertEquals( 2, cpList.size() );
		System.assertEquals( csList[0].Id, cpList[0].Case__c );
		System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), cpList[0].Product__c );
		System.assertEquals( 0, cpList[0].RecordStatusCount__c );
		System.assertEquals( null, cpList[0].ProductDisposition1__c );
		System.assertEquals( null, cpList[0].ProductDisposition2__c );
		System.assertEquals( null, cpList[0].ProductDisposition3__c );
		System.assertEquals( null, cpList[0].ProductDisposition4__c );
		System.assertEquals( null, cpList[0].Under_Warranty__c );
		System.assertEquals( true, cpList[0].Highlight__c );

		Test.startTest();
// Update 1st case product with Product Disposition Values
			cpList[0].ProductDisposition1__c = 'PD1_4';
			cpList[0].ProductDisposition2__c = 'PD2_4';
			cpList[0].ProductDisposition3__c = 'PD3_4';
			cpList[0].Under_Warranty__c = 'Under Warranty';
			cpList[0].PartLevel1__c = 'PL1';
			cpList[0].PartLevel2__c = 'PL2';
			cpList[0].How_did_it_happen__c = 'Airline Damage';
			cpList[0].DateofPurchaseUnknown__c = true;
			cpList[0].SerialBatchNumberUnknown__c = true;
			cpList[0].Serial_Batch_Number__c = 'SBNbr1';
			update cpList[0];

// Check Case Product is correctly udpated
			cpList = CarelineAlert_NWL_T.getCaseProductData();
			System.assertEquals( newCpList[0].Id, cpList[0].Id );
			System.assertEquals( 1, cpList[0].RecordStatusCount__c );
			System.assertEquals( 'PD1_4', cpList[0].ProductDisposition1__c );
			System.assertEquals( 'PD2_4', cpList[0].ProductDisposition2__c );
			System.assertEquals( 'PD3_4', cpList[0].ProductDisposition3__c );
			System.assertEquals( 'Under Warranty', cpList[0].Under_Warranty__c );
			System.assertEquals( true, cpList[0].Highlight__c );
// Check Careline Stat record is crated correctly.
// Careline Alert Stat record should be created as there is no existing records for this product and disposition combinations.
// The counter should be 1 as there should only be 1 alert record tied to this and that is still in IN review status
			casList = CarelineAlert_NWL_T.getCarelineStatData();
			System.assertEquals( 1, casList.size() );
			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
			System.assertEquals( 'PD1_4', casList[0].ProductDisposition1__c );
			System.assertEquals( 'PD2_4', casList[0].ProductDisposition2__c );
			System.assertEquals( 'PD3_4', casList[0].ProductDisposition3__c );
			System.assertEquals( 0, casList[0].Counter__c );
// Check Careline Alert record is crated correctly.
// Careline Alert for Potential Quality should be created. As this is the first occurence and the alerts are set to be
// triggered for LT 2 the record created should be with Status "In Review". The record type should be Potential
// Quality and tied back to the parent stat record
			caList = CarelineAlert_NWL_T.getCarelineAlertData();
			System.assertEquals( 1, caList.size() );
			System.assertEquals( 'Potential Safety', caList[0].RecordType.Name );
			System.assertEquals( 'In Review', caList[0].Status__c );
			System.assertEquals( 'PD1_4', caList[0].OriginalPD1__c );
			System.assertEquals( 'PD2_4', caList[0].OriginalPD2__c );
			System.assertEquals( 'PD3_4', caList[0].OriginalPD3__c );
			System.assertEquals( casList[0].Id, caList[0].CarelineAlertStat__c );

			caList[0].PotentialSafetyEmail__c = 'a@b.com';
			caList[0].Status__c = 'Escalated';
			update caList[0];

// Update 1st case product with Product Disposition Values
			cpList[1].ProductDisposition1__c = 'PD1_4';
			cpList[1].ProductDisposition2__c = 'PD2_4';
			cpList[1].ProductDisposition3__c = 'PD3_4';
			cpList[1].Under_Warranty__c = 'Under Warranty';
			cpList[1].PartLevel1__c = 'PL1';
			cpList[1].PartLevel2__c = 'PL2';
			cpList[1].How_did_it_happen__c = 'Airline Damage';
			cpList[1].DateofPurchaseUnknown__c = true;
			cpList[1].SerialBatchNumberUnknown__c = true;
			cpList[1].Serial_Batch_Number__c = 'SBNbr1';
			update cpList[1];

// Check Case Product is correctly udpated
			cpList = CarelineAlert_NWL_T.getCaseProductData();
			System.assertEquals( newCpList[1].Id, cpList[1].Id );
			System.assertEquals( 1, cpList[1].RecordStatusCount__c );
			System.assertEquals( 'PD1_4', cpList[1].ProductDisposition1__c );
			System.assertEquals( 'PD2_4', cpList[1].ProductDisposition2__c );
			System.assertEquals( 'PD3_4', cpList[1].ProductDisposition3__c );
			System.assertEquals( 'Under Warranty', cpList[1].Under_Warranty__c );
			System.assertEquals( true, cpList[1].Highlight__c );
// Check Careline Stat record is crated correctly.
// Careline Alert Stat record should be created as there is no existing records for this product and disposition combinations.
// The counter should be 1 as there should only be 1 alert record tied to this and that is still in IN review status
			casList = CarelineAlert_NWL_T.getCarelineStatData();
			System.assertEquals( 1, casList.size() );
			System.assertEquals( prodNameToIdMap.get( 'Test_Prod_0' ), casList[0].Product__c );
			System.assertEquals( 'PD1_4', casList[0].ProductDisposition1__c );
			System.assertEquals( 'PD2_4', casList[0].ProductDisposition2__c );
			System.assertEquals( 'PD3_4', casList[0].ProductDisposition3__c );
			System.assertEquals( 1, casList[0].Counter__c );
// Check Careline Alert record is crated correctly.
// Careline Alert for Potential Quality should be created. As this is the first occurence and the alerts are set to be
// triggered for LT 2 the record created should be with Status "In Review". The record type should be Potential
// Quality and tied back to the parent stat record
			caList = CarelineAlert_NWL_T.getCarelineAlertData();
			System.assertEquals( 2, caList.size() );
			System.assertEquals( 'Potential Safety', caList[1].RecordType.Name );
			System.assertEquals( 'In Review', caList[1].Status__c );
			System.assertEquals( 'PD1_4', caList[1].OriginalPD1__c );
			System.assertEquals( 'PD2_4', caList[1].OriginalPD2__c );
			System.assertEquals( 'PD3_4', caList[1].OriginalPD3__c );
			System.assertEquals( casList[0].Id, caList[1].CarelineAlertStat__c );

		Test.stopTest();
	}

/**
 * Method to get case product data
 * @return
 */
	private static List<Case_Product__c> getCaseProductData(){
		return [SELECT Id, Case__c, RecordStatusCount__c, ProductDisposition1__c, ProductDisposition2__c,
						 ProductDisposition3__c, ProductDisposition4__c, Under_Warranty__c, Highlight__c, Product__c
					 FROM Case_Product__c
					 ORDER BY CreatedDate];
	}
/**
 * Method to get careline stat object
 * @return
 */
	private static List<CarelineAlertStat__c> getCarelineStatData(){
		return [SELECT Id, Product__c, ProductDisposition1__c, ProductDisposition2__c,
						ProductDisposition3__c, ProductDisposition4__c, Counter__c
					FROM CarelineAlertStat__c
					ORDER BY CreatedDate];
	}

/**
 * Method to get careline alert object
 * @return
 */
	private static List<CarelineAlert__c> getCarelineAlertData(){
		return [SELECT Id, RecordType.Name, Status__c, OriginalPD1__c, OriginalPD2__c,
						OriginalPD3__c, OriginalPD4__c,CaseProduct__c, CarelineAlertStat__c,
						PotentialQualityEmail__c, PotentialSafetyEmail__c
					FROM CarelineAlert__c
					ORDER BY CreatedDate];
	}
}
//********************************************* END OF CLASS *********************************************************//