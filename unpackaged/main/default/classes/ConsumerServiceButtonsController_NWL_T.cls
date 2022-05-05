@isTest
public class ConsumerServiceButtonsController_NWL_T {

    @testSetup
    static void commonTestSetup(){

    GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();

    g.contacts(1,'Test',null,'test@test.com');
    g.rtSettings( 'Consumer_Inquiry' , 'Case', 'Consumer' );

    g.csRecordType = 'Consumer_Inquiry';
    g.case(1, 'Open', 'Test Subject', 'Email', 'Information', 'Graco');

    g.prodEan11 = '123456789';
    g.productData(1,'test');

    GlobalSwitchNWL__c gs = g.globalSwitchSettings('SendOrderAck',true);

    // Generate Brand Data
    Brand__c b = g.brand( GenerateTestData_NWL_T.C_BRAND_GRACO );
    System.assert( b != null );
    
    GlobalValuesNWL__c gv = g.globalValues( Utility_NWL.getOrgBasedKey('PCAKey'), 'test123#' );
    System.assertNotEquals( gv, null );

    List<Order_Index__c> orderList = g.orderIndex(1, null, 'Test_PP_', 'FR010102');
        System.assertEquals( orderList.size(),1);
        orderList[0].DeliveryBlockKey__c = 'C2';
        orderList[0].CurrencyIsoCode = 'EUR';
        orderList[0].SAP_Ship_To_Number__c = '009287373';
        orderList[0].Distribution_Channel__c = '04';
        orderList[0].POTypeKey__c = 'ZGCR';
        update orderList;
    

    }

    static testMethod void testcreateCaseProduct(){

        test.startTest();
        List<Product2> pList = [SELECT Id FROM Product2 LIMIT 1];
        List<Case> cList = [SELECT Id FROM Case LIMIT 1];

        ConsumerServiceButtonsController_NWL.createCaseProduct(pList[0].Id, cList[0].Id);

        List<Case_Product__c> cpList = [SELECT Id FROM Case_Product__c LIMIT 1];

        system.assertEquals(cpList.size(),1);

        test.stopTest();

    }

   

    static testMethod void testcreatequickCase(){

        test.startTest();
        List<Contact> lstCon = [SELECT Id,FirstName,LastName,Email FROM Contact LIMIT 1];
        List<Order_Index__c> oList = [SELECT Id FROM Order_Index__c LIMIT 1 ];
        ConsumerServiceButtonsController_NWL.createquickCase(lstCon[0].id, 'Graco', null, 'Information', 'Test Subject', 'description', '012i00000011kxV', oList[0].Id);

        List<Case> lstcase = [SELECT Id,Brand__c,Reason__c,Resolution__c,Status,Description FROM Case LIMIT 1];
        Test.stopTest();

        system.assertEquals(lstcase[0].Brand__c, 'Graco');
        system.assertEquals(lstcase.size(), 1);
        system.assertEquals(lstcase[0].Reason__c, 'Information');

    }


    static testMethod void testupdateSpamCase(){

        test.startTest();
        List<Case> cList = [SELECT Id,CaseNumber,Brand__c,Subject,Status,Resolution__c FROM Case LIMIT 1];
        ConsumerServiceButtonsController_NWL.updateSpamCase(cList[0].Id, cList[0].Brand__c,cList[0].Subject);

        Test.stopTest();

        List<Case> spamList = [SELECT Id,CaseNumber,Brand__c,Subject,Status,Reason__c,Resolution__c FROM Case WHERE Id =: cList[0].Id ];
        List<CaseComment> commentList = [SELECT Id, CommentBody, ParentId FROM CaseComment WHERE ParentId =: spamList[0].Id];

        System.assertEquals(spamList.size(), 1);
        System.assertEquals(spamList[0].Resolution__c, 'Other Action-Spam-Auto Close');
        System.assertEquals(spamList[0].Reason__c, 'Spam');
        System.assertEquals(commentList.Size(), 1);
        System.assertEquals(commentList[0].commentBody, 'Spam Case');
    }

