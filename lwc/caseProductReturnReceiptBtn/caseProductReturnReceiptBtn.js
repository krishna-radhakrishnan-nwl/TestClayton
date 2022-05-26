import { LightningElement,api, track} from 'lwc';

export default class CaseProductReturnReceiptBtn extends LightningElement {

    @track showPopup = false;
    @api recordId;
    @api rmaNumber;
    @api orderNumber;
    

    handleReturnReceipt(){
        console.log('start open popup');
        this.showPopup = true;
    }

    handleClose(){
        this.showPopup = false;
        console.log('In Close..');
    }

}