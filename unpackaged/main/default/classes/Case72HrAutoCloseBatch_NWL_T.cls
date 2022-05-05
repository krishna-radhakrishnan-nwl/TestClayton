/**
* File.......... : Case72HrAutoCloseBatch_NWL_T
* @author....... : Krishna Radhakrishnan
* @version...... : 1.0
* @createdDate.. : 19-Feb-2019
* Description... : Test class for Case72HrAutoCloseBatch_NWL
*
*/
@isTest
private class Case72HrAutoCloseBatch_NWL_T {

      public static testMethod void testRunAs() {
            // Setup test data
            // Create a unique UserName
            String uniqueUserName = 'intuser' + DateTime.now().getTime() + '@testorg.com';
            // This code runs as the system user
            Profile p = [SELECT Id FROM Profile WHERE Name='Newell Integration Profile'];
            User u = new User(Alias = 'intuser', Email='intuser@testorg.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',BusinessDepartment__c='IT',
            LicenseRegion__c = 'NA',LicenseDivision__c='Newell',
            UserName=uniqueUserName);
      
            // Implement test code
            GenerateTestData_NWL_T genTestData = new GenerateTestData_NWL_T();
            genTestData.rt72HrAutoClose = true;
            genTestData.rtSettings( 'Consumer_Default', 'Case', 'Consumer' );
            genTestData.csRecordType = 'Consumer_Default';
            genTestData.csNotesSAP   = 'Test Note';

            //create contact
            List<Contact> ctList = genTestData.contacts(1,'Test',null,'Test@test.com');
            
            // Create Cases
            List<Case> csList = genTestData.case( 1, 'Waiting on Consumer', 'Waiting On Consumer Test_', 'Email', Case72HrAutoCloseBatch_NWL.C_CASE_REASON_INFORMATION, 'Graco' );
            System.assertEquals( csList.size(), 1 );

            //add case comment
            CaseComment cc = new CaseComment();
            cc.ParentId = csList[0].Id;
            cc.CommentBody = 'Test Single Comment';
            insert cc;


            // Setting the AutoFollowUpEmailUpdate to a past date so that the query will pick up.
            DateTime d = DateTime.now().addDays(-10);
            csList[0].AutoFollowUpEmailDate__c = d;
            csList[0].New_Email_From_Customer__c = false;
            csList[0].contactId = ctList[0].Id;
            update csList[0];
      
            System.runAs(u) {
                  // The following code runs as user 'u'
                  Test.startTest();
                  Case72HrAutoCloseBatch_NWL cBatch = new Case72HrAutoCloseBatch_NWL();
                  Database.executeBatch(cBatch, 10);
                  Test.stopTest();
                }

            // Do System asserts on the case. Case should have status as closed
            List<Case> cUpdList = [SELECT Id, Status, CaseGroup__c, Resolution__c, Reason__c,AutoFollowUpEmailDate__c FROM Case LIMIT 1];
            System.assertEquals(cUpdList[0].Status, Case72HrAutoCloseBatch_NWL.C_CASE_STATUS_CLOSED);
            System.assertEquals(cUpdList[0].CaseGroup__c, Case72HrAutoCloseBatch_NWL.C_CASEGROUP_CONSUMER);
            System.assertEquals(cUpdList[0].Resolution__c, Case72HrAutoCloseBatch_NWL.C_CASE_RESOLUTION_SYS_AUTO_CLOSE);
            System.assertEquals(cUpdList[0].Reason__c, Case72HrAutoCloseBatch_NWL.C_CASE_REASON_INFORMATION);
          }

