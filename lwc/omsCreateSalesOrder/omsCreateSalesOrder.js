import { LightningElement, api, track,wire } from 'lwc';
import getVFOrigin from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.getVFOrigin';
import getinitdata from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.getinitdata';
import getoptions from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.getoptions';
import reCalcFreightlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.reCalcFreightlwc';
import updateCurrencyForAccountLWC from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.updateCurrencyForAccountLWC';
import applyDiscountlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.applyDiscountlwc';
import clearBomComponentslwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.clearBomComponentslwc';
import addAllProductsToCartlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.addAllProductsToCartlwc';
import UpdateOPDiscountlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.UpdateOPDiscountlwc';
import remAllProductsFromCartlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.remAllProductsFromCartlwc';
import reCalcPricinglwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.reCalcPricinglwc';
import addProductsToOrderlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.addProductsToOrderlwc';
import simulateSalesOrderlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.simulateSalesOrderlwc';
import createSapSalesOrderlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.createSapSalesOrderlwc';
import cbConAddrlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.cbConAddrlwc';
import removeProductsFromOrderlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.removeProductsFromOrderlwc';
import updateProductsInCartlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.updateProductsInCartlwc';
import explodeBomlwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.explodeBomlwc';
import reTokenizeCClwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.reTokenizeCClwc';
import updateAddFreightLWC from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.updateAddFreightLWC';
import updateTotalPricelwc from '@salesforce/apex/SalesOrderRequestControllerLWC_NWL.updateTotalPricelwc';
// Import custom labels
import validateMsg from '@salesforce/label/c.PAYM_RequiredValidator';
import GRAPHICS_PACK from '@salesforce/resourceUrl/GraphicsPack';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript,loadStyle } from 'lightning/platformResourceLoader';

export default class OmsCreateSalesOrder extends NavigationMixin(LightningElement) {
    label = { validateMsg };
    @track showSpinner = false;
    @api caseId;
    omsReturnData;
    OrderTypeOpt = [];
    shippingMethodOpt = [];
    cardTypeOpt = [];
    @track errors=[];
    @track dataoms;
    //Address checkbox fields
    flagGreen = GRAPHICS_PACK + '/32/fatcow/farmfresh/flag_green.png';
    flagYellow = GRAPHICS_PACK + '/32/fatcow/farmfresh/flag_yellow.png';
    flagRed = GRAPHICS_PACK + '/32/fatcow/farmfresh/flag_red.png';
    cross = GRAPHICS_PACK + '/16/famfamfam/silk/cross.png';

    activeSections = ['A','C','E','F','G'];

