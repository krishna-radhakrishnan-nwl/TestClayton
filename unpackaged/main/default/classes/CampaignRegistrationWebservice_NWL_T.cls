@isTest
public class CampaignRegistrationWebservice_NWL_T{

    private static final String C_SUCCESS         = 'Success';
    private static final String C_ERROR           = 'Error';
    private static final String C_KEY_STATUS      = 'status';
    private static final String C_KEY_MESSAGE     = 'Message';
    private static final String C_KEY_CONTACT_ID  = 'contactId';

    @testSetup
    public static void commonTestDataSetup(){
		// Initialize Generate Test Data class
    	GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();
    	// Set Generic Consumer Account Switch to active
    	GlobalSwitchNWL__c gs = g.globalSwitchSettings( 'GCA', true );
    	System.assertNotEquals(null, gs );
    	// Generate test products
    	g.prodRecTyId = Schema.SObjectType.Product2.RecordTypeInfosByName.get('SAP Product').RecordTypeId;
    	List<Product2> pList =  g.productData(2, 'Test_Prod_');
    	System.assertEquals(2, pList.size() );
		// Generate test brand
		Brand__c b = g.brand( 'Dymo' );
		System.assertNotEquals(null, b );
		// Generate Test accounts
		g.aRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Generic Consumer Account').RecordTypeId;
    	List<Account> aList = g.account( 1, 'Generic Consumer Account EMEA', null, null );
    	System.assertEquals( 1, aList.size() );
		// Generate Generic Consumer Account Settings
    	g.gcasRegion = 'EMEA';
    	GCASettingsNWL__c gcas = g.gcaSettings( aList[0].id, 0, 9999 );
    	System.assertNotEquals(null, gcas );

    	LocaleSetting__c ls = g.localeSettingsByBrand('fr_FR', 'EMEA', b.Id);
		System.assertNotEquals(null, ls );

		LanguageNWL__c l = g.languageSettings( 'French', 'fr', 'fra');
		System.assertNotEquals(null, l );

    	// Generate Test Campaigns
    	g.cmBrandId = b.Id;
		g.cmMaxOrderProductsPerContact = 0;
		g.cmMaxProductsPerRegistration = 0;
		g.cmMaxRegistrationProductsPerContact = 0;
		g.cmMinProductsPerOrderProduct = 1;
		g.cmMinProductsPerRegistration = 1;
    	List<Campaign> cList = g.Campaigns('Cashback', 'Test-XTL-', 2, true);
    	System.assertEquals( 2, cList.size() );
    	cList.addAll( g.Campaigns('Fulfillment','Test-ENT-', 1, false) );
    	System.assertEquals( 3, cList.size() );

		// Generate test Campaign Products
		List<CampaignProduct__c> cpList = new List<CampaignProduct__c>();
		// Add for GB
		CampaignProduct__c cp1 = new CampaignProduct__c();
		cp1.RecordTypeId                     = Schema.SObjectType.CampaignProduct__c.RecordTypeInfosByName.get('GB').RecordTypeId;
		cp1.Campaign__c                      = cList[0].Id;
		cp1.CashbackAmount__c                = 10.99;
		cp1.Product__c                       = pList[0].id;
		cp1.WebProductName__c                = 'XTL-300';
		cp1.CashbackCalculationPreference__c = 'Fixed';
		cp1.CashbackPercentage__c 			 = 50;
		cp1.WebProductImageName__c           = 'TestImage1';
		cp1.CurrencyIsoCode                  = 'GBP';
		cpList.add(cp1);

		// Add for FR
		CampaignProduct__c cp2 = new CampaignProduct__c();
		cp2.RecordTypeId                     = Schema.SObjectType.CampaignProduct__c.RecordTypeInfosByName.get('FR').RecordTypeId;
		cp2.Campaign__c                      = cList[0].Id;
		cp2.CashbackAmount__c                = 10.99;
		cp2.Product__c                       = pList[0].id;
		cp2.WebProductName__c                = 'XTL-300';
		cp2.CashbackCalculationPreference__c = 'Fixed';
		cp2.CashbackPercentage__c            = 50;
		cp2.WebProductImageName__c           = 'TestImage1';
		cp2.CurrencyIsoCode                  = 'EUR';
		cpList.add(cp2);

		// Add for FR
		CampaignProduct__c cp3 = new CampaignProduct__c();
		cp3.RecordTypeId                     = Schema.SObjectType.CampaignProduct__c.RecordTypeInfosByName.get('FR').RecordTypeId;
		cp3.Campaign__c                      = cList[0].Id;
		cp3.CashbackAmount__c                = 10.99;
		cp3.Product__c                       = pList[1].id;
		cp3.WebProductName__c                = 'XTL-500';
		cp3.CashbackCalculationPreference__c = 'Fixed';
		cp3.CashbackPercentage__c            = 50;
		cp3.WebProductImageName__c           = 'TestImage2';
		cp3.CurrencyIsoCode                  = 'EUR';
		cpList.add(cp3);

		// Add for GB - Fulfillment
		CampaignProduct__c cp4 = new CampaignProduct__c();
		cp4.RecordTypeId           = Schema.SObjectType.CampaignProduct__c.RecordTypeInfosByName.get('GB').RecordTypeId;
		cp4.Campaign__c            = cList[2].Id;
		cp4.Product__c             = pList[0].id;
		cp4.WebProductName__c      = 'XTL-300';
		cp4.WebProductImageName__c = 'TestImage1';
		cpList.add(cp4);

		insert cpList;
		System.assertEquals( 4, cpList.size() );

		// Add for GB - Fulfillment
		CampaignOrderProduct__c cop1 = new CampaignOrderProduct__c();
		cop1.RecordTypeId            = Schema.SObjectType.CampaignOrderProduct__c.RecordTypeInfosByName.get('GB').RecordTypeId;
		cop1.Campaign__c             = cList[2].Id;
		cop1.Product__c              = pList[0].id;
		cop1.WebProductName__c       = 'XTL-300';
		cop1.WebProductImageName__c  = 'TestImage1';
		insert cop1;

		// Set Campaigns to Active
		cList.clear();
		for( Campaign c : [SELECT Id, IsActive FROM Campaign]){
			c.IsActive = true;
			cList.add(c);
		}
		update cList;
    }

