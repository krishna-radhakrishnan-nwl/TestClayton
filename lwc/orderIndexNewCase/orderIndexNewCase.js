import { LightningElement,api,track } from 'lwc';

export default class OrderIndexNewCase extends LightningElement {



    @api orderId;
    @api contactId
    @track isModalOpen = false;

    openModal(){
        this.isModalOpen = true;
        console.log(this.orderId)
        console.log(this.contactId);
    }

    closeModal(){
        this.isModalOpen = false;
    }

}