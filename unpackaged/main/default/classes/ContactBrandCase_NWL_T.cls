/**
*
* @author: Krishna Radhakrishnan
*/

@isTest
private class ContactBrandCase_NWL_T {
	@testSetup
	static void commonTestSetup(){
		// Create Users for ecomingthe owner of the case.
        Profile serviceP = [SELECT id FROM Profile WHERE name = 'Newell System Administrator'];
        List<User> uList = new List<User>();
    	//user 1 for contact with no communities flag

    	 User serviceUser = new User(
                Email                 = 'serviceuser@test.com',
                EmailEncodingKey      = 'UTF-8',
                Lastname              = 'TULast1',
                Firstname             = 'TUFirst1',
                LanguageLocaleKey     = 'en_US',
                LocaleSidKey          = 'en_US',
                Country               = 'United States',
                TimeZoneSidKey        = 'America/Los_Angeles',
                Username              = 'contBrand1@test1.com',
                Alias                 = 'TU1',
                ProfileId               =  serviceP.Id,
                BusinessDepartment__c = 'Salesforce',
                LicenseRegion__c      = 'NA',
                LicenseDivision__c	  = 'Global');
            uList.add(serviceUser);

    	 User testUser = new User(
                Email                 = 'contactnocommflag@test.com',
                EmailEncodingKey      = 'UTF-8',
                Lastname              = 'TULast2',
                Firstname              = 'TUFirst2',
                LanguageLocaleKey     = 'en_US',
                LocaleSidKey          = 'en_US',
                Country               = 'United States',
                TimeZoneSidKey        = 'America/Los_Angeles',
                Username              = 'contBrand2@test2.com',
                Alias                 = 'TU2',
                ProfileId             =  serviceP.Id,
                BusinessDepartment__c = 'Salesforce',
                LicenseRegion__c      = 'NA',
                LicenseDivision__c	  = 'Global');
    	uList.add(testUser);
    	insert uList;
    	System.assertEquals( 2, uList.size() );


		// Create Cases. The primary case and the secondary Case
		GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();
		g.rtSettings( 'Consumer_Inquiry' , 'Case', 'Consumer' );
		// Generate Test Accounts
        List<Account> aList = g.account(1, 'Generic Consumer Account', 'United States', 'S');
        System.assertEquals(1, aList.size() );
        // Generate Test Contacts
        g.conMailingstreet      = '3 Glenlake Pkwy';
        g.conMailingCity        = 'Atlanta';
        g.conMailingStateCode   = 'Ga';
        g.conMailingPostalCode  = '30328';
        g.conMailingCountryCode = 'US';
        List<Contact> cList = g.contacts( 1, null, aList[0].Id, 'a@b.com' );
        System.assertEquals(1, cList.size() );

        // Generate Test cases
        g.csRecordType = 'Consumer_Inquiry';
        g.csSalesOrg   = 'US01';
        g.csConId      = cList[0].Id;


        //Makethe owner id as service User.
        User tUsr = [SELECT Id FROM USER WHERE LastName='TUlast1' AND FirstName = 'TUFirst1' LIMIT 1];
        g.csOwnerId = tUsr.Id;

        List<Case> csList1 = g.case2( 4, 'Open', 'ContactBrandCase_', 'Email', 'Other', 'Newell' );
        System.assertEquals(4, csList1.size() );
        List<Attachment> attchList = g.attachmentsToCase(2,csList1,'Image/jpg');
        System.assertEquals(8, attchList.size() );

        GlobalValuesNWL__c gv = new GlobalValuesNWL__c();
        gv.Name     = 'ContactBrandOldCaseLastDays';
        gv.Value__c = '30';
        Insert gv;

	}

	@isTest static void noCheckBoxSelected() {
		// Take the first test case and use it as the reference. No check box selected
		Case masterCs = [SELECT Id FROM CASE WHERE SUBJECT = 'ContactBrandCase_0' AND BRAND__C = 'Newell' LIMIT 1];

		User tUsr = [SELECT Id FROM USER WHERE LASTNAME='TULast2' AND FirstName = 'TUFirst2' LIMIT 1];
		System.runAs(tUsr){
			Boolean excOccured = false;
			Test.startTest();
			
			try{
				ApexPages.StandardController sCon = new ApexPages.StandardController(masterCs);
				ContactBrandCase_NWL cont = new ContactBrandCase_NWL(sCon);
				cont.mergeCases();
			}catch(Exception ex){
				excOccured = true;
			}
				
			Test.stopTest();
			System.assert(excOccured, 'An exception thrown');
		}
	}

