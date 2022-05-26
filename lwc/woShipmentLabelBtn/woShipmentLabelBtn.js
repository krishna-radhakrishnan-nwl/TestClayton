import { LightningElement,api,track } from 'lwc';
import transitLabel from '@salesforce/apex/WorkOrderCustomBtns_NWL.transitLabel';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import success from '@salesforce/label/c.success';
import Error_Message from '@salesforce/label/c.Error_Message';
import ShipmentLabel from '@salesforce/label/c.wobtnShipmentLabel';
import workOrderSagawaSuccess from '@salesforce/label/c.workOrderSagawaSuccess';
import workOrderSagawaError from '@salesforce/label/c.workOrderSagawaError';

export default class WoShipmentLabelBtn extends LightningElement {
    @api recId;  
    @track showSpinner = false;
    error;

    label = {
        success,
        Error_Message,
        ShipmentLabel,
        workOrderSagawaSuccess,
        workOrderSagawaError
    }

    handleShipmentLabel() {
        this.showSpinner = true;         
        transitLabel({ workorderIds: this.recId,workOrderType:'shipment'})
            .then((result) => { 
                this.showSpinner = false;                                  
                this.error = undefined;                 
                const event = new ShowToastEvent({
                    title: this.label.success,
                    variant: 'success',
                    message: this.label.workOrderSagawaSuccess,                   
                });                                                          
                this.dispatchEvent(event);                                               
            })
            .catch((error) => {
                this.showSpinner = false;              
                this.error = error;                               
                const event = new ShowToastEvent({
                    title: this.label.Error_Message,
                    variant: 'error',
                    message: this.label.workOrderSagawaError,
                    mode:'sticky'
                });
                this.dispatchEvent(event);               
            });
    }
}