    //Spinners
    @track showHeaderSpinner = false;
    @track showSearchSpinner = false;
    @track siteUrl = '/apex/CreditCardSales_NWL';
    @track orderTypes=[];
    @track orderReasons;
    @track customerNos;
    @track itemLevelDiscounts=[];
    @track shippingMethods;
    @track ccTypes;
    @track incoterms;
    @track ccExpMonths;
    @track ccExpYears;
    @track isAddrLoaded=false;
    @track ordShpCond=[];
    @track ordBillBlock;
    @track ordCurr;
    @track backupmap = [];
    @track loadordermap = [];
    @track productsearchmap = [];
    @track removeproductmap = [];
    @track sendPaymentEmail;
    @track ccIsTokenized;
    @track allowPCIPalPayment;
    ordercreated = false;
    brand;
    selectedProductCategory;
    selectedProductIdForOrders;
    @track orderProductsList;
    subBrand;
    sapBrand;
    csList;
    oi;
    selectedMatToRemoves;
    enableOCAPICallout;
    sfPricing;
    simMerchNetTotal = 0.00;
    simShipNetTotal = 0.00;
    simAdjMerchNetTotal = 0.00;
    simAdjShipNetTotal = 0.00;
    simOrderNetTotal = 0.00;
    simOrderTax = 0.00;
    simMerchGrossTotal = 0.00;
    simShipGrossTotal = 0.00;
    simAdjMerchGrossTotal = 0.00;
    simAdjShipGrossTotal = 0.00;
    simOrderGrossTotal = 0.00;
    simShipTax = 0.00;
    simOrderTotalTax = 0.00;
    simOrderDiscounts = 0.00;
    simOrderCredits = 0.00;
    simOrderCouponSavings = 0.00;
    simOrderGCPayments = 0.00;
    simOrderTotal = 0.00;
    c_BLANK = '---';
    @track bs;
    @track sbsList;
    @track orderTypeList;
    selectedMatToRemoves;
    @track sfccOCAPI;
    ccframeLoaded =false;

    
    //Expression flags
    @track isBrandSelected = false;
    @track isSimOrderGrossTotal = false;
    @track isBomCompListEmpty = false;
    @track isOrderProdListEmpty = false; 
    @track showCredCard = true;  
    @track so__cc_paymiFrameWrapper = true;
    @track so__cc_paymiFrameMessage = false;
        // Wire getVFOrigin Apex method to a Property
        @wire(getVFOrigin)
        vfOrigin;
    @track actveTab = "one";

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
                        recordId: this.caseId
                    }).then(data => {                       
                        console.log('data' + JSON.stringify(data));
                        this.brands = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.subBrands = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.orderTypes = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.orderReasons = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ccExpYears = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ccExpMonths = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ccTypes = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.itemLevelDiscounts = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.customerNos = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.incoterms = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ordBillBlock=[{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ordCurr = [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ordShpCond= [{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ordDelvBlock=[{ label: this.c_BLANK, value: this.c_BLANK }];
                        this.ordDisc=[{ label: this.c_BLANK, value: this.c_BLANK }];
                        for (const [key, value] of Object.entries(data.ordDisc)) {
                            this.ordDisc.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.orderTypes)) {
                            this.orderTypes.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.ordDelvBlock)) {
                            this.ordDelvBlock.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.orderReasons)) {
                            this.orderReasons.push({ label: value, value: key });
                        }
                        console.log('1'+JSON.stringify(this.orderReasons));
                        for (const [key, value] of Object.entries(data.customerNos)) {
                            this.customerNos.push({ label: value, value: key });
                        }
                        console.log('1'+JSON.stringify(this.customerNos));
                        for (const [key, value] of Object.entries(data.ccTypes)) {
                            this.ccTypes.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.incoterms)) {
                            this.incoterms.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.ccExpMonths)) {
                            this.ccExpMonths.push({ label: value, value: key });
                        }
                        console.log('1'+JSON.stringify(this.ccExpMonths));
                        for (const [key, value] of Object.entries(data.ccExpYears)) {
                            this.ccExpYears.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.ordShpCond)) {
                            this.ordShpCond.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.ordBillBlock)) {
                            this.ordBillBlock.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.ordCurr)) {
                            this.ordCurr.push({ label: value, value: key });
                        }
                        for (const [key, value] of Object.entries(data.itemLevelDiscounts)) {
                            this.itemLevelDiscounts.push({ label: value, value: key });
                        }
                        
                        this.showSpinner = false;
                        console.log('orderTypes' + JSON.stringify(this.orderTypes));
                       /* if(this.dataoms.showExpOrdChg === false)
                        { 
                            this.template.querySelector('.Expedite').disabled = true;  
                        }
                        if(this.dataoms.bomComponents === false)
                        {
                            this.template.querySelector('.ExplodeBOM').disabled = true;
                        }*/
                                       
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
        console.log('handleResponseii');
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
            console.log('credInfo='+JSON.stringify(credInfo));
            console.log(this.dataoms.selectedCcExpYear);
        }
    }
    handleCreditClick()
    {
        if(!this.ccframeLoaded){
            if(!this.dataoms.ccIsTokenized){
                let _this = this;
                this.showSpinner = true;
                this.siteUrl = '/apex/CreditCardSales_NWL?region='+this.dataoms.caseRegion+'&tokenized='+this.dataoms.ccIsTokenized; 
                this.ccframeLoaded = true;

                    setTimeout(() => {                                                                        
                        _this.showSpinner = false;
                    }, 7000);
            }
        }
         
    }
    reTokenizeCC()
    {
          //this.showSpinner = true;
           this.dataoms.ccIsTokenized = false;
           this.ccframeLoaded = false;
           this.handleCreditClick();
           /*reTokenizeCClwc(
            {
              datainstance:JSON.stringify(this.dataoms)               
            }).then(data=>{
              console.log(data);
              this.dataoms = JSON.parse(JSON.stringify(data));
              this.showSpinner = false;
            }).catch(error=>{
                this.showSpinner = false;
                console.log(error);
            })*/
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
        UpdateOPDiscountlwc({datainstance: JSON.stringify(this.dataoms)}).then(data=>
            {
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.showSpinner = false;
            }).catch(error=>
            {
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })
    }
    updateAddFreight(event)
    {
        let val = event.target.value;
        this.dataoms.ordAddFreight=val;
        updateAddFreightLWC({datainstance: JSON.stringify(this.dataoms)}).then(data=>
            {
                this.dataoms = JSON.parse(JSON.stringify(data));
            }).catch(error=>
            {
                console.log(error);
            })   
    }
    clearBomComponents()
      {
        this.showSpinner = true;
        clearBomComponentslwc(
            {
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
    remAllProductsFromCart()
    {
      this.showSpinner = true;
      remAllProductsFromCartlwc(
          {
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
    updateProductsInCart()
    {
        updateProductsInCartlwc(
          {
            datainstance:JSON.stringify(this.dataoms)
          }).then(data=>{
            console.log(data);
            this.dataoms = JSON.parse(JSON.stringify(data));
          }).catch(error=>{
              this.showErrorMsg('Error',error.body.message); 
            console.log(error);
          })
    }  
    removeProductsFromOrder(event) {
        event.preventDefault();
        this.showSpinner = true;
        this.dataoms.selectedMatToRemove = event.currentTarget.dataset.id;
        removeProductsFromOrderlwc(
            {                
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

    bindProdQuantity(event){
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

    bindorderprice(event){
        let id = event.currentTarget.dataset.id;       
        let val = event.target.value;
        if(val !== undefined && val.length > 0){       
            this.dataoms.orderProductsList.forEach(item => {
                if(item.materialId === id){
                    item.priceOverride = parseInt(val);
                }
            })
        }  
    } 
    updateTotalPrice(event){
        let id = event.currentTarget.dataset.id;       
        let val = event.target.checked;
        if(val !== undefined ){       
            this.dataoms.orderProductsList.forEach(item => {
                if(item.materialId === id){
                    item.free = val;
                    this.dataoms.free=item.free;
                    this.dataoms.freeQty=item.quantity;
                    this.dataoms.freeItemPrice=item.msrp;
                }
            })
        }  
        this.showSpinner = true;
        updateTotalPricelwc(
            {                
                datainstance: JSON.stringify(this.dataoms)
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.showSpinner = false;
            }).catch(error => {
                this.showSpinner = false;
                this.showErrorMsg('Error',error.body.message); 
                console.log(error);
            })        
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
    addAllProductsToCart(event)
    {
      this.showSpinner = true;
      this.dataoms.selectedProductCategory = event.currentTarget.dataset.cat;
      addAllProductsToCartlwc(
          {
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
    applyDiscount(event)
    {
        let val = event.target.value;
        this.dataoms.selectedOrdDisc=val;
        applyDiscountlwc({datainstance: JSON.stringify(this.dataoms)}).then(data=>
            {
                this.dataoms = JSON.parse(JSON.stringify(data));
            }).catch(error=>
            {
                console.log(error);
            })
    }
    reCalcPricing(event)
    {
        let val = event.target.value;
        this.dataoms.selectedOrdCurr=val;
        reCalcPricinglwc({datainstance: JSON.stringify(this.dataoms)}).then(data=>
            {
                this.dataoms = JSON.parse(JSON.stringify(data));
            }).catch(error=>
            {
                console.log(error);
            })
    }
    addProductsToOrder(event) {
        this.showSpinner = true;
        //this.setAdressFields();
        this.dataoms.selectedProductIdForOrders = event.currentTarget.dataset.id;
        this.dataoms.selectedProductCategory = event.currentTarget.dataset.cat;
        addProductsToOrderlwc(
            {
                datainstance: JSON.stringify(this.dataoms)                
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.showSpinner = false;
                this.reloadExpressions();
            }).catch(error => {
                console.log(error);
                this.showSpinner = false;
            })
    }
    simulateSalesOrder() {
        this.showSpinner = true;
        if(this.isAddrLoaded){
            this.setAdressFields();
        } 
        console.log('simulatedata'+JSON.stringify(this.dataoms));
        if(this.template.querySelector('.shipping-instruct-val') !== undefined){
            this.dataoms.customerShippingInstructions = this.template.querySelector('.shipping-instruct-val').value;
        }
        simulateSalesOrderlwc(
            {
                datainstance: JSON.stringify(this.dataoms)
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.reloadExpressions();
                //this.activeSections.push('C');
                this.activateSections(['A', 'C', 'E', 'F', 'G']);
                this.showSpinner = false;
                if(this.dataoms.isErrorlwc === false){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Order simulate completed',
                        variant: 'success',
                    }),
                );
                }
            }).catch(error => {
                this.showSpinner = false;                                           
                this.showErrorMsg('Error',error.body.message);                        
                console.log(JSON.stringify(this.errors));                
            })


    }
    highlightErrorPanel(){
        if(this.dataoms.isError){
            setTimeout(() => {   
                this.template.querySelector('.error-panel').scrollIntoView();                                                                                               
            }, 300);               
        }     
    }
    createSapSalesOrder() {
        this.showSpinner = true;
        createSapSalesOrderlwc(
            {
                datainstance: JSON.stringify(this.dataoms)
            }).then(data => {
                console.log(data);
                this.dataoms = JSON.parse(JSON.stringify(data));
                this.showSpinner = false;
                if(!this.dataoms.isErrorlwc){                                                   
                      this.ordercreated = true;
                    //this.showOrderSuccessMsg();
                }
            }).catch(error => {
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: error.body.message,
                        mode:'sticky'
                    })
                );      
                console.log(error);
            })
    }
    reloadExpressions(){
        if(this.dataoms.simOrderGrossTotal > 0.00){
            this.isSimOrderGrossTotal = true;
        } 
        this.showCredCard = this.dataoms.sendPaymentEmail === false && this.dataoms.showCcTab && ccOrderPhone ? true : false;        
        this.isBomCompListEmpty = this.dataoms.bomComponentsList !== undefined && this.dataoms.bomComponentsList !== null && this.dataoms.bomComponentsList.length > 0 ? false : true;                    
        this.isOrderProdListEmpty = this.dataoms.orderProductsList !== undefined && this.dataoms.orderProductsList !== null && this.dataoms.orderProductsList.length > 0 ? false : true;  
        /*if(this.dataoms.sendPaymentEmail){
            this.template.querySelector('.send-pay-email-chk').checked = true; 
        }else{
            this.template.querySelector('.send-pay-email-chk').checked = false; 
        }*/  
        this.highlightErrorPanel();   
    }
    reCalcFreight(event){
        if(event){
            this.dataoms.selectedOrdShpCond = event.target.value;
        }       
        console.log(JSON.stringify(this.dataoms.selectedOrdShpCond));
        reCalcFreightlwc({datainstance: JSON.stringify(this.dataoms)}).then(data=>
        {
            this.dataoms = JSON.parse(JSON.stringify(data));
        }).catch(error=>
        {
            console.log(error);
        })
    }
    setorderreason(event)
    {
        this.dataoms.selectedOrderReason = event.target.value;
    }
    setincoterms(event)
    {
        this.dataoms.selectedIncoterms = event.target.value;
    }
    setorderdelivery(event)
    {
        this.dataoms.selectedOrdDelvBlock = event.target.value;
    }
    setbillblock(event)
    {
        this.dataoms.selectedOrdbillBlock = event.target.value;
    }
    updateCurrencyForAccount(event){
        let val = event.target.value;
        this.dataoms.selectedCustomerNo=val; 
        let jsonObj =   JSON.stringify(this.dataoms);
        this.dataoms = [];
        updateCurrencyForAccountLWC({datainstance: jsonObj}).then(data=>
        {
            this.dataoms = JSON.parse(JSON.stringify(data));
        }).catch(error=>
        {
            console.log(error);
        }) 
    }
    closePopup(event) {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
    handleSectionToggle(event) {
        this.activeSections = event.detail.openSections;
    }
    setOrderType(event){
        this.dataoms.selectedOrderType = event.target.value;
        console.log(JSON.stringify(this.dataoms.selectedOrderType));
        if(this.dataoms.selectedOrderType === 'ZWSO' || this.dataoms.selectedOrderType === 'FD')
        {
            this.dataoms.focOrder = true;
            console.log(JSON.stringify(this.dataoms.focOrder));
        }
        this.reCalcFreight();
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
    cbShpAddr() {
        this.dataoms.shpAddr = true;
        this.dataoms.conAddr = false;
        console.log( this.dataoms.shpAddr);
        this.template.querySelector('.cb-ship-addr').checked = true;
        this.template.querySelector('.cb-con-ship-addr').checked = false;
    }
    cbConAddr() {
        this.dataoms.shpAddr = false;
        this.dataoms.conAddr = true;
        console.log( this.dataoms.shpAddr);
        console.log( this.dataoms.conAddr);
        this.template.querySelector('.cb-ship-addr').checked = false;
        this.template.querySelector('.cb-con-ship-addr').checked = true;
    }
    ccAddressFill(event) {
        let val = event.target.checked;
        let name = event.target.name;

        if (name === 'useShipAddr') {
            if (val === true) {
                this.dataoms.ccShpAddr = true;
                this.template.querySelector('.use-con-addr').checked = false;
                this.template.querySelector('.new-bill-addr').checked = false;
                this.setDisabledAttr(true);
                this.setValueToSelAddr('ship');
            } else if (this.template.querySelector('.use-con-addr').checked === false && this.template.querySelector('.new-bill-addr').checked === false) {
                this.setValueToBlank();
            }
        } else if (name === 'useConAddr') {
            if (val === true) {
                this.dataoms.ccConAddr= true;
                this.template.querySelector('.use-ship-addr').checked = false;
                this.template.querySelector('.new-bill-addr').checked = false;
                this.setDisabledAttr(true);
                this.setValueToSelAddr('con');
            } else if (this.template.querySelector('.use-ship-addr').checked === false && this.template.querySelector('.new-bill-addr').checked === false) {
                this.setValueToBlank();
            }
        } else if (name === 'newBillAddr') {
            if (val === true) {
                this.dataoms.ccBillAddr=true;
                this.template.querySelector('.use-ship-addr').checked = false;
                this.template.querySelector('.use-con-addr').checked = false;
                this.setDisabledAttr(false);
            } else if (this.template.querySelector('.use-ship-addr').checked === false && this.template.querySelector('.use-con-addr').checked === false) {
                this.setValueToBlank();
            }
        }
    }

    updateConAddr(event) {
        this.dataoms.conAddrUpd = event.target.checked;
        
    }
    showOrderSuccessMsg() {
            const event = new ShowToastEvent({
                "title": "Success!",
                "variant": 'success',
                "mode":'sticky',
                "message": this.dataoms.salesorderno+" order created successfully!",
            });
            this.dispatchEvent(event);
    }
    setSelectedOption(event){
        let val = event.target.value;
        if(event.target.name === 'shippingMethod'){
            this.dataoms.selectedShippingMethod = val;
            this.dataoms.ordSimulateRequired = true;
        }
    }
    handleAdressActive(){
        if(this.isAddrLoaded)
            return;
        this.isAddrLoaded = true;
    }

     setAdressFields(){
        //Shipping Address
        this.dataoms.shpAddrName = this.template.querySelector('.ship-fn-val').value;
        this.dataoms.shpAddrName2 = this.template.querySelector('.ship-ln-val').value;
        this.dataoms.shpAddrStreet = this.template.querySelector('.ship-st-val').value;
        this.dataoms.shpAddrStreet2 = this.template.querySelector('.ship-st-val2').value;
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
        this.dataoms.conAddrStreet2 = this.template.querySelector('.con-st-val2').value;
        this.dataoms.conAddrCity = this.template.querySelector('.con-ct-val').value;
        this.dataoms.conAddrState = this.template.querySelector('.con-sc-val').value;
        this.dataoms.conAddrZipCode = this.template.querySelector('.con-pc-val').value;
        this.dataoms.conAddrCountry = this.template.querySelector('.con-cc-val').value;
        this.dataoms.conAddrEmail = this.template.querySelector('.con-mail-val').value;
        this.dataoms.conAddrPhone = this.template.querySelector('.con-ph-val').value;
        this.dataoms.conAddrCompanyName = this.template.querySelector('.con-cn-val').value;
        
        //Billing Address fields
        this.dataoms.ccAddrName = this.template.querySelector('.bill-fn-val').value;
      //  this.dataoms.ccAddrName2 = this.template.querySelector('.bill-ln-val').value;
        this.dataoms.ccAddrStreet = this.template.querySelector('.bill-st-val').value;
        this.dataoms.ccAddrCity = this.template.querySelector('.bill-ct-val').value;
        this.dataoms.ccAddrState = this.template.querySelector('.bill-sc-val').value;
        this.dataoms.ccAddrZipCode = this.template.querySelector('.bill-pc-val').value;
        this.dataoms.ccAddrCountry = this.template.querySelector('.bill-cc-val').value;
     //   this.dataoms.ccAddrEmail = this.template.querySelector('.bill-mail-val').value;
     //   this.dataoms.ccAddrPhone = this.template.querySelector('.bill-ph-val').value;
        this.dataoms.ccAddrCompanyName = this.template.querySelector('.bill-cn-val').value;
    }

    activateSections(secNames){
        let _this = this;
        setTimeout(() => {
            _this.activeSections = secNames;
        }, 200);
    }

    setDisabledAttr(arg) {
        let billAddrFields = [...this.template.querySelectorAll('.billing-addr-field')];
        billAddrFields.forEach(item => {
            item.disabled = arg;
        });
    }
    explodeBom(event)
    {
      this.showSpinner = true;
      this.dataoms.selectedProductForBOM = event.currentTarget.dataset.id;
      this.dataoms.selectedCaseProductForBOM = event.currentTarget.dataset.cpid;
      explodeBomlwc(
          {
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
   
    setValueToSelAddr(val) {
        this.template.querySelector('.bill-fn-val').value = this.template.querySelector('.' + val + '-fn-val').value;
      //  this.template.querySelector('.bill-ln-val').value = this.template.querySelector('.' + val + '-ln-val').value;
        this.template.querySelector('.bill-st-val').value = this.template.querySelector('.' + val + '-st-val').value;
        this.template.querySelector('.bill-ct-val').value = this.template.querySelector('.' + val + '-ct-val').value;
        this.template.querySelector('.bill-sc-val').value = this.template.querySelector('.' + val + '-sc-val').value;
        this.template.querySelector('.bill-pc-val').value = this.template.querySelector('.' + val + '-pc-val').value;
        this.template.querySelector('.bill-cc-val').value = this.template.querySelector('.' + val + '-cc-val').value;
      //  this.template.querySelector('.bill-mail-val').value = this.template.querySelector('.' + val + '-mail-val').value;
       // this.template.querySelector('.bill-ph-val').value = this.template.querySelector('.' + val + '-ph-val').value;
        this.template.querySelector('.bill-cn-val').value = this.template.querySelector('.' + val + '-cn-val').value;
    }    
}