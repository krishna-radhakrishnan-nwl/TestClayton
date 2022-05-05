@isTest
public class CalculateCashback_NWL_T{

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
    	// Generate Test Campaigns
    	g.cmBrandId = b.Id;
		g.cmMaxOrderProductsPerContact = 0;
		g.cmMaxProductsPerRegistration = 0;
		g.cmMaxRegistrationProductsPerContact = 2;
		g.cmMinProductsPerOrderProduct = 1;
		g.cmMinProductsPerRegistration = 1;
    	List<Campaign> cmList = g.Campaigns('Cashback', 'Test-XTL-', 1, true);
    	System.assertEquals( 1, cmList.size() );

    	// Generate Country Data
    	g.countrySettings( 'United Kingdom', 'GB', 'GB' );
		// Generate Test Contacts
		g.conType = 'Consumer';
		g.conRegion = 'EMEA';
		g.conMailingstreet      = '3 Glenlake Pkwy';
		g.conMailingCity        = 'Atlanta';
		g.conMailingStateCode   = 'AB';
		g.conMailingPostalCode  = '30328';
		g.conMailingCountryCode = 'GB';
		List<Contact> cList = g.contacts( 1, null, aList[0].Id, 'a@b.com' );
		System.assertEquals(1, cList.size() );

		// Generate test Campaign Products
		List<CampaignProduct__c> cpList = new List<CampaignProduct__c>();
		// Add for GB
		CampaignProduct__c cp1 = new CampaignProduct__c();
		cp1.RecordTypeId                     = Schema.SObjectType.CampaignProduct__c.RecordTypeInfosByName.get('GB').RecordTypeId;
		cp1.Campaign__c                      = cmList[0].Id;
		cp1.CashbackAmount__c                = 500.00;
		cp1.Product__c                       = pList[0].id;
		cp1.WebProductName__c                = 'XTL-300';
		cp1.CashbackCalculationPreference__c = 'Fixed';
		cp1.CashbackPercentage__c 			 = 50;
		cp1.WebProductImageName__c           = 'TestImage1';
		cp1.CurrencyIsoCode                  = 'GBP';
		cpList.add(cp1);

		// Add for FR
		CampaignProduct__c cp3 = new CampaignProduct__c();
		cp3.RecordTypeId                     = Schema.SObjectType.CampaignProduct__c.RecordTypeInfosByName.get('FR').RecordTypeId;
		cp3.Campaign__c                      = cmList[0].Id;
		cp3.CashbackAmount__c                = 500.00;
		cp3.Product__c                       = pList[0].id;
		cp3.WebProductName__c                = 'XTL-300';
		cp3.CashbackCalculationPreference__c = 'Percentage';
		cp3.CashbackPercentage__c 			 = 50;
		cp3.WebProductImageName__c           = 'TestImage1';
		cp3.CurrencyIsoCode                  = 'EUR';
		cpList.add(cp3);

		insert cpList;
		System.assertEquals(2, cpList.size() );

