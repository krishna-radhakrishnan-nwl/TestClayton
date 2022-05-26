import { LightningElement,wire, api, track } from 'lwc';
import getinitdata from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.getinitdata';
import getoptions from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.getoptions';
import loadPaymentFramelwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.loadPaymentFramelwc';
import loadOrderFormlwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.loadOrderFormlwc';
import updateBrandLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.updateBrandLwc';
import updateSubBrandLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.updateSubBrandLwc';
import searchProductsLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.searchProductsLwc';
import simulateSalesOrderLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.simulateSalesOrderLwc';
import addProductsToOrderLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.addProductsToOrderLwc';
import removeProductsFromOrderLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.removeProductsFromOrderLwc';
import CreateOmsOrdLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.CreateOmsOrderLwc';
import getGCBalanceLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.getGCBalanceLwc';
import addGiftCardToOrderLWC from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.addGiftCardToOrderLWC';
import removeGiftCardFromOrderLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.removeGiftCardFromOrderLwc';
import explodeBomLWC from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.explodeBomLWC';
import addCouponCodeLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.addCouponCodeLwc';
import removeCouponLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.removeCouponLwc';
import remAllProductsFromCartLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.remAllProductsFromCartLwc';
import clearBomComponentsLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.clearBomComponentsLwc';
import addAllProductsToCartLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.addAllProductsToCartLwc';
import UpdateOPDiscountLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.UpdateOPDiscountLwc';
import getOrderNumberLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.getOrderNumberLwc';
import reTokenizeCCLwc from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.reTokenizeCCLwc';
import getVFOrigin from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.getVFOrigin';
// Import custom labels
import validateMsg from '@salesforce/label/c.PAYM_RequiredValidator';
import GRAPHICS_PACK from '@salesforce/resourceUrl/GraphicsPack';
//import FLEX_MICROFORM from '@salesforce/resourceUrl/flex_microform';
//import POSTCODE_ADDR_SCRIPT from '@salesforce/resourceUrl/postcode_address_script';
//import POSTCODE_ADDR_STYLE from '@salesforce/resourceUrl/postcode_address_style';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { loadScript,loadStyle } from 'lightning/platformResourceLoader';

export default class OmsCreateOrder extends NavigationMixin(LightningElement) {
    label = { validateMsg };
    @track showSpinner = false;
    @api caseId;

    flagGreen = GRAPHICS_PACK + '/32/fatcow/farmfresh/flag_green.png';
    flagYellow = GRAPHICS_PACK + '/32/fatcow/farmfresh/flag_yellow.png';
    flagRed = GRAPHICS_PACK + '/32/fatcow/farmfresh/flag_red.png';
    cross = GRAPHICS_PACK + '/16/famfamfam/silk/cross.png';

    activeSections = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

    //Spinners
    @track showHeaderSpinner = false;
    @track showSearchSpinner = false;

    @track brands;
    @track dataoms;
    @track subBrands;
    @track orderTypes;
    @track shippingMethods;
    @track orderReasons;
    @track ccExpYears;
    @track ccExpMonths;
    @track ccTypes;
    @track itemLevelDiscounts;
    @track holdProductReturn;
    c_BLANK = '---';

    //Expression flags
    @track isBrandSelected = false;
    @track isSimOrderGrossTotal = false;
    @track isBomCompListEmpty = false;
    @track isOrderProdListEmpty = false; 
    @track showCredCard = false;  
    @track so__cc_paymiFrameWrapper = true;
    @track so__cc_paymiFrameMessage = false;
    @track giftCardsListEmpty = false;
    @track couponsSecEnable = false;
    @track pcIpalFrame = true;
    @track pcIpalMessage = false;
    @track pcIpalMessageClr = '';

    @track actveTab = "one";
    @track isAddrLoaded = false;
    @track errors = [];
    @track siteUrl = '/apex/CreditCardOMS_NWL';

    @track credInfo;
    @track isSerachError = false;

    // Wire getVFOrigin Apex method to a Property
    @wire(getVFOrigin)
    vfOrigin;
  
