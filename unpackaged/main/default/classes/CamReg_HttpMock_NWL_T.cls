@isTest
global class CamReg_HttpMock_NWL_T implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        //System.assertEquals('http://api.salesforce.com/foo/bar', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());

        // Create a fake response
        HttpResponse res = new HttpResponse();
        //res.setHeader('Content-Type', 'application/json');
        res.setBody('"success"');
        res.setStatusCode(200);
        return res;
    }
}