		// Set Campaigns to Active
		cmList.clear();
		for( Campaign c : [SELECT Id, IsActive FROM Campaign]){
			c.IsActive = true;
			cmList.add(c);
		}
		update cmList;
    }

    @isTest
	public static void testCurrencyMatch(){
		List<Campaign> cmList = [SELECT Id, (SELECT Id FROM Campaign_Products__r) FROM Campaign WHERE RecordType.Name = 'Cashback'];
		System.assertEquals(1, cmList.size() );
		System.assertEquals(2, cmList[0].Campaign_Products__r.size() );

		List<Contact> cList = [SELECT Id FROM Contact];
		System.assertEquals(1, cList.size() );

		List<Product2> pList = [SELECT Id FROM Product2 WHERE Name = 'Test_Prod_0'];
		System.assertEquals(1, pList.size() );

		CampaignRegistration__c cr = new CampaignRegistration__c();
		cr.BankAccountNumber__c = '12345678';
		cr.SortCode__c           = '123456';
		cr.Campaign__c          = cmList[0].Id;
		cr.CashbackStatus__c    = 'Pending POP Approval';
		cr.Contact__c           = cList[0].Id;
		cr.Country__c           = 'GB';
		cr.PopStatus__c         = 'Not Submitted For Approval';
		insert cr;
		System.assertNotEquals(null, cr.Id );

		CampaignRegistrationItems__c cri = new CampaignRegistrationItems__c();
		cri.CampaignRegistration__c = cr.Id;
		cri.CampaignProduct__c      = cmList[0].Campaign_Products__r[0].Id;
		cri.CurrencyIsoCode         = 'USD';
		cri.DateOfPurchase__c       = System.today();
		cri.DealerName__c           = 'Other';
		cri.PricePaidPerUnit__c     = 10.00;
		cri.Quantity__c             = 1;
		cri.SerialNumber__c         = '1234567890';

		Test.startTest();
			try{
				insert cri;
			}catch(Exception ex){
				System.assertEquals(true, ex.getMessage().contains( 'Record currency : USD does not match select campaign product currency : GBP' ) );
			}
		Test.stopTest();
	}

    @isTest
	public static void testCashbackFixedCalculation(){
		List<Campaign> cmList = [SELECT Id, (SELECT Id FROM Campaign_Products__r WHERE CashbackCalculationPreference__c = 'Fixed')
										FROM Campaign WHERE RecordType.Name = 'Cashback'];
		System.assertEquals(1, cmList.size() );
		System.assertEquals(1, cmList[0].Campaign_Products__r.size() );

		List<Contact> cList = [SELECT Id FROM Contact];
		System.assertEquals(1, cList.size() );

		List<Product2> pList = [SELECT Id FROM Product2 WHERE Name = 'Test_Prod_0'];
		System.assertEquals(1, pList.size() );

		CampaignRegistration__c cr = new CampaignRegistration__c();
		cr.BankAccountNumber__c = '12345678';
		cr.SortCode__c          = '123456';
		cr.Campaign__c          = cmList[0].Id;
		cr.CashbackStatus__c    = 'Pending POP Approval';
		cr.Contact__c           = cList[0].Id;
		cr.Country__c           = 'GB';
		cr.PopStatus__c         = 'Not Submitted For Approval';
		insert cr;
		System.assertNotEquals(null, cr.Id );

		List<CampaignRegistrationItems__c> criList = new List<CampaignRegistrationItems__c>();

		for( Integer i=0; i<2; i++){
			CampaignRegistrationItems__c cri = new CampaignRegistrationItems__c();
			cri.CampaignRegistration__c = cr.Id;
			cri.CampaignProduct__c      = cmList[0].Campaign_Products__r[0].Id;
			cri.CurrencyIsoCode         = 'GBP';
			cri.DateOfPurchase__c       = System.today();
			cri.DealerName__c           = 'Other';
			cri.PricePaidPerUnit__c     = 950.00 + (i*500);
			cri.Quantity__c             = 1;
			cri.SerialNumber__c         = '123456789' + i;
			criList.add(cri);
		}

		Test.startTest();
			insert criList;
		Test.stopTest();

		criList = [SELECT Id, CashbackAmount__c, SerialNumber__c FROM CampaignRegistrationItems__c];
		Integer count = 0;
		for(CampaignRegistrationItems__c cri : [SELECT Id, CashbackAmount__c, SerialNumber__c FROM CampaignRegistrationItems__c] ){
			if( cri.SerialNumber__c == '1234567890'){
				System.assertEquals(475.00, cri.CashbackAmount__c );
				count++;
			}else if( cri.SerialNumber__c == '1234567891'){
				System.assertEquals(500.00, cri.CashbackAmount__c );
				count++;
			}
		}
		System.assertEquals(2, count);
	}

    @isTest
	public static void testMaxRegistrationsPerContactInOneReg(){
		List<Campaign> cmList = [SELECT Id, (SELECT Id FROM Campaign_Products__r) FROM Campaign WHERE RecordType.Name = 'Cashback'];
		System.assertEquals(1, cmList.size() );
		System.assertEquals(2, cmList[0].Campaign_Products__r.size() );

		List<Contact> cList = [SELECT Id FROM Contact];
		System.assertEquals(1, cList.size() );

		List<Product2> pList = [SELECT Id FROM Product2 WHERE Name = 'Test_Prod_0'];
		System.assertEquals(1, pList.size() );

		CampaignRegistration__c cr = new CampaignRegistration__c();
		cr.BankAccountNumber__c = '12345678';
		cr.SortCode__c          = '123456';
		cr.Campaign__c          = cmList[0].Id;
		cr.CashbackStatus__c    = 'Pending POP Approval';
		cr.Contact__c           = cList[0].Id;
		cr.Country__c           = 'GB';
		cr.PopStatus__c         = 'Not Submitted For Approval';
		insert cr;
		System.assertNotEquals(null, cr.Id );

		List<CampaignRegistrationItems__c> criList = new List<CampaignRegistrationItems__c>();

		for( Integer i=0; i<3; i++){
			CampaignRegistrationItems__c cri = new CampaignRegistrationItems__c();
			cri.CampaignRegistration__c = cr.Id;
			cri.CampaignProduct__c      = cmList[0].Campaign_Products__r[0].Id;
			cri.CurrencyIsoCode         = 'GBP';
			cri.DateOfPurchase__c       = System.today();
			cri.DealerName__c           = 'Other';
			cri.PricePaidPerUnit__c     = 950.00;
			cri.Quantity__c             = 1;
			cri.SerialNumber__c         = '123456789' + i;
			criList.add(cri);
		}

		Test.startTest();
			Boolean exRaised = false;
			try{
				// Insert 3 reigsterations for the contact in 1 shot when only 2 are allowed.
				insert criList;
			}catch(Exception ex){
				exRaised = true;
				System.assertEquals(true, ex.getMessage().contains( 'Contact has already regeistered for Maximum products allowed for this campaign' ) );
			}
		Test.stopTest();
		System.assertEquals(true, exRaised);
	}

    @isTest
	public static void testMaxRegistrationsPerContactInMulReg(){
		List<Campaign> cmList = [SELECT Id, (SELECT Id FROM Campaign_Products__r) FROM Campaign WHERE RecordType.Name = 'Cashback'];
		System.assertEquals(1, cmList.size() );
		System.assertEquals(2, cmList[0].Campaign_Products__r.size() );

		List<Contact> cList = [SELECT Id FROM Contact];
		System.assertEquals(1, cList.size() );

		List<Product2> pList = [SELECT Id FROM Product2 WHERE Name = 'Test_Prod_0'];
		System.assertEquals(1, pList.size() );

		CampaignRegistration__c cr = new CampaignRegistration__c();
		cr.BankAccountNumber__c = '12345678';
		cr.SortCode__c          = '123456';
		cr.Campaign__c          = cmList[0].Id;
		cr.CashbackStatus__c    = 'Pending POP Approval';
		cr.Contact__c           = cList[0].Id;
		cr.Country__c           = 'GB';
		cr.PopStatus__c         = 'Not Submitted For Approval';
		insert cr;
		System.assertNotEquals(null, cr.Id );

		List<CampaignRegistrationItems__c> criList = new List<CampaignRegistrationItems__c>();

		for( Integer i=0; i<2; i++){
			CampaignRegistrationItems__c cri = new CampaignRegistrationItems__c();
			cri.CampaignRegistration__c = cr.Id;
			cri.CampaignProduct__c      = cmList[0].Campaign_Products__r[0].Id;
			cri.CurrencyIsoCode         = 'GBP';
			cri.DateOfPurchase__c       = System.today();
			cri.DealerName__c           = 'Other';
			cri.PricePaidPerUnit__c     = 950.00;
			cri.Quantity__c             = 1;
			cri.SerialNumber__c         = '123456789' + i;
			criList.add(cri);
		}
		insert criList;
		Boolean exRaised = false;
		Test.startTest();
			// Insert 1 reigsteration for the contact when only 2 are allowed and 2 are already created earlier
			try{
				CampaignRegistrationItems__c cri = new CampaignRegistrationItems__c();
				cri.CampaignRegistration__c = cr.Id;
				cri.CampaignProduct__c      = cmList[0].Campaign_Products__r[0].Id;
				cri.CurrencyIsoCode         = 'GBP';
				cri.DateOfPurchase__c       = System.today();
				cri.DealerName__c           = 'Other';
				cri.PricePaidPerUnit__c     = 950.00;
				cri.Quantity__c             = 1;
				cri.SerialNumber__c         = '123456789';
				insert cri;
			}catch(Exception ex){
				exRaised = true;
				System.assertEquals(true, ex.getMessage().contains( 'Contact has already regeistered for Maximum products allowed for this campaign' ) );
			}
		Test.stopTest();
		System.assertEquals(true, exRaised);
	}

}