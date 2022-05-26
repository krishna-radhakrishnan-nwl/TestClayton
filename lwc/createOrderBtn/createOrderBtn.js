import { LightningElement,track,api } from 'lwc';
import  getquerydata  from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.getquerydata';
import  createOrder from '@salesforce/apex/CreateOMSOrderControllerLWC_NWL.createOrder';
export default class CreateOrderBtn extends LightningElement {
    @api recId;
    @api isCase;
    @track showPopup = false;
    @track showOMS = false;
    @track showSAP = false;
    @track casedetails;
    lwcpage='';
    @track oms=false;
    @track sales=false;
    @track buttonname;
    
    getorderpage()
    { 
        getquerydata({
            recordId: this.recId  
        }).then(data=>{
            this.casedetails = JSON.parse(JSON.stringify(data));
            console.log(JSON.stringify(this.casedetails));
            createOrder({
                caseId: this.recId,
                caseBrand: this.casedetails.Brand__c,
                caseSubBrand: this.casedetails.Sub_Brand__c,
                caseRegion: this.casedetails.Region__c,
                shipTo: this.casedetails.ShipTo__c,
                recordType: this.casedetails.RecordTypeId,
                reason: this.casedetails.Reason__c  
            }).then(data=>{
                this.lwcpage=data;
                console.log('check1'+this.lwcpage);
                if(this.lwcpage ==='oms')
                {
                    this.oms=true;
                   
                }
                else{
                    this.sales=true;
                  
                }
                this.showPopup = true;
                console.log('values'+this.oms+this.sales);
            }).catch(error=>{
                console.log(error);
            })
        }).catch(error=>{
            console.log(error); 
        })

    }
    handleCreateReturn(){    
        if(this.isCase){
            this.oms=false;
            this.sales=false;
            this.getorderpage();
        }else{
            this.showPopup = true;
        }       
        //this.showPopup = true;
        console.log('In handleCreateReturn..');
    }

    handleClose(){
        this.showPopup = false;
        
        console.log('In Close..');
    }

}