    connectedCallback() {
        console.log('init');
        this.showSpinner = true;
        // to get all constructor data
        getinitdata(
            {
                recordId: this.caseId
            }).then(data => {                
                console.log(JSON.stringify(data));                
                this.dataoms = JSON.parse(JSON.stringify(data));                 
                this.reloadExpressions();              
                //this.loadOrderForm();
                getoptions(
                    {
                        /*recordId: this.caseId,
                        isCase: this.dataoms.isCase,
                        isContact: this.dataoms.isContact*/
                        recordId: this.caseId,
                        datainstance: JSON.stringify(this.dataoms)    
                    }).then(data => {   
                        this.getOrderNumber();                                                                   
                        //this.dataoms = JSON.parse(JSON.stringify(data)); 
                        this.brands = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.subBrands = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.orderTypes = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.shippingMethods = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.orderReasons = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ccExpYears = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ccExpMonths = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ccTypes = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.itemLevelDiscounts = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.holdProductReturn = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        for (const [key, value] of Object.entries(data.brands)) {
                            this.brands.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.subBrands)) {
                            this.subBrands.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.orderTypes)) {
                            this.orderTypes.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.shippingMethods)) {
                            this.shippingMethods.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.orderReasons)) {
                            this.orderReasons.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.ccExpYears)) {
                            this.ccExpYears.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.ccExpMonths)) {
                            this.ccExpMonths.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.itemLevelDiscounts)) {
                            this.itemLevelDiscounts.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.ccTypes)) {
                            this.ccTypes.push({ label: value, value: key });
                        }  
                        for (const [key, value] of Object.entries(data.holdProductReturn)) {
                            this.holdProductReturn.push({ label: value, value: key }); 
                        }                     
                        console.log('orderTypes' + JSON.stringify(this.orderTypes));  
                        this.showSpinner = false;                                                               
                    }).catch(error => {
                        this.showSpinner = false;
                    })

            }).catch(error => {
                this.showSpinner = false;
                console.log(JSON.stringify(error));                
            })
            window.addEventListener( "message", this.handleResponse.bind(this), false );
    }

    handleResponse(message){
        console.log('handleResponse');
        // check the origin match for both source and target
        if (message.origin.indexOf(this.vfOrigin.data) !== -1) {
            let credInfo = JSON.parse(message.data);
            this.dataoms.ccNumber = credInfo.ccName;
            this.dataoms.ccName = credInfo.cardholderName;
            this.dataoms.selectedCcType = credInfo.cardType;
            this.dataoms.selectedCcExpMonth = credInfo.expMonth;
            this.dataoms.selectedCcExpYear = credInfo.expYear;
            this.dataoms.ccCvv = credInfo.cvv;   
            this.dataoms.ccIsTokenized = credInfo.ccIsTokenized;                     
            this.dataoms.ccLast4 = credInfo.ccLast4;                   
            console.log('credInfo='+credInfo);
        }
    }

    key_Code_Checker(component, event, helper){
        if (component.which == 13){
            this.searchProducts();
        }
    }

    reloadExpressions(){
        if(this.dataoms.simOrderGrossTotal > 0.00){
            this.isSimOrderGrossTotal = true;
        } 
        this.showCredCard = this.dataoms.sendPaymentEmail === false && this.dataoms.showCcTab && this.dataoms.ccOrderPhone ? true : false;        
        this.isBomCompListEmpty = this.dataoms.bomComponentsList !== undefined && this.dataoms.bomComponentsList !== null && this.dataoms.bomComponentsList.length > 0 ? false : true;                    
        this.isOrderProdListEmpty = this.dataoms.orderProductsList !== undefined && this.dataoms.orderProductsList !== null && this.dataoms.orderProductsList.length > 0 ? false : true;  
        this.giftCardsListEmpty = this.dataoms.giftCardsList !== undefined && this.dataoms.giftCardsList !== null && this.dataoms.giftCardsList.length > 0 ? false : true;
        this.couponsSecEnable = this.dataoms.brandSelected && this.dataoms.pageRender && this.dataoms.enableOCAPICallout ? true : false;            
        this.highlightErrorPanel(); 
        /*if(this.dataoms.sendPaymentEmail){
            this.template.querySelector('.send-pay-email-chk').checked = true; 
        }else{
            this.template.querySelector('.send-pay-email-chk').checked = false; 
        }*/    
    }

    setSimulateOrderFlag(){
        this.dataoms.ordSimulateRequired = true;
    }

    setSelectedOption(event){
        let val = event.target.value;
        if(event.target.name === 'shippingMethod'){
            this.dataoms.selectedShippingMethod = val;
            this.dataoms.ordSimulateRequired = true;
        }
        else if(event.target.name === 'orderReason'){
            this.dataoms.selectedOrderReason = val;
            this.dataoms.ordSimulateRequired = true;
        }
    }

    setSelectedBox(event){
        let val = event.target.checked;
        if(event.target.name === 'waiveShipping'){
            this.dataoms.waiveShipping = val;
            this.dataoms.ordSimulateRequired = true;
        }else if(event.target.name === 'applyCredit'){
            this.dataoms.applyCredit = val;
            this.dataoms.ordSimulateRequired = true;
        }
    }

    setHoldProductReturn(event){
        this.dataoms.selectedProductReturnVal = event.target.value;
    }

    loadPaymentFrame(event) {
        let val = false;
        if(event){
            event.preventDefault();
            let val = event.target.checked;      
            this.dataoms.sendPaymentEmail = val;
        }
        this.showCredCard = (val === false && this.dataoms.showCcTab && this.dataoms.ccOrderPhone) ? true : false;                        
        if(val === false){
            this.showSpinner = true;
            loadPaymentFramelwc(
                {
                    recordId: this.caseId,
                    datainstance: JSON.stringify(this.dataoms)
                }).then(data => {
                    this.dataoms = JSON.parse(JSON.stringify(data));
                    this.siteUrl = '/apex/CreditCardOMS_NWL?brand='+this.dataoms.brand+'&subBrand='+this.dataoms.subBrand+'&cybMerchantId='+this.dataoms.cybMerchantId+'&ccIsTokenized='+this.dataoms.ccIsTokenized;                   
                    this.template.querySelector('.active-tab-value').activeTabValue = "three";                              
                    console.log(data);
                    let _this = this;
                    if(this.dataoms.allowPCIPalPayment){
                        setTimeout(() => {   
                            _this.setUpPCIPalPayment();                                                                                                    
                        }, 500);                                           
                    }else{
                        setTimeout(() => {                                                                        
                            _this.showSpinner = false;
                        }, 4000); 
                    }                                
                }).catch(error => {
                    this.showSpinner = false;
                    console.log(error);
                })
        }    
    }

    sendMessgaeToVisualForce() {
        let message = {
            message : this.messageToSend,
            source  : 'LWC'
        };        
        let visualForce = this.template.querySelector("iframe");
        if( visualForce ){
            visualForce.contentWindow.postMessage(message, this.vfOrigin.data);
        }
        
    }

    setUpPCIPalPayment(){
        window.addEventListener("message", (event) => {   
            this.pcIpalMessageClr = '';    
            console.log("-------------------------"+event);
            console.log("-------------------------"+JSON.stringify(event.data));
            var validCVVCodes = ["M", "1"];
            var subscriptionID,decision,reasonCode,ccType,ccLast4,ccExpMonth,ccExpYear,cvvResult,faultString;
            try{
                //alert("event.data.VariableData.ignoreAVSResult.Value = "+event.data.VariableData.ignoreAVSResult.Value);
                 try{
                     subscriptionID = event.data.VariableData.paySubscriptionCreateReply_subscriptionID.Value ;
                     decision       = event.data.VariableData.decision.Value ;
                     reasonCode     = event.data.VariableData.reasonCode.Value ;
                     ccType         = event.data.VariableData.respCardType.Value ;
                     ccLast4        = event.data.VariableData.cardLast4.Value ;
                     ccExpMonth     = event.data.VariableData.cardExpiryMonth.Value ;
                     ccExpYear      = event.data.VariableData.cardExpiryYear.Value ;
                     cvvResult      = event.data.VariableData.cvCode.Value ;
                     faultString    = event.data.VariableData.faultString.Value ;
                }
                catch(ex){}
                // Token generated successfully
                if(decision!=null && decision == "ACCEPT"){
                    if(cvvResult != null && cvvResult != "" && validCVVCodes.indexOf(cvvResult) !== -1){
                        //flexResponse.value = JSON.stringify(response);
                        console.log('Token generated: '+subscriptionID);
                        this.dataoms.ccIsTokenized = true;
                        this.dataoms.ccNumber = subscriptionID;                                               
                        this.dataoms.ccTokenizedMessage = 'Credit Card Info Tokenized Successfully !!';
                        this.dataoms.selectedCcType = ccType;
                        this.dataoms.ccLast4 = ccLast4;
                        this.dataoms.selectedCcExpMonth = ccExpMonth;
                        this.dataoms.selectedCcExpYear = ccExpYear;                        
                        this.pcIpalMessage = true;                        
                        this.pcIpalFrame = false;                       
                   }
                    else{
                        this.pcIpalFrame = false;                        
                        //$jq("input[id$='so__cci_ppIsTokenized']").val(false);   
                        this.dataoms.ccIsTokenized = false;                       
                        this.pcIpalMessageClr = 'red'; 
                        this.dataoms.ccTokenizedMessage = 'CVV validation failed - cvvResult:'+cvvResult;                        
                    }
                }
                else{                   
                    this.pcIpalFrame = false;      
                    //$jq("input[id$='so__cci_ppIsTokenized']").val(false); 
                    this.dataoms.ccIsTokenized = false;                   
                    this.pcIpalMessageClr = 'red';                   
                    this.dataoms.ccTokenizedMessage = 'Credit Card Auth failed - Decision:'+decision+' ResonCode:'+reasonCode +' '+faultString;  
                    //alert( faultString );
                }
            }
            catch(ex){
                this.pcIpalFrame = false;                
                //$jq("input[id$='so__cci_ppIsTokenized']").val(false);     
                this.dataoms.ccIsTokenized = false;             
                this.pcIpalMessageClr = 'red'; 
                this.dataoms.ccTokenizedMessage = 'Error: '+ex;
            }
            //console.log(JSON.stringify(event.data));
        }, false);
            

        if(this.dataoms.ccIsTokenized){
            this.pcIpalFrame = false;
        }
        else{
            var actionUrl = this.dataoms.pcipalHostUrl+'/session/'+this.dataoms.pcipalTenantId+'/view/'+this.dataoms.pcipalSessionId+'/framed';
            var form = document.createElement('form');
            form.setAttribute('action', actionUrl);
            form.setAttribute('method', 'post');
            form.setAttribute('target', 'loadIframe');
            var xBearerToken = document.createElement('input');
            xBearerToken.setAttribute('type', 'hidden');
            xBearerToken.setAttribute('name', 'X-BEARER-TOKEN');
            xBearerToken.setAttribute('value', this.dataoms.pcipalAuthToken);
            var xRefreshToken = document.createElement('input');
            xRefreshToken.setAttribute('type', 'hidden');
            xRefreshToken.setAttribute('name', 'X-REFRESH-TOKEN');
            xRefreshToken.setAttribute('value', this.dataoms.pcipalRefreshToken);
            form.appendChild(xBearerToken); form.appendChild(xRefreshToken);
            var formContainer = this.template.querySelector('.pcipal-form-container');
            formContainer.appendChild(form);
            form.submit();
         }
         setTimeout(() => {   
            this.showSpinner = false;                                                                                                    
        }, 1000);               
    }

   /* setUpCreditCard(){
        //Loop and add the Year values to DropDownList.       
        this.dataoms.selectedCcExpMonth = '0'+((new Date()).getMonth()+1);
        
        //setupCCValidation();
        if(this.dataoms.ccIsTokenized === true){
            //hide credit card section and show msg
            this.so__cc_paymiFrameWrapper = false;
        }
        else{           
            var expYear = this.template.querySelector('.expiry-year-input');
            var cardType = this.template.querySelector('.card-type-input');
            var tokenizebtn = this.template.querySelector('.tokenizebtn');
            var container = this.template.querySelector('.cardNumber-container');
            var cdTypefromCC='';
            var jwk = JSON.parse(this.dataoms.flexToken);
            var flexResponse= this.template.querySelector('.flexresponse');
                        
            loadScript(this, FLEX_MICROFORM).then(() => {
                 // SETUP MICROFORM  
                FLEX.microform(
                    {
                        keyId: jwk.kid,
                        keystore: jwk,
                        container: '#'+container.id,
                        label: 'Card Number',
                        placeholder: 'Enter Card Number here',
                        styles: {
                            'input': {
                                'font-family': '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol"',
                                'font-size': '1rem',
                                'line-height': '1.5',
                                'color': '#495057',
                            },
                            ':focus': {'color': 'blue'},
                            ':disabled': {'cursor': 'not-allowed'},
                            'valid': {'color': '#3c763d'},
                            'invalid': {'color': '#a94442'},
                        },
                        encryptionType: 'rsaoaep256'
                    },
                    function (setupError, microformInstance) {
                        if (setupError) {
                            // handle error
                            return;
                        }
                        microformInstance.on('cardTypeChange', function (data) {
                            if(data && data.card && data.card.length > 0){
                                for (i = 0; i < data.card.length; i++) {
                                    if(data.card[i].name =='visa' || data.card[i].name =='mastercard'||data.card[i].name =='amex'||data.card[i].name =='discover'){
                                        cdTypefromCC=data.card[i].cybsCardType;
                                        console.log(cdTypefromCC );
                                    }
                                }
                                AlertMsg.innerHTML='';
                            }
                            else{
                                cdTypefromCC='';
                            }
                        });
                        // intercept the form submission and make a tokenize request instead
                        tokenizebtn.addEventListener('click', function () {
                            /*if(!validate()){
                                return;
                            }*/
                            // Send in optional parameters from other parts of your payment form
                           /* var options = {
                                cardExpirationMonth: this.dataoms.selectedCcExpMonth,
                                cardExpirationYear: expYear.value,
                                cardType: cardType.value
                            };
                            
                            var AlertMsg = this.template.querySelector("alert-msg");
                            microformInstance.createToken(options, function (err, response) {
                                if (err) {
                                    
                                    var msg = new Array();
                                    AlertMsg.innerHTML='';
                                    switch (err.details.responseStatus.reason) {
                                        case 'VALIDATION_ERROR':
                                            // Occurs when any validation issues have been flagged and these are explained by
                                            // err.details.responseStatus.message
                                            // Issues with specific data fields are described by the details property array
                                            err.details.responseStatus.details.forEach(function(detail) {
                                                msg.push(detail.message);
                                            });
                                            console.error('Validation error');
                                            break;
                                        case 'DECRYPTION_ERROR':
                                            // The card was unable to be decrypted on the server side. This was likely due to the
                                            // Microform 'encryptionType' parameter not matching the type specified when initially
                                            // requesting the public key.
                                            msg.push('Error');
                                            console.error('Decryption error');
                                            break;
                                        case 'TOKENIZATION_ERROR':
                                            // The card was unable to be tokenized by the service which could indicate that there
                                            // is some problem with the data. For further investigation use the embedded icsReply
                                            // details to check the EBC transaction search.
                                            // err.details.responseStatus._embedded.icsReply.requestId
                                            msg.push('Tokenization Error');
                                            console.error('Tokenization error');
                                            break;
                                        case 'RESOURCE_QUOTA_EXCEEDED':
                                            // Occurs when the supplied public key has been used too
                                            // many times. Request a new public key and try again.
                                            console.error('Resource quota exceeded');
                                            break;
                                        case 'INTERNAL_ERROR':
                                            // Something went wrong on CyberSource's end
                                            msg.push('Internal Error in CyberSource');
                                            break;
                                        default:
                                            msg.push('Unknown Error');
                                    }
                                    for(var i=0; i < msg.length; i++) {
                                        var li = document.createElement("li");
                                        li.appendChild(document.createTextNode(msg[i]));
                                        AlertMsg.appendChild(li);
                                    }
                                    return;
                                }
                                AlertMsg.innerHTML='';
                                
                                // Token generated successfully
                                if(response.token!=null){
                                    flexResponse.value = JSON.stringify(response);
                                    var last4 = response.maskedPan.slice(response.maskedPan.length - 4);
                                    console.log('Token generated: '+response.maskedPan);
                                    this.dataoms.ccIsTokenized = true; 
                                    this.dataoms.ccNumber = response.token;
                                    this.dataoms.ccTokenizedMessage = 'Credit Card Info Tokenized Successfully !!';
                                    this.dataoms.ccLast4 = last4;      
                                    this.so__cc_paymiFrameMessage = true;
                                    this.so__cc_paymiFrameWrapper = false;                                 
                                }
                                else{                                    
                                    this.dataoms.ccIsTokenized = true;
                                    //alert( result.message );

                                }
                            });
                        });
                        
                    }
                );
            });                     
        }
    }*/

    handleAdressActive(){
        if(this.isAddrLoaded)
            return;
        this.isAddrLoaded = true;
        /*let pcaPredictKey = this.dataoms.pcaPredictKey;
        Promise.all([
            loadScript(this,POSTCODE_ADDR_SCRIPT),
            loadStyle(this,POSTCODE_ADDR_STYLE)
        ])
            .then(() => {
                var shipFields = [
                    { element: this.template.querySelector('.ship-st-val').name, field: "Line1" },                   
                    { element: this.template.querySelector('.ship-ct-val').name, field: "City", mode: pca.fieldMode.POPULATE },
                    { element: this.template.querySelector('.ship-sc-val').name, field: "ProvinceCode", mode: pca.fieldMode.POPULATE },
                    { element: this.template.querySelector('.ship-pc-val').name, field: "PostalCode" },
                    { element: this.template.querySelector('.ship-cc-val').name, field: "CountryIso2", mode: pca.fieldMode.COUNTRY }
                ],
                    //
                    options = {
                        key: {pcaPredictKey}
        
                    },
                    control = new pca.Address(shipFields, options);
        
                /*var contactFields = [
                    { element: "so__conAddrStreet", field: "Line1" },
                    { element: "so__conAddrStreet2", field: "Line2", mode: pca.fieldMode.POPULATE },
                    { element: "so__conAddrCity", field: "City", mode: pca.fieldMode.POPULATE },
                    { element: "so__conAddrState", field: "ProvinceCode", mode: pca.fieldMode.POPULATE },
                    { element: "so__conAddrZipCode", field: "PostalCode" },
                    { element: "so__conAddrCountry", field: "CountryIso2", mode: pca.fieldMode.COUNTRY }
                ],
                    //key: "{pcaPredictKey}"
                    contactOptions = {
                        key: "{!pcaPredictKey}"
        
                    },
                    control = new pca.Address(contactFields, contactOptions);
        
                var billingFields = [
                    { element: "so__ccAddrStreet", field: "Line1" },
                    { element: "so__ccAddrCity", field: "City", mode: pca.fieldMode.POPULATE },
                    { element: "so__ccAddrState", field: "ProvinceCode", mode: pca.fieldMode.POPULATE },
                    { element: "so__ccAddrZipCode", field: "PostalCode" },
                    { element: "so__ccAddrCountry", field: "CountryIso2", mode: pca.fieldMode.COUNTRY }
                ],
                    //key: "{pcaPredictKey}"
                    billingOptions = {
                        key: "{!pcaPredictKey}"
        
                    },
                control = new pca.Address(billingFields, billingOptions);
                this.isAddrLoaded = true;                
            })
            .catch(error => {
                this.showErrorMsg('Error loading postcode address',error.message);                
            }); */              
    }

    showErrorMsg(header,msg){
        this.dispatchEvent(
            new ShowToastEvent({
                title: header,
                message: msg,
                variant: 'error',
                mode:'sticky'
            })
        );
    }

    showSuccessMsg(header,msg){
        this.dispatchEvent(
            new ShowToastEvent({
                title: header,
                message: msg,
                variant: 'success'
            })
        );
    }

    loadOrderForm() {
        this.showHeaderSpinner = true;
        loadOrderFormlwc(
            {
                recordId: this.caseId,
                datainstance: JSON.stringify(this.dataoms)                
            }).then(data => {
                console.log(data);                
                this.dataoms = JSON.parse(JSON.stringify(data));                
                this.showHeaderSpinner = false;
                this.shippingMethods = [{ label: this.c_BLANK, value: this.c_BLANK }];              
               /* this.dataoms.shipMethodLabelList.forEach(item => {                    
                    this.shippingMethods.push({ label: item, value: item });                   
                }); */
                for (const [key, value] of Object.entries(this.dataoms.shippingMethodsMap)) {
                    this.shippingMethods.push({ label: value, value: key });
                }
                this.orderReasons = [];
                for (const [key, value] of Object.entries(this.dataoms.orderReasonsMap)) {
                    this.orderReasons.push({ label: value, value: key });
                }
                this.reloadExpressions();
                if(this.dataoms.brandSelected && this.dataoms.pageRender){
                    this.isBrandSelected = true;
                    this.activateSections(['A','B', 'E', 'F', 'G']);
                }             
            }).catch(error => {
                this.showHeaderSpinner = false;
                this.showErrorMsg('Error',error.body.message);  
                console.log('error in loadOrderForm');
             })
    }

    setOrderType(event){
        this.dataoms.selectedOrderType = event.target.value;
    }

    updateBrand(event) {
        this.showSpinner = true;
        this.dataoms.brand = event.target.value;
        updateBrandLwc(
            {
                recordId: this.caseId,
                datainstance: JSON.stringify(this.dataoms)                
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.subBrands = [{ label: this.c_BLANK, value: this.c_BLANK }];
                this.dataoms.subBrandsList.forEach(item => {                    
                    this.subBrands.push({ label: item.trim(), value: item.trim()});                   
                }) 
                this.orderTypes = [{ label: this.c_BLANK, value: this.c_BLANK }];
                this.dataoms.orderTypeList.forEach(item => {                    
                    this.orderTypes.push({ label: item.trim(), value: item.trim()});                   
                })    
                this.showSpinner = false;                    
            }).catch(error => {
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })
    }
    updateSubBrand(event) {
        this.showSpinner = true;
        this.dataoms.subBrand = event.target.value;
        updateSubBrandLwc(
            {
                recordId: this.caseId,
                datainstance: JSON.stringify(this.dataoms)
            }).then(data => {
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.orderTypes = [{ label: this.c_BLANK, value: this.c_BLANK }];
                this.dataoms.orderTypeList.forEach(item => {                    
                    this.orderTypes.push({ label: item.trim(), value: item.trim()});                   
                })    
                this.showSpinner = false;
            }).catch(error => {
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })
    }
    searchProducts() {
        this.showSearchSpinner = true;       
        this.dataoms.searchProductNumber  =  this.template.querySelector('.prod-serach-input-key').value; 
        this.isSerachError = false;
        searchProductsLwc(
            {
                recordId: this.caseId,
                datainstance: JSON.stringify(this.dataoms)
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.showSearchSpinner = false;
                if(this.dataoms.searchErrMsg){
                    this.isSerachError = true;
                }                
            }).catch(error => {
                this.showSearchSpinner = false;
                this.showErrorMsg('Error',error.body.message);  
            })

    }
    addProductsToOrder(event) {
        this.showSpinner = true;
        this.dataoms.selectedProductIdForOrders = event.currentTarget.dataset.id;
        this.dataoms.selectedProductCategory = event.currentTarget.dataset.cat;
        addProductsToOrderLwc(
            {
                recordId: this.caseId,
                datainstance: JSON.stringify(this.dataoms)                
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.showSpinner = false;
                this.reloadExpressions();
            }).catch(error => {
                console.log(error);
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
            })
    }
    removeProductsFromOrder(event) {
        event.preventDefault();
        this.showSpinner = true;
        this.dataoms.selectedMatToRemove = event.currentTarget.dataset.id;
        removeProductsFromOrderLwc(
            {                
                recordId: this.caseId,
                datainstance: JSON.stringify(this.dataoms)
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.reloadExpressions();
                this.showSpinner = false;
            }).catch(error => {
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })        
    }
    simulateSalesOrder() {
        this.showSpinner = true;
        if(this.isAddrLoaded){
            this.setAdressFields();
        }
        if(this.dataoms.isOrder){
            this.dataoms.caseNumber = this.template.querySelector('.case-num-val').value;  
        }    
        simulateSalesOrderLwc(
            {
                recordId: this.caseId,
                datainstance: JSON.stringify(this.dataoms)
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.reloadExpressions();
                //this.activeSections.push('C');
                this.activateSections(['A', 'B', 'C', 'D', 'E', 'F', 'G']);
                this.showSpinner = false;
                if(this.dataoms.isError === false){
                    if(this.dataoms.sendPaymentEmail === false && ( this.dataoms.selectedOrderType == 'Warranty/Charge' || this.dataoms.selectedOrderType == 'Charge/Repair')){
                        this.loadPaymentFrame();
                    }  
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Order simulate completed',
                            variant: 'success',
                        }),
                    );
                }
                else{
                    this.highlightErrorPanel();
                }                   
            }).catch(error => {
                this.showSpinner = false;               
                if(error.body.message !== undefined){
                    this.errors = error.body.message.split('\n'); 
                    if(this.errors.length > 1)
                        this.errors.pop();                                                                     
                }                            
                this.showErrorMsg('Error',error.body.message);                        
                console.log(errors);                
            })

    }

    createOMSOrder() {
        this.showSpinner = true;
        if(this.template.querySelector('.shipping-notes-val') !== undefined){
            this.dataoms.shippingNotes = this.template.querySelector('.shipping-notes-val').value;
        }
        CreateOmsOrdLwc(
            {
                recordId: this.caseId,
                datainstance: JSON.stringify(this.dataoms)
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.showSpinner = false;
                if(this.dataoms.isSuccess){                                       
                    //this.showOrderSuccessMsg();                   
                    setTimeout(() => {   
                        this.template.querySelector('.error-panel').scrollIntoView();                                                                                               
                    }, 300);                                
                }else{
                    this.highlightErrorPanel();
                }                           
            }).catch(error => {
                this.showSpinner = false;               
                this.showErrorMsg('Error',error.body.message);     
                console.log(error);
            })
    }

    highlightErrorPanel(){
        if(this.dataoms.isError){
            setTimeout(() => {   
                this.template.querySelector('.error-panel').scrollIntoView();                                                                                               
            }, 300);               
        }     
    }

    openSuccRecord(event){
        event.preventDefault();       
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.dataoms.orderId,
                actionName: 'view',
            },
        }).then(url => {
             window.open(url);
        });
    }      

    getGCBalance()
      {
        this.showSpinner = true;
        this.dataoms.gcNumber = this.template.querySelector('.gift-number-input').value;
        this.dataoms.gcPin = this.template.querySelector('.gift-pin-input').value;
        getGCBalanceLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.reloadExpressions();
              this.showSpinner = false;              
            }).catch(error=>{
              console.log(error);
              this.showSpinner = false;
              this.showErrorMsg('Error',error.body.message); 
            })
      }
      addGiftCardToOrder()
      {
        this.showSpinner = true;
        addGiftCardToOrderLWC(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)             
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.reloadExpressions();              
              this.showSpinner = false;
            }).catch(error=>{
              console.log(error);
              this.showSpinner = false;
              this.showErrorMsg('Error',error.body.message);              
            })
      }
      removeGiftCardFromOrder(event)
      {
        event.preventDefault();
        this.showSpinner = true;
        this.dataoms.selectedGCToRemove = event.currentTarget.dataset.id;
        //Setting -SimulateOrderFlag
        this.dataoms.ordSimulateRequired = true;
        removeGiftCardFromOrderLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.reloadExpressions();
              this.showSpinner = false;
            }).catch(error=>{
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })
      } 
      explodeBom(event)
      {
        this.showSpinner = true;
        this.dataoms.selectedProductForBOM = event.currentTarget.dataset.id;
        this.dataoms.selectedCaseProductForBOM = event.currentTarget.dataset.cpid;
        explodeBomLWC(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)              
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.reloadExpressions();
              this.showSpinner = false;                       
            }).catch(error=>{
              this.showSpinner = false;
              this.showErrorMsg('Error',error.body.message); 
              console.log(error);
            })
      } 
      addCouponCode()
      {
        this.showSpinner = true;
        this.dataoms.couponCode = this.template.querySelector('.coupon-serach-input-key').value;
        addCouponCodeLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.reloadExpressions();
              this.showSpinner = false;
            }).catch(error=>{
              console.log(error);
              this.showSpinner = false;
              this.showErrorMsg('Error',error.body.message);               
            })
      } 
      removeCoupon(event)
      {
        this.showSpinner = true;
        this.dataoms.selectedCouponToRemove = event.currentTarget.dataset.id;
        //Setting -SimulateOrderFlag
        this.dataoms.ordSimulateRequired = true;
        removeCouponLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.reloadExpressions();
              this.showSpinner = false;
            }).catch(error=>{
              console.log(error);
              this.showSpinner = false;
              this.showErrorMsg('Error',error.body.message); 
            })
      } 
      remAllProductsFromCart()
      {
        this.showSpinner = true;
        remAllProductsFromCartLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)              
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.reloadExpressions();
              this.showSpinner = false;
            }).catch(error=>{
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })
      } 
      clearBomComponents()
      {
        this.showSpinner = true;
        clearBomComponentsLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.reloadExpressions();
              this.showSpinner = false;
            }).catch(error=>{
              this.showSpinner = false;
              this.showErrorMsg('Error',error.body.message); 
              console.log(error);
            })
      }
      addAllProductsToCart(event)
      {
        this.showSpinner = true;
        this.dataoms.selectedProductCategory = event.currentTarget.dataset.cat;
        addAllProductsToCartLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.reloadExpressions();
              this.showSpinner = false;
            }).catch(error=>{
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })
      }  
      UpdateOPDiscount(event)
      {
        this.showSpinner = true;
        let id = event.currentTarget.dataset.id;       
        this.dataoms.orderProductsList.forEach(item => {
            if(item.materialId === id){
                item.itemLevelDiscountCode = event.target.value;
            }
        })    
        UpdateOPDiscountLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.showSpinner = false;
            }).catch(error=>{
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })
      }
     
      reTokenizeCC()
      {
        this.showSpinner = true;
        reTokenizeCCLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)               
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.pcIpalFrame = true;
              setTimeout(() => {   
                this.setUpPCIPalPayment();                                                                                                    
              }, 300); 
              this.showSpinner = false;
            }).catch(error=>{
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })
      } 
      getOrderNumber()
      {
        getOrderNumberLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms) 
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.showSpinner = false;
            }).catch(error=>{
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message);                 
                console.log(error);
            })
      } 
      updateProductsInCart()
      {
        updateProductsInCartLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
            }).catch(error=>{
                this.showErrorMsg('Error',error.body.message); 
              console.log(error);
            })
      } 
      updateOrderType()
      {
        updateOrderTypeLwc(
            {
              recordId:this.caseId,
              datainstance:JSON.stringify(this.dataoms)
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
            }).catch(error=>{
                this.showErrorMsg('Error',error.body.message); 
              console.log(error);
            })
      } 

    bindSearchQuantity(event){
        let id = event.currentTarget.dataset.id; 
        let val = event.target.value;
        if(val !== undefined && val.length > 0){   
            this.dataoms.searchProductsList.forEach(item => {
                if(item.materialId === id){
                    item.quantity = parseInt(val);
                }
            })
            let searchProductsMap = new Map(Object.entries(this.dataoms.searchProductsMap)); 
            if(searchProductsMap.get(id) !== undefined){
                searchProductsMap.get(id).quantity = parseInt(val);
            }           
        }           
    }

    bindCaseQuantity(event){
        let id = event.currentTarget.dataset.id;  
        let val = event.target.value;
        if(val !== undefined && val.length > 0){         
            this.dataoms.caseProductsList.forEach(item => {
                if(item.materialId === id){
                    item.quantity = parseInt(val);
                }
            })
            let caseProductsMap = new Map(Object.entries(this.dataoms.caseProductsMap)); 
            if(caseProductsMap.get(id) !== undefined){
                caseProductsMap.get(id).quantity = parseInt(val);
            } 
        }              
    }

    bindBOMQuantity(event){
        let id = event.currentTarget.dataset.id;       
        let val = event.target.value;
        if(val !== undefined && val.length > 0){       
            this.dataoms.bomComponentsList.forEach(item => {
                if(item.componentId === id){
                    item.quantity = parseInt(val);
                }
            })
            let bomComponentsMap = new Map(Object.entries(this.dataoms.bomComponentsMap)); 
            if(bomComponentsMap.get(id) !== undefined){
                bomComponentsMap.get(id).quantity = parseInt(val);
            } 
        }  
    }    

    bindUnitPrice(event){
        let id = event.currentTarget.dataset.id;       
        this.dataoms.orderProductsList.forEach(item => {
            if(item.materialId === id){
                item.msrp = event.target.value;
            }           
        }) 
        this.dataoms.ordSimulateRequired = true;
    }

    activateSections(secNames){
        let _this = this;
        setTimeout(() => {
            _this.activeSections = secNames;
        }, 200);
    }
    
    cbShpAddr() {      
        this.dataoms.shpAddr = true;
        this.dataoms.conAddr = false;
        this.template.querySelector('.cb-ship-addr').checked = true;
        this.template.querySelector('.cb-con-ship-addr').checked = false;
    }

    cbConAddr() {      
        this.dataoms.shpAddr = false;
        this.dataoms.conAddr = true;
        this.template.querySelector('.cb-ship-addr').checked = false;
        this.template.querySelector('.cb-con-ship-addr').checked = true;
    }

    updateConAddr(event) {
        this.dataoms.conAddrUpd = event.target.checked;
    }

    ccAddressFill(event) {
        let val = event.target.checked;
        let name = event.target.name;

        if (name === 'useShipAddr') {
            if (val === true) {
                this.template.querySelector('.use-con-addr').checked = false;
                this.template.querySelector('.new-bill-addr').checked = false;
                this.setDisabledAttr(true);
                this.setValueToSelAddr('ship');
            } else if (this.template.querySelector('.use-con-addr').checked === false && this.template.querySelector('.new-bill-addr').checked === false) {
                this.setValueToBlank();
            }
        } else if (name === 'useConAddr') {
            if (val === true) {
                this.template.querySelector('.use-ship-addr').checked = false;
                this.template.querySelector('.new-bill-addr').checked = false;
                this.setDisabledAttr(true);
                this.setValueToSelAddr('con');
            } else if (this.template.querySelector('.use-ship-addr').checked === false && this.template.querySelector('.new-bill-addr').checked === false) {
                this.setValueToBlank();
            }
        } else if (name === 'newBillAddr') {
            if (val === true) {
                this.template.querySelector('.use-ship-addr').checked = false;
                this.template.querySelector('.use-con-addr').checked = false;
                this.setDisabledAttr(false);
            } else if (this.template.querySelector('.use-ship-addr').checked === false && this.template.querySelector('.use-con-addr').checked === false) {
                this.setValueToBlank();
            }
        }
    }

    setDisabledAttr(arg) {
        let billAddrFields = [...this.template.querySelectorAll('.billing-addr-field')];
        billAddrFields.forEach(item => {
            item.disabled = arg;
        });
    }

    setValueToBlank() {
        let billAddrFields = [...this.template.querySelectorAll('.billing-addr-field')];
        billAddrFields.forEach(item => {
            item.value = '';
        });
    }

    openRecord(event){
        event.preventDefault();
        let id = event.currentTarget.dataset.id;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                actionName: 'view',
            },
        }).then(url => {
             window.open(url);
        });
    }  
    
    setAdressFields(){
        //Shipping Address
        this.dataoms.shpAddrName = this.template.querySelector('.ship-fn-val').value;
        this.dataoms.shpAddrName2 = this.template.querySelector('.ship-ln-val').value;
        this.dataoms.shpAddrStreet = this.template.querySelector('.ship-st-val').value;
        this.dataoms.shpAddrCity = this.template.querySelector('.ship-ct-val').value;
        this.dataoms.shpAddrState = this.template.querySelector('.ship-sc-val').value;
        this.dataoms.shpAddrZipCode = this.template.querySelector('.ship-pc-val').value;
        this.dataoms.shpAddrCountry = this.template.querySelector('.ship-cc-val').value;
        this.dataoms.shpAddrEmail = this.template.querySelector('.ship-mail-val').value;
        this.dataoms.shpAddrPhone = this.template.querySelector('.ship-ph-val').value;
        this.dataoms.shpAddrCompanyName = this.template.querySelector('.ship-cn-val').value;
        //Contact Shiping Adreess fields
        this.dataoms.conAddrName = this.template.querySelector('.con-fn-val').value;
        this.dataoms.conAddrName2 = this.template.querySelector('.con-ln-val').value;
        this.dataoms.conAddrStreet = this.template.querySelector('.con-st-val').value;
        this.dataoms.conAddrCity = this.template.querySelector('.con-ct-val').value;
        this.dataoms.conAddrState = this.template.querySelector('.con-sc-val').value;
        this.dataoms.conAddrZipCode = this.template.querySelector('.con-pc-val').value;
        this.dataoms.conAddrCountry = this.template.querySelector('.con-cc-val').value;
        this.dataoms.conAddrEmail = this.template.querySelector('.con-mail-val').value;
        this.dataoms.conAddrPhone = this.template.querySelector('.con-ph-val').value;
        this.dataoms.conAddrCompanyName = this.template.querySelector('.con-cn-val').value;
        //Billing Address fields
        this.dataoms.ccAddrName = this.template.querySelector('.bill-fn-val').value;
        this.dataoms.ccAddrName2 = this.template.querySelector('.bill-ln-val').value;
        this.dataoms.ccAddrStreet = this.template.querySelector('.bill-st-val').value;
        this.dataoms.ccAddrCity = this.template.querySelector('.bill-ct-val').value;
        this.dataoms.ccAddrState = this.template.querySelector('.bill-sc-val').value;
        this.dataoms.ccAddrZipCode = this.template.querySelector('.bill-pc-val').value;
        this.dataoms.ccAddrCountry = this.template.querySelector('.bill-cc-val').value;
        this.dataoms.ccAddrEmail = this.template.querySelector('.bill-mail-val').value;
        this.dataoms.ccAddrPhone = this.template.querySelector('.bill-ph-val').value;
        this.dataoms.ccAddrCompanyName = this.template.querySelector('.bill-cn-val').value;
    }

    setValueToSelAddr(val) {
        this.template.querySelector('.bill-fn-val').value = this.template.querySelector('.' + val + '-fn-val').value;
        this.template.querySelector('.bill-ln-val').value = this.template.querySelector('.' + val + '-ln-val').value;
        this.template.querySelector('.bill-st-val').value = this.template.querySelector('.' + val + '-st-val').value;
        this.template.querySelector('.bill-ct-val').value = this.template.querySelector('.' + val + '-ct-val').value;
        this.template.querySelector('.bill-sc-val').value = this.template.querySelector('.' + val + '-sc-val').value;
        this.template.querySelector('.bill-pc-val').value = this.template.querySelector('.' + val + '-pc-val').value;
        this.template.querySelector('.bill-cc-val').value = this.template.querySelector('.' + val + '-cc-val').value;
        this.template.querySelector('.bill-mail-val').value = this.template.querySelector('.' + val + '-mail-val').value;
        this.template.querySelector('.bill-ph-val').value = this.template.querySelector('.' + val + '-ph-val').value;
        this.template.querySelector('.bill-cn-val').value = this.template.querySelector('.' + val + '-cn-val').value;
    }    
   

    closePopup(event) {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleSectionToggle(event) {
        this.activeSections = event.detail.openSections;
    }

}