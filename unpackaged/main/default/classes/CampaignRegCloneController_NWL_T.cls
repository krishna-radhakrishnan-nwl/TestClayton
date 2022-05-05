@isTest
private class CampaignRegCloneController_NWL_T{

    private static final String C_SUCCESS    = 'Success';
    private static final String C_KEY_STATUS = 'status';

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

        g.conType = 'Consumer';
        g.conRegion = 'EMEA';
        List<Contact> cnList = g.contacts( 1, 'Test Con', null, 'a@b.com');
        System.assertEquals(1, cnList.size());

    	// Generate Test Campaigns
    	g.cmBrandId = b.Id;
		g.cmMaxOrderProductsPerContact = 0;
		g.cmMaxProductsPerRegistration = 0;
		g.cmMaxRegistrationProductsPerContact = 0;
		g.cmMinProductsPerOrderProduct = 1;
		g.cmMinProductsPerRegistration = 1;
    	List<Campaign> cList = g.Campaigns('Fulfillment','Test-ENT-', 1, false);
    	System.assertEquals( 1, cList.size() );
    	cList.addAll( g.Campaigns('Fulfillment','Test-ENT-E1-', 1, false) );
    	System.assertEquals( 2, cList.size() );
    	cList.addAll( g.Campaigns('Fulfillment','Test-ENT-E2-', 1, false) );
    	System.assertEquals( 3, cList.size() );

		// Generate test Campaign Products
		List<CampaignProduct__c> cpList = new List<CampaignProduct__c>();

		// Add for GB - Fulfillment
		CampaignProduct__c cp4 = new CampaignProduct__c();
		cp4.RecordTypeId           = Schema.SObjectType.CampaignProduct__c.RecordTypeInfosByName.get('GB').RecordTypeId;
		cp4.Campaign__c            = cList[0].Id;
		cp4.Product__c             = pList[0].id;
		cp4.WebProductName__c      = 'XTL-300';
		cp4.WebProductImageName__c = 'TestImage1';
		cpList.add(cp4);

		// Add for FR - Fulfillment
		CampaignProduct__c cp3 = new CampaignProduct__c();
		cp3.RecordTypeId           = Schema.SObjectType.CampaignProduct__c.RecordTypeInfosByName.get('FR').RecordTypeId;
		cp3.Campaign__c            = cList[2].Id;
		cp3.Product__c             = pList[0].id;
		cp3.WebProductName__c      = 'XTL-300';
		cp3.WebProductImageName__c = 'TestImage1';
		cpList.add(cp3);

		insert cpList;
		System.assertEquals( 2, cpList.size() );

		// Add for GB - Fulfillment
		CampaignOrderProduct__c cop1 = new CampaignOrderProduct__c();
		cop1.RecordTypeId            = Schema.SObjectType.CampaignOrderProduct__c.RecordTypeInfosByName.get('GB').RecordTypeId;
		cop1.Campaign__c             = cList[0].Id;
		cop1.Product__c              = pList[0].id;
		cop1.WebProductName__c       = 'XTL-300';
		cop1.WebProductImageName__c  = 'TestImage1';
		insert cop1;
		System.assertNotEquals(null, cop1.Id);