	@isTest static void allCheckBoxSelected() {
		// Take the first test case and use it as the reference. All checkbox seleected
		Case masterCs = [SELECT Id FROM CASE WHERE SUBJECT = 'ContactBrandCase_0' AND BRAND__C = 'Newell' LIMIT 1];

		User tUsr = [SELECT Id FROM USER WHERE LASTNAME='TULast2' AND FirstName = 'TUFirst2' LIMIT 1];
		System.runAs(tUsr){
			Test.startTest();
				ApexPages.StandardController sCon = new ApexPages.StandardController(masterCs);
				ContactBrandCase_NWL cont = new ContactBrandCase_NWL(sCon);
				// Check the checkbox of all the three cases
				List<ContactBrandCase_NWL.CaseWrapper> csWrapperListT = cont.csWrapperList;
				for(ContactBrandCase_NWL.CaseWrapper csWrapper : csWrapperListT ){
					csWrapper.selected = true;
				}
				cont.csWrapperList = csWrapperListT;
				cont.mergeCases();

			Test.stopTest();

			Integer count = 0;
			List<Case> finCsList = [SELECT Id,OwnerId,Status,Reason__c,Resolution__c,Subject FROM CASE WHERE SUBJECT IN ('ContactBrandCase_0','ContactBrandCase_1','ContactBrandCase_2','ContactBrandCase_3','Merged to Parent')];
			Set<Id> nonParentCsIdSet = new Set<Id>();
			Id parentId;
			Integer closedCaseCount = 0;
			Integer nonClosedCaseCount = 0;
			for(Case cs : finCsList ){
				if(cs.Status == 'Closed') {closedCaseCount += 1; nonParentCsIdSet.add(cs.Id);}
				if(cs.Status != 'Closed') {nonClosedCaseCount += 1; parentId = cs.Id;}
			}
			System.assertEquals(closedCaseCount,3);
			System.assertEquals(nonClosedCaseCount,1);

			List<Attachment> attList = [SELECT Id, Name,Body, Description, ContentType,ParentId  From Attachment WHERE
                IsDeleted=false AND ParentId = :parentId];
            List<ContentDocumentLink> links=[SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink where LinkedEntityId = :parentId];
            Set<Id> ids=new Set<Id>();	
            for(ContentDocumentLink link:links)
            {
                ids.add(link.ContentDocumentId);
            }
            List<ContentVersion> cvList=[SELECT Id,VersionData,Title,ContentDocumentId,FileExtension,FileType FROM ContentVersion 
                                        WHERE ContentDocumentId in :ids AND IsLatest = true ORDER BY CreatedDate DESC];
            System.assertEquals(attList.size()+cvList.size(),8);


		}
	}
	@isTest static void noRelatedCasesExist() {
		GenerateTestData_NWL_T testDataGen = new GenerateTestData_NWL_T();

		List<Account> accounts = testDataGen.account(1, 'Test Account', 'Canada', null);

		Case cs = new Case(Status = 'Open', Subject = 'NoRelatedCase_0', Origin = 'Email', Reason = 'defect', Brand__c = 'Dymo', AccountId = accounts[0].Id, CaseGroup__c = 'Customer');
		insert cs;

		Case masterCs = [SELECT Id FROM CASE WHERE SUBJECT = 'NoRelatedCase_0' AND BRAND__C = 'Dymo' LIMIT 1];
		User tUsr = [SELECT Id FROM USER WHERE LASTNAME='TULast2' AND FirstName = 'TUFirst2' LIMIT 1];
		System.runAs(tUsr){
			Boolean excOccured = false;
			Test.startTest();
				try{
					ApexPages.StandardController sCon = new ApexPages.StandardController(masterCs);
					ContactBrandCase_NWL cont = new ContactBrandCase_NWL(sCon);
					cont.mergeCases();
				}catch(Exception ex){
					excOccured = true;
				}
			Test.stopTest();
			System.assert(excOccured, 'An exception thrown');
		}
	}



}