    static testMethod void testupdateSpamCase_NoBrand(){

        test.startTest();
        //create case with null brand and null subject
        GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();
        g.csRecordType = 'Consumer_Inquiry';
        List<Case> cList = g.case(1, 'Open', null, 'Email', 'Information', null);
        ConsumerServiceButtonsController_NWL.updateSpamCase(cList[0].Id, cList[0].Brand__c,cList[0].Subject);

        Test.stopTest();

        List<Case> spamList = [SELECT Id,CaseNumber,Brand__c,Subject,Status,Reason__c,Resolution__c FROM Case WHERE Id =: cList[0].Id ];

        System.assertEquals(spamList.size(), 1);
        System.assertEquals(spamList[0].Resolution__c, 'Other Action-Spam-Auto Close');
        System.assertEquals(spamList[0].Reason__c, 'Spam');
        System.assertEquals(spamList[0].Brand__c, 'Newell');
        System.assertEquals(spamList[0].Subject, 'Spam Case');

    }

    static testMethod void testgetCustomSettingByRecordType(){
        test.startTest();

        List<Case> cList = [SELECT Id,CaseNumber FROM Case LIMIT 1];
        Object result = ConsumerServiceButtonsController_NWL.getCustomSettingByRecordType(cList[0].Id);

        test.stopTest();

        system.assert(result !=null);


    }


    static testMethod void testsearchCasesfromContact(){
        test.startTest();

        GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();

        List<Contact> conList = [SELECT Id FROM Contact LIMIT 1];

        g.csConId = conList[0].Id;
        g.csRecordType = 'Consumer_Inquiry';
        g.case(3, 'Open', 'Test Subject', 'Email', 'Information', 'Graco');

        List<Case> cList = [SELECT Id,CaseNumber FROM Case];

        
        ConsumerServiceButtonsController_NWL.quickCaseWrapper qcWrap = ConsumerServiceButtonsController_NWL.searchCasesfromContact(conList[0].Id);
    

        test.stopTest();
    }


    static testMethod void testSearchContactsPass(){
        test.startTest();

        List<contact> searchResult = ConsumerServiceButtonsController_NWL.searchContacts('', '', 'test@test.com', '', '', '', '', '', '', '', '', '');
        system.assertEquals(searchResult.size(),1);
        test.stopTest();
    }

    static testMethod void testSearchContactsFail(){
        test.startTest();

        List<contact> searchResult = ConsumerServiceButtonsController_NWL.searchContacts('Test', 'BadContact', 'Bad.test@newellco.com', '123-123-1231', '27301', 'US', 'NC', 'Greensboro', 'APAC', 'English','','');
        test.stopTest();
    }


    static testMethod void testsearchProducts(){

        test.startTest();
        GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();

        g.prodBrand = 'DY00';
        g.prodBrandDesc= 'DYMO';
        g.prodEan11 = '111222333444';

        List<Product2> plist = g.productData(1,'DYMO Product_');

        pList[0].IsActive = True;
        update pList;

        //Successful Search
        List<Product2> searchResult = ConsumerServiceButtonsController_NWL.searchProducts('DYMO Product_0','','','DYMO','111222333444','','','','','','','','','','','','','','','');
        system.assertEquals(searchResult.size(),1);


        //No products returned
        List<Product2> searchResult2 = ConsumerServiceButtonsController_NWL.searchProducts('DYMO Product_0','test','test','DYMO','111222333444','test','test','test','test','test','test','test','test','test','test','test','test','test','test','test');

        test.stopTest();
    }


    static testMethod void testSendOrdAckEmail(){

        test.startTest();
        GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();

        g.csRecordType = 'Consumer_Inquiry';
        List<Case> csList = g.case(2, 'Open', 'Test Subject', 'Web', 'Defect', 'Office');

        List<Contact> conList = [SELECT Id,FirstName,LastName,Email FROM Contact WHERE Email = 'test@test.com'];

        csList[0].ContactId = ConList[0].Id;
        update csList;

        String caseId = string.valueOf(csList[0].Id);
        String caseId2 = string.valueOf(csList[1].Id);


        try{
            String ordAck = ConsumerServiceButtonsController_NWL.sendOrdAckEmail(caseId2);
        }catch(Exception e){}

        try{
            String ordAck = ConsumerServiceButtonsController_NWL.sendOrdAckEmail(caseId);
          }catch(Exception e){}

        List<Order_Index__c> orderList = [SELECT Id,Name FROM Order_Index__c LIMIT 1];

        Case_Order__c cOrder = new Case_Order__c();
        cOrder.Case__c = csList[0].id;
        cOrder.Order__c = orderList[0].id;
        insert cOrder;
        
        try{
            String ordAck = ConsumerServiceButtonsController_NWL.sendOrdAckEmail(caseId);
        }catch(Exception e){}

        
        test.stopTest();
    }