		// Set Campaigns to Active
		cList.clear();
		for( Campaign c : [SELECT Id, IsActive FROM Campaign]){
			c.IsActive = true;
			cList.add(c);
		}
		update cList;
    }

	@isTest static void testCloneCampaignRegistrationNoProd(){

       	// setup a reference to the page the controller is expecting with the parameters
        PageReference pr = Page.CampaignRegClonePage_NWL;
        Test.setCurrentPage(pr);

        // Fetch campaign data
		Campaign c = [SELECT Id, Type FROM Campaign WHERE Name = 'Test-ENT-E1-0' LIMIT 1][0];
		System.assertNotEquals(null, c);
		System.assertEquals('Fulfillment', c.Type);
		// Create Campaign Registrations
		CampaignRegistration__c cr = new CampaignRegistration__c();
		cr.Campaign__c = c.Id;
		cr.Contact__c  = [SELECT Id FROM Contact LIMIT 1][0].Id;
		cr.Country__c  = 'FR';
		insert cr;
		System.assertNotEquals(null, cr.Id);

        // Construct the standard controller
        ApexPages.StandardController con = new ApexPages.StandardController(cr);

        // create the controller
        CampaignRegCloneController_NWL ext = new CampaignRegCloneController_NWL(con);

        // Switch to test context
        Test.startTest();
	        // call the cloneWithItems method
	        PageReference ref = ext.cloneWithItems();
        // Switch back to runtime context
        Test.stopTest();

		for(Apexpages.Message msg:ApexPages.getMessages()){
			System.assertEquals( ApexPages.Severity.ERROR, msg.getSeverity() );
			System.assertEquals( 'Campaign cannot be cloned. No registration items found', msg.getDetail() );
		}

        // Make sure the returned url is null since no items were found for
        System.assertEquals(null,ref );

        List<CampaignRegistration__c> crList = [SELECT Id FROM CampaignRegistration__c WHERE Id != :cr.Id];
        System.assertEquals(0, crList.size());

        List<CampaignRegistrationItems__c> criList = [SELECT Id FROM CampaignRegistrationItems__c WHERE CampaignRegistration__c != :cr.Id];
        System.assertEquals(0, criList.size());

        List<CampaignRegistrationOrderItem__c> croiList = [SELECT Id FROM CampaignRegistrationOrderItem__c WHERE CampaignRegistration__c != :cr.Id];
        System.assertEquals(0, croiList.size());

	}

	@isTest static void testCloneCampaignRegistrationNoOrdProd(){

       	// Setup a reference to the page the controller is expecting with the parameters
        PageReference pr = Page.CampaignRegClonePage_NWL;
        Test.setCurrentPage(pr);

        // Fetch campaign data
		Campaign c = [SELECT Id, Type FROM Campaign WHERE Name = 'Test-ENT-E2-0' LIMIT 1][0];
		System.assertNotEquals(null, c);
		System.assertEquals('Fulfillment', c.Type);
		// Create Campaign Registrations
		CampaignRegistration__c cr = new CampaignRegistration__c();
		cr.Campaign__c = c.Id;
		cr.Contact__c  = [SELECT Id FROM Contact LIMIT 1][0].Id;
		cr.Country__c  = 'FR';
		insert cr;
		System.assertNotEquals(null, cr.Id);

		CampaignRegistrationItems__c cri = new CampaignRegistrationItems__c();
		cri.CampaignRegistration__c = cr.Id;
		cri.CampaignProduct__c = [SELECT Id FROM CampaignProduct__c WHERE Campaign__r.Name = 'Test-ENT-E2-0' Limit 1][0].Id;
		cri.DateOfPurchase__c = Date.today();
		cri.DealerName__c = 'Other';
		cri.Quantity__c = 1;
		insert cri;
		System.assertNotEquals(null, cri.Id);

        // Construct the standard controller
        ApexPages.StandardController con = new ApexPages.StandardController(cr);

        // create the controller
        CampaignRegCloneController_NWL ext = new CampaignRegCloneController_NWL(con);

        // Switch to test context
        Test.startTest();
	        // call the cloneWithItems method
	        PageReference ref = ext.cloneWithItems();
        // Switch back to runtime context
        Test.stopTest();

		for(Apexpages.Message msg:ApexPages.getMessages()){
			System.assertEquals( ApexPages.Severity.ERROR, msg.getSeverity() );
			System.assertEquals( 'Campaign cannot be cloned. No registration order items found', msg.getDetail() );
		}

        // Make sure the returned url is null since no items were found for
        System.assertEquals(null,ref);

        List<CampaignRegistration__c> crList = [SELECT Id FROM CampaignRegistration__c WHERE Id != :cr.Id];
        System.assertEquals(0, crList.size());

        List<CampaignRegistrationItems__c> criList = [SELECT Id FROM CampaignRegistrationItems__c WHERE CampaignRegistration__c != :cr.Id];
        System.assertEquals(0, criList.size());

        List<CampaignRegistrationOrderItem__c> croiList = [SELECT Id FROM CampaignRegistrationOrderItem__c WHERE CampaignRegistration__c != :cr.Id];
        System.assertEquals(0, croiList.size());
	}


	@isTest static void testCloneCampaignRegistration(){

       	// setup a reference to the page the controller is expecting with the parameters
        PageReference pr = Page.CampaignRegClonePage_NWL;
        Test.setCurrentPage(pr);

        // Fetch campaign data
		Campaign c = [SELECT Id, Type FROM Campaign WHERE Name = 'Test-ENT-0' LIMIT 1][0];
		System.assertNotEquals(null, c);
		System.assertEquals('Fulfillment', c.Type);

		// Generate Input Data
		CampaignRegistrationWebservice_NWL.InputData inp = CampaignRegistrationWebservice_NWL_T.inpData( 'Dymo', 'Fulfillment', String.valueOf(c.Id) );
		// Create Campaign Registrations
		String res = CampaignRegistrationWebservice_NWL.register( inp );
		CampaignRegistrationWebservice_NWL_T.ResultData rd = CampaignRegistrationWebservice_NWL_T.formatResult( res );
		System.assertEquals( C_SUCCESS, rd.resMap.get( C_KEY_STATUS ) );

		// Check if all Ids are returned correctly.
		System.assertEquals( true, rd.resMap.containsKey( 'contactId' ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationId' ) );
		System.assertEquals( true, rd.resMap.containsKey( 'campaignRegistrationNumber' ) );

		CampaignRegistration__c cr = [SELECT Id FROM CampaignRegistration__c WHERE Id = :rd.resMap.get( 'campaignRegistrationId' ) ];

        // Construct the standard controller
        ApexPages.StandardController con = new ApexPages.StandardController(cr);

        // create the controller
        CampaignRegCloneController_NWL ext = new CampaignRegCloneController_NWL(con);

        // Switch to test context
        Test.startTest();
	        // call the cloneWithItems method
	        PageReference ref = ext.cloneWithItems();
        // Switch back to runtime context
        Test.stopTest();

        // create the matching page reference
        PageReference redir = new PageReference('/'+ext.newRecordId+'/e?retURL=%2F'+ext.newRecordId);
        // make sure the user is sent to the correct url
        System.assertEquals(redir.getUrl(), ref.getUrl());

        List<CampaignRegistration__c> crList = [SELECT Id, ParentCampaignRegistration__c FROM CampaignRegistration__c WHERE Id = :ext.newRecordId];
        System.assertEquals(1, crList.size());
        System.assertEquals(cr.Id, crList[0].ParentCampaignRegistration__c);

        List<CampaignRegistrationItems__c> criList = [SELECT Id FROM CampaignRegistrationItems__c WHERE CampaignRegistration__c = :ext.newRecordId];
        System.assertEquals(1, criList.size());

        List<CampaignRegistrationOrderItem__c> croiList = [SELECT Id FROM CampaignRegistrationOrderItem__c WHERE CampaignRegistration__c = :ext.newRecordId];
        System.assertEquals(1, croiList.size());
	}

}
//*********************************************** END OF CLASS *******************************************************//