      @isTest static void testSuccess() {
            // Implement test code
            GenerateTestData_NWL_T genTestData = new GenerateTestData_NWL_T();
            genTestData.rt72HrAutoClose = true;
            genTestData.rtSettings( 'Consumer_Default', 'Case', 'Consumer' );
            genTestData.csRecordType = 'Consumer_Default';
            genTestData.csNotesSAP   = 'Test Note';

            // Create Cases
            List<Case> csList = genTestData.case( 1, 'Waiting on Consumer', 'Waiting On Consumer Test_', 'Email', Case72HrAutoCloseBatch_NWL.C_CASE_REASON_INFORMATION, 'Graco' );
            System.assertEquals( csList.size(), 1 );

            //add case comment
            CaseComment cc = new CaseComment();
            cc.ParentId = csList[0].Id;
            cc.CommentBody = 'Test Single Comment';
            insert cc;


            List<Contact> conList = genTestData.contacts( 1,'B',null, 'test72hr@test.com' );

            csList[0].ContactId = conList[0].Id;

            update csList;

            // Setting the AutoFollowUpEmailUpdate to a past date so that the query will pick up.
            DateTime d = DateTime.now().addDays(-10);
            csList[0].AutoFollowUpEmailDate__c = d;
            csList[0].New_Email_From_Customer__c = false;
            update csList[0];

            Test.startTest();
                  Case72HrAutoCloseBatch_NWL cBatch = new Case72HrAutoCloseBatch_NWL();
                  Database.executeBatch(cBatch, 10);
            Test.stopTest();

            // Do System asserts on the case. Case should have status as closed
            List<Case> cUpdList = [SELECT Id, Status, CaseGroup__c, Resolution__c, Reason__c,AutoFollowUpEmailDate__c FROM Case LIMIT 1];
            System.assertEquals(cUpdList[0].Status, Case72HrAutoCloseBatch_NWL.C_CASE_STATUS_CLOSED);
            System.assertEquals(cUpdList[0].CaseGroup__c, Case72HrAutoCloseBatch_NWL.C_CASEGROUP_CONSUMER);
            System.assertEquals(cUpdList[0].Resolution__c, Case72HrAutoCloseBatch_NWL.C_CASE_RESOLUTION_SYS_AUTO_CLOSE);
            System.assertEquals(cUpdList[0].Reason__c, Case72HrAutoCloseBatch_NWL.C_CASE_REASON_INFORMATION);
      }

      /**
      * Test failure is replicted by  introducing a custom field Exception of the validation rule
      * 'Change_Newell_Brand_to_close' is the validation rule. For this validation rule, for certain record types,
      * we cannot change the brand to 'Newell' when closed. That validation rule is broken in this test failure method.
      * If the validation rule is changed in the future, this test class will fail and needs to be reworked.
      *
      */
      @isTest static void testFailure() {
            GenerateTestData_NWL_T genTestData = new GenerateTestData_NWL_T();
            genTestData.rt72HrAutoClose = true;
            genTestData.rtSettings( 'General_Inquiry', 'Case', 'Consumer' );

            genTestData.csRecordType = 'General_Inquiry';

            // Create Cases
            List<Case> csList = genTestData.case( 1, 'Waiting on Consumer', 'Waiting On Consumer Test_', 'Email', 'Other', 'Graco' );
            System.assertEquals( csList.size(), 1 );
            csList[0].Brand__c = 'Newell';
            // Setting the AutoFollowUpEmailUpdate to a past date so that the query will pick up.
            DateTime d = DateTime.now().addDays(-10);
            csList[0].AutoFollowUpEmailDate__c = d;
            update csList[0];

            Test.startTest();
                  Case72HrAutoCloseBatch_NWL cBatch = new Case72HrAutoCloseBatch_NWL();
                  Database.executeBatch(cBatch, 10);
            Test.stopTest();

            // Do System asserts on the case. Case should have status as closed
            List<Case> cUpdList = [SELECT Id, Status, CaseGroup__c, Resolution__c, Reason__c,AutoFollowUpEmailDate__c FROM Case LIMIT 1];
            System.assertEquals(cUpdList[0].Status, Case72HrAutoCloseBatch_NWL.C_CASE_STATUS_WAIT_INT_DATA);
      }
}