    static testMethod void testsendAttachEmail(){

        test.startTest();
        GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();
        g.csRecordType = 'Consumer_Inquiry';
        List<Case> csList = g.case(2, 'Open', 'Test Subject', 'Web', 'Defect', 'Office');
        String caseId = string.valueOf(csList[0].Id);

        List<Contact> con = [SELECT Id FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        csList[0].ContactId = con[0].Id;
        update csList;

        String msg = ConsumerServiceButtonsController_NWL.sendAttachEmail(caseId);
        System.assertEquals(msg, 'Email notification created successfully');

        test.stopTest();

    }

    static testMethod void testsendEmailAR(){

        test.startTest();
        GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();
        g.csRecordType = 'Consumer_Inquiry';
        List<Case> csList = g.case(2, 'Open', 'Test Subject', 'Web', 'Defect', 'Office');
        String caseId = string.valueOf(csList[0].Id);
        String caseId2 = string.valueOf(csList[1].Id);

        List<Contact> con = [SELECT Id FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        csList[0].ContactId = con[0].Id;
        update csList;

        //success
        String msg = ConsumerServiceButtonsController_NWL.sendEmailAR(caseId,'Waiting For Payment');
        system.assertEquals(msg, 'Email message request submitted successfully !');

        //failure no contact
        try{
            String msg2 = ConsumerServiceButtonsController_NWL.sendEmailAR(caseId2,'Waiting For Payment'); 
            system.assertEquals(msg2, 'No contact or contact email address found');
        }catch(Exception e){}

        //failure no case
        try{
            String msg3 = ConsumerServiceButtonsController_NWL.sendEmailAR('123456789123456','Waiting For Payment'); 
            system.assertEquals(msg3, 'No Case found. Contact your system Administrator');
        }catch(Exception e){}

        test.stopTest();
    }

    static testMethod void testsendPaymentEmail(){

        test.startTest();
        GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();
        g.csRecordType = 'Consumer_Inquiry';
        List<Case> csList = g.case(2, 'Open', 'Test Subject', 'Web', 'Defect', 'Office');
        List<Order_Index__c> orderList = [SELECT Id,Name FROM Order_Index__c LIMIT 1];
        String caseId = string.valueOf(csList[0].Id);

        Case_Order__c cOrder = new Case_Order__c();
        cOrder.Case__c = csList[0].id;
        cOrder.Order__c = orderList[0].id;
        insert cOrder;

        String msg = ConsumerServiceButtonsController_NWL.sendPaymentEmail(caseId,'Waiting For Payment');


        test.stopTest();
    }

    static testMethod void testsendPaymentEmail_OMS(){

        test.startTest();
        GenerateTestData_NWL_T g = new GenerateTestData_NWL_T();
        g.csRecordType = 'Consumer_Inquiry';
        List<Case> csList = g.case(2, 'Open', 'Test Subject', 'Web', 'Defect', 'Office');
        g.ordNumPrefix = '2';
        g.oiRecordType = 'OMS_Order';
        List<Order_Index__c> orderList = g.orderIndex(2, null, 'Test_OMS', null);

        orderList[0].DeliveryBlockKey__c = 'C2';
        orderList[0].CurrencyIsoCode = 'EUR';
        orderList[0].SAP_Ship_To_Number__c = '009287373';
        orderList[0].Distribution_Channel__c = '04';
        orderList[0].POTypeKey__c = 'ZGCR';
        update orderList;

        String caseId = string.valueOf(csList[1].Id);

        Case_Order__c cOrder = new Case_Order__c();
        cOrder.Case__c = csList[1].id;
        cOrder.Order__c = orderList[1].id;
        insert cOrder;

        String msg = ConsumerServiceButtonsController_NWL.sendPaymentEmail(caseId,'Waiting For Payment');


        test.stopTest();
    }


}