    @isTest
	public static void testSendCashbackCampaignData(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name, SentToWebsite__c FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		Test.setMock(HttpCalloutMock.class, new CamReg_HttpMock_NWL_T());
		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.sendCampaignData( c.Id );
		Test.stopTest();
		System.assertEquals( true, res.startsWith('SUCCESS') );
		System.assertEquals( system.today(), [SELECT SentToWebsite__c FROM Campaign WHERE Id = :c.Id LIMIT 1][0].SentToWebsite__c.date() );
	}

    @isTest
	public static void testSendFulfillmentCampaignData(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name, SentToWebsite__c FROM Campaign WHERE Name = 'Test-ENT-0' LIMIT 1][0];
		Test.setMock(HttpCalloutMock.class, new CamReg_HttpMock_NWL_T());
		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.sendCampaignData( c.Id );
		Test.stopTest();
		System.assertEquals( true, res.startsWith('SUCCESS') );
		System.assertEquals( system.today(), [SELECT SentToWebsite__c FROM Campaign WHERE Id = :c.Id LIMIT 1][0].SentToWebsite__c.date() );
	}

    @isTest
	public static void testMissingLocale(){
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', 'abcd' );
		inp.keyValuePairs = '{}';
		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( false, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'locale missing in KVP' ) );
		//System.assertEquals( false, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );

		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', null, null, true );
	}

    @isTest
	public static void testInvalidCampaignType(){
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', 'abcd' );
		inp.campaignType = 'Test';
		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( false, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Invalid Campaign Type : Test' ) );
		//System.assertEquals( false, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', null, null, true );
	}

    @isTest
	public static void testNoGcaConfig(){
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', 'abcd' );
		inp.keyValuePairs = '{"locale":"en_US"}';
		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( false, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Generic consumer account settings not found : US' ) );
		//System.assertEquals( false, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', null, null, true );
	}

    @isTest
	public static void testInvalidCampaignId(){
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', '07Lq000000Kk2qREAR' );
		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Invalid Campaign Id : [07Lq000000Kk2qREAR]. No active campaign found' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), null, true );
	}

    @isTest
	public static void testNoAttachments(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );
		inp.attachmentsList = new List<CampaignRegistrationWebservice_NWL.AttachmentsData>();
		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Missing Attachment for Proof Of Purchase. This Campaign requires a Proof Of Purchase to be uploaded on the site' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), null, true );
	}

    @isTest
	public static void testInvalidDop(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );
		inp.productList[0].dateOfPurchase = System.today().addDays(26);

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Date of Purchase outside Campaign Date of Purchase of ' +
			Utility_NWL.formatDate(System.today()) +
			' And ' +
			Utility_NWL.formatDate(System.today().addDays(25)) +
			' for product Test_Prod_0' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), null, true );
	}

    @isTest
	public static void testBlankDop(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );
		inp.productList[0].dateOfPurchase = null;

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Date of Purchase cannot be blank. Product : Test_Prod_0' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), null, true );
	}

    @isTest
	public static void testBlankSN(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );
		inp.productList[0].serialNumber = '';

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Serial Number cannot be blank. Product : Test_Prod_0' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), null, true );
	}

    @isTest
	public static void testDuplicateSN(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );

		CampaignRegistrationWebservice_NWL.ProductData pd = new CampaignRegistrationWebservice_NWL.ProductData();
		pd.counter          = 2;
		pd.countryCode      = 'GB';
		pd.materialNumber   = 'Test_Prod_0';
		pd.quantity         = 1;
		pd.serialNumber     = '1234567890';
		pd.pricePaidPerUnit = '100.50';
		pd.curr             = 'GBP';
		pd.dateOfPurchase   = System.today();
		pd.dealerName       = 'Test Dealer';
		inp.productList.add(pd);

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Duplicate Serial Number in the incomming payload : 1234567890' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), null, true );
	}

    @isTest
	public static void testMaxProdPerReg(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );

		CampaignRegistrationWebservice_NWL.ProductData pd = new CampaignRegistrationWebservice_NWL.ProductData();
		pd.counter          = 2;
		pd.countryCode      = 'GB';
		pd.materialNumber   = 'Test_Prod_0';
		pd.quantity         = 1;
		pd.serialNumber     = '1234567890';
		pd.pricePaidPerUnit = '100.50';
		pd.curr             = 'GBP';
		pd.dateOfPurchase   = System.today();
		pd.dealerName       = 'Test Dealer';
		inp.productList.add(pd);

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Duplicate Serial Number in the incomming payload : 1234567890' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), null, true );
	}



    @isTest
	public static void testInvalidProducts(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );
		inp.productList[0].materialNumber = 'test';

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'No valid products found for campaign' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), null, true );
	}

    @isTest
	public static void testCamRegHdrErr(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );
		inp.accountNumber = '123';

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Error creating Campaign Registration Header record' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), null, true );
	}

    @isTest
	public static void testCamRegItmErr(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );
		inp.productList[0].curr = 'EUR';

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );

		System.assertEquals( C_ERROR, rd.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd.msgSet.contains( 'Error creating Campaign Registration Item record' ) );
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), rd.resMap.get( 'campaignRegistrationId' ), true );
	}

    @isTest
	public static void testExistingRegwithSameSN(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', c.Id );

		String res1 = CampaignRegistrationWebservice_NWL.register( inp );
		ResultData rd1 = CampaignRegistrationWebservice_NWL_T.formatResult( res1 );
		System.assertEquals( C_SUCCESS, rd1.resMap.get( C_KEY_STATUS ) );
		System.assertEquals( true, rd1.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( true, rd1.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( true, rd1.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		CampaignRegistrationWebservice_NWL_T.validateContact( rd1.resMap.get( 'contactId' ), inp );
		CampaignRegistrationItems__c cri = [SELECT Id FROM CampaignRegistrationItems__c];
		inp.mailingCity  = 'Alpharetta';
		Test.startTest();
			String res2 = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();

		ResultData rd2 = CampaignRegistrationWebservice_NWL_T.formatResult( res2 );
		System.assertEquals( C_ERROR, rd2.resMap.get( C_KEY_STATUS ) );
		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd2.resMap.containsKey( 'contactId' ) );
		System.assertEquals( false, rd2.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( false, rd2.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages returned correctly.
		System.assertEquals( true, rd2.msgSet.contains( 'Campaign Registration : ' + cri.Id + ' already exists for Serial Number : 1234567890' ) );
		System.assertEquals( true, rd2.msgSet.contains( 'Existing contact found : ' + rd1.resMap.get( 'contactId' ) ) );
		CampaignRegistrationWebservice_NWL_T.validateContact( rd1.resMap.get( 'contactId' ), inp );
		System.assertEquals( false, rd2.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( false, rd2.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd2.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( false, rd2.msgSet.contains( 'Approval process request submitted Successfully' ) );
		// Validate log data
		System.assertEquals( true, [SELECT Id, IsError__c FROM Email_Log__c WHERE IsError__c = true][0].IsError__c );
	}

    @isTest
	public static void testNewFulfillmentCampaignRegistration(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-ENT-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Fulfillment', String.valueOf(c.Id) );

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );
		System.assertEquals( C_SUCCESS, rd.resMap.get( C_KEY_STATUS ) );

		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages are returned correctly.
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Campaign Registration Order Items created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );
	}

    @isTest
	public static void testNewCashbackCampaignRegistration(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', String.valueOf(c.Id) );

		Test.startTest();
			String res = CampaignRegistrationWebservice_NWL.register( inp );
		Test.stopTest();
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );
		System.assertEquals( C_SUCCESS, rd.resMap.get( C_KEY_STATUS ) );

		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		// Check if all messages are returned correctly.
		//System.assertEquals( true, rd.msgSet.contains( 'Contact created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Campaign Registration Header created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Campaign Registration Items created successfully' ) );
		System.assertEquals( false, rd.msgSet.contains( 'Campaign Registration Order Items created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Attachments created successfully' ) );
		System.assertEquals( true, rd.msgSet.contains( 'Approval process request submitted Successfully' ) );

		// Check contact details
		CampaignRegistrationWebservice_NWL_T.validateContact( rd.resMap.get( 'contactId' ), inp );
		// Validate log data
		CampaignRegistrationWebservice_NWL_T.validateLogData( 'Dymo', rd.resMap.get( 'contactId' ), rd.resMap.get( 'campaignRegistrationId' ), false );
	}
    @isTest
	public static void testTrackInvalidCashbackStatus(){
		Test.startTest();
			String trackRes = CampaignRegistrationWebservice_NWL.trackStatus( 'Test' );
		Test.stopTest();
		Map<String, String> resMap = (Map<String, String>)JSON.deserialize( trackRes, Map<String, String>.Class );
		System.assertEquals( C_ERROR, resMap.get( C_KEY_STATUS ) );
	}
    @isTest
	public static void testTrackCashbackStatus(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-ENT-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Fulfillment', String.valueOf(c.Id) );
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( CampaignRegistrationWebservice_NWL.register( inp ) );
		System.assertEquals( C_SUCCESS, rd.resMap.get( C_KEY_STATUS ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );
		Test.startTest();
			String trackRes = CampaignRegistrationWebservice_NWL.trackStatus( rd.resMap.get( 'campaignRegistrationNumber' ) );
		Test.stopTest();
		Map<String, String> resMap = (Map<String, String>)JSON.deserialize( trackRes, Map<String, String>.Class );
		System.assertEquals( C_SUCCESS, resMap.get( C_KEY_STATUS ) );
	}

    @isTest
	public static void testTrackFulfillmentStatus(){
		Campaign c = [SELECT Id, CampaignBrand__r.Name, RecordType.Name FROM Campaign WHERE Name = 'Test-XTL-0' LIMIT 1][0];
		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Cashback', String.valueOf(c.Id) );
		ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( CampaignRegistrationWebservice_NWL.register( inp ) );
		System.assertEquals( C_SUCCESS, rd.resMap.get( C_KEY_STATUS ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );
		Test.startTest();
			String trackRes = CampaignRegistrationWebservice_NWL.trackStatus( rd.resMap.get( 'campaignRegistrationNumber' ) );
		Test.stopTest();
		Map<String, String> resMap = (Map<String, String>)JSON.deserialize( trackRes, Map<String, String>.Class );
		System.assertEquals( C_SUCCESS, resMap.get( C_KEY_STATUS ) );
	}

	//TODO : Move to appropriate classes
	@isTest
	private static void testWS(){
		new XICashbackLoadWS_NWL.DT_CashbackLoad_Response_Sykes_SFDC();
		new XICashbackLoadWS_NWL.OrderItem_element();
		new XICashbackLoadWS_NWL.DT_CashbackLoad_Request_Sykes_SFDC();
		new XICashbackLoadWS_NWL.OrderResponse_element();
		new XICashbackLoadWS_NWL.Order_element();
		new XICashbackLoadWS_NWL.HTTPS_Port();

		new XICashbackStatusWS_NWL.DT_CashbackStatus_Request_Sykes_SFDC();
		new XICashbackStatusWS_NWL.DT_CashbackStatus_Response_Sykes_SFDC();
		new XICashbackStatusWS_NWL.OrderItem_element();
		new XICashbackStatusWS_NWL.OrderResponse_element();
		new XICashbackStatusWS_NWL.Order_element();
		new XICashbackStatusWS_NWL.HTTPS_Port();

		new XICreateCaseInTsrWS_NWL.Record_element();
		new XICreateCaseInTsrWS_NWL.DT_CreateCaseTesseract_SDFC_Request();
		new XICreateCaseInTsrWS_NWL.DT_CreateCaseTesseract_SFDC_Response();
		new XICreateCaseInTsrWS_NWL.HTTPS_Port();


		new XISAPCaseNotesWS_NWL.DT_CaseNotes_Request();
		new XISAPCaseNotesWS_NWL.Record_element();
		new XISAPCaseNotesWS_NWL.DT_CaseNotes_Response();
		new XISAPCaseNotesWS_NWL.HTTPS_Port();


		new XICheckRequestWS_NWL.DT_RefundCheckResponse_Salesforce();
		new XICheckRequestWS_NWL.Record_element();
		new XICheckRequestWS_NWL.DT_RefundCheckRequest_Salesforce();
		new XICheckRequestWS_NWL.HTTPS_Port();

		new XISampleOrderNotification_NWL.DT_SalesOrderUpdateResponse_Salesforce();
		new XISampleOrderNotification_NWL.Header_element();
		new XISampleOrderNotification_NWL.DT_SalesOrderUpdateRequest_Salesforce();
		new XISampleOrderNotification_NWL.Record_element();
		new XISampleOrderNotification_NWL.HTTPS_Port();

		new XIOrdShpStatusCheckWS_NWL.DT_OrderShipmentStatusCheck_Request();
		new XIOrdShpStatusCheckWS_NWL.Record_element();
		new XIOrdShpStatusCheckWS_NWL.DT_OrderShipmentStatusCheck_Response();
		new XIOrdShpStatusCheckWS_NWL.HTTPS_Port();
	}

	public static CampaignRegistrationWebservice_NWL.InputData inpData( String brand, String camType, String cId ){
		Map<String, String> keyValMap = new Map<String, String>();
		CampaignRegistrationWebservice_NWL.InputData inp = new CampaignRegistrationWebservice_NWL.InputData();
		List<CampaignRegistrationWebservice_NWL.ProductData> pdList = new List<CampaignRegistrationWebservice_NWL.ProductData>();
		CampaignRegistrationWebservice_NWL.ProductData pd = new CampaignRegistrationWebservice_NWL.ProductData();
		List<CampaignRegistrationWebservice_NWL.OrderProductData> opdList = new List<CampaignRegistrationWebservice_NWL.OrderProductData>();
		CampaignRegistrationWebservice_NWL.OrderProductData opd = new CampaignRegistrationWebservice_NWL.OrderProductData();
		List<CampaignRegistrationWebservice_NWL.AttachmentsData> attList = new List<CampaignRegistrationWebservice_NWL.AttachmentsData>();
		CampaignRegistrationWebservice_NWL.AttachmentsData att = new CampaignRegistrationWebservice_NWL.AttachmentsData();

		keyValMap.put( 'locale', 'fr_FR' );

		pd.counter        = 1;
		pd.countryCode    = 'GB';
		pd.materialNumber = 'Test_Prod_0';
		pd.quantity       = 1;
		pd.dateOfPurchase = System.today();
		pd.dealerName     = 'Test Dealer';
		if( camType == 'Cashback'){
			pd.serialNumber     = '1234567890';
			pd.pricePaidPerUnit = '100.50';
			pd.curr             = 'GBP';
		    pd.webCalculatedCashbackValue = '10.00';
		}else if( camType == 'Fulfillment'){

		}
		pdList.add(pd);

		if( camType == 'Fulfillment'){
			opd.counter        = 1;
			opd.countryCode    = 'GB';
			opd.materialNumber = 'Test_Prod_0';
			opd.quantity       = 1;
			opdList.add(opd);
		}

		att.counter    = 1;
		att.name       = 'FileName';
		att.mimeType   = 'Image/jpg';
		att.base64Body = Blob.valueOf('Unit Test Image Attachment Body');
		attList.add(att);

		inp.brand       	   = brand;
		inp.campaignType       = camType;
		inp.campaignId         = cId;
		inp.salutation         = 'Mr.';
		inp.firstName          = 'Testfirst';
		inp.lastName           = 'Testlast';
		inp.email              = 'test@dummy.com';
		inp.phone              = '123-456-7890';
		inp.mailingStreet      = 'Baraniaka 88';
		inp.mailingCity        = 'Poznan';
		inp.mailingStateCode   = 'KP';
		inp.mailingPostalCode  = '61131';
		inp.mailingCountryCode = 'PL';
		if( camType == 'Cashback'){
			inp.accountNumber = '';
			inp.sortCode      = '';
			inp.ibanCode      = 'BE68844010370034';
			inp.bicCode       = 'AARBBEB1XXX';
		}
		inp.keyValuePairs      = JSON.serialize( keyValMap );
		inp.productList 	   = pdList;
		inp.orderProductList   = opdList;
		inp.attachmentsList    = attList;

		return inp;
	}

	private static void validateContact( Id conId, CampaignRegistrationWebservice_NWL.InputData inp ){
// Check if contactId was really created
		List<Contact> cList = [SELECT Id, Contact_Type__c, Salutation, FirstName, LastName, Email, Phone, Phone_Raw__c, Account.Name,
									Mailingstreet, MailingCity, MailingStateCode, MailingPostalCode, MailingCountryCode,
									Duplicate_Contact__c, Duplicate_Contact_Identifier__c, Language__c
 								FROM Contact WHERE Id = :conId];
		System.assertEquals( 1, cList.size() );
// Check if contact was associated to the consumer generic account
		System.assertEquals( true , cList[0].Account.Name.startsWith( 'Generic') );
// Check if contact created was type consumer
		System.assertEquals( 'Consumer', cList[0].Contact_Type__c );
// Check if contact created all correct input data
		System.assertEquals( inp.salutation, cList[0].Salutation );
		System.assertEquals( inp.firstName, cList[0].FirstName);
		System.assertEquals( inp.lastName, cList[0].LastName  );
		System.assertEquals( inp.email, cList[0].Email );
		System.assertEquals( inp.phone.replaceAll('[\\D]', ''), cList[0].Phone_Raw__c );
		System.assertEquals( inp.mailingstreet, cList[0].Mailingstreet );
		System.assertEquals( inp.mailingCity, cList[0].MailingCity );
		System.assertEquals( inp.mailingStateCode, cList[0].MailingStateCode );
		System.assertEquals( '61-131', cList[0].MailingPostalCode );
		System.assertEquals( inp.mailingCountryCode, cList[0].MailingCountryCode );
		System.assertEquals( 'French', cList[0].Language__c );
// Check if contact was identified as duplicate
		System.assertEquals( null, cList[0].Duplicate_Contact__c );
		System.assertEquals( null, cList[0].Duplicate_Contact_Identifier__c );
	}

	private static void validateLogData( String br, String cId, String cmId, Boolean isError ){
		List<Email_Log__c> eList = [SELECT Type__c, Brand__c, Contact_Id__c, CampaignRegistrationId__c, Trace__c, IsError__c
										FROM Email_Log__c];
		System.assertEquals( 1, eList.size() );
		System.assertEquals( 'CAMRG', eList[0].Type__c );
		System.assertNotEquals( null, eList[0].Trace__c );
		System.assertEquals( br, eList[0].Brand__c );
		System.assertEquals( cmId, eList[0].CampaignRegistrationId__c );
		System.assertEquals( cId, eList[0].Contact_Id__c );
		System.assertEquals( isError, eList[0].IsError__c );
	}

	public class ResultData{
		public Map<String, String> resMap = new Map<String, String>();
		public Set<String> msgSet = new Set<String>();
	}

	public static ResultData formatResult( String res ){
		ResultData rd = new ResultData();
		// Get result messages and convert to MAP from JSON string
		rd.resMap = (Map<String, String>)JSON.deserialize( res, Map<String, String>.Class );
		System.debug( 'rd.resMap : ' + rd.resMap );
		for( String s : rd.resMap.keySet() ){
			if( s.startsWith('message') ){
				rd.msgSet.add( rd.resMap.get(s) );
			}
		}
		return rd;
	}
}