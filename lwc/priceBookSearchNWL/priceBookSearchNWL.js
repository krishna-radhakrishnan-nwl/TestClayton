import { LightningElement, api, track, wire } from 'lwc';
import searchPriceBookCall from '@salesforce/apex/MapaPriceOfferController_NWL.searchPriceBook';

export default class PriceBookSearchNWL extends LightningElement {
    
    searchText = '';
    lastSearchtext;
    finalSearchText = '';
    delayPricebookTimeout;

    @api htmlAttribute;
    @api pricebookAccountId;
    
    @track showContactOption = false;
    @track displayContactList = [];
    @track selectedContact;
    @track previewRecordId = null;
    delayApexSearch;
    @track showSpinner=true;
    @track disableInput = true;

    @wire(searchPriceBookCall, {sWildCardText:'$finalSearchText', accountId:'$pricebookAccountId'})
    wiredPriceBookData({error, data}) {
        this.showSpinner = false;
        this.disableInput = false;        
        console.log('Response from apex received');
        const inputElement = this.template.querySelector('[data-id="inputbox"]');        
        if(inputElement!==null) {
            inputElement.focus();
        }
        if(data){
            console.log(JSON.stringify(data));
            this.displayContactList = data;
            if(this.displayContactList.length > 0)  {
                this.showContactOption = true;
            } else {
                console.log('Disappearing dropdown 0');
                this.showContactOption = false;
            }
        } else if (error) {
            console.error('Error:', error);
        }
    }

    get isContactBlank() {
        return (this.selectedContact===null || this.selectedContact===undefined);   
    }

    keycheck(event) {
        if(event.which==13) {
            event.preventDefault();            
        }
    }

    handleIconClick(event) {
        event.preventDefault();
    }

    lookupContact(event) {  
        this.searchText = event.target.value;        
        if (event.keyCode === 27 || !this.searchText.trim() || this.searchText.length===0) { 
            this.selectedContact = null;
            this.displayContactList = [];
            console.log('Disappearing dropdown 2');
            this.showContactOption = false;
        }
        else if(this.searchText.trim() !== this.lastSearchtext ) {            
            clearTimeout(this.delayApexSearch);
            this.delayApexSearch = setTimeout(() => {
                this.lastSearchtext = this.searchText.trim();
                
                console.log('finalSearchText updated : '+this.lastSearchtext.toLowerCase());
                console.log('Account ID : ', this.pricebookAccountId);

                this.showSpinner = true;
                this.disableInput = true;
                this.finalSearchText = this.lastSearchtext.toLowerCase();
            }, 400);
        }
    }

    displayContactOption() {
        const inputElement = this.template.querySelector('[data-id="inputbox"]');
        inputElement.focus();
        if(this.displayContactList.length>0) {
            this.showContactOption = true;
        }
    }

    hideContactOption() {        
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { this.delayedBlur(); },500);
    }

    delayedBlur() {
        console.log('Disappearing dropdown 3');
        this.showContactOption = false;
        //this.displayContactList = [];
    }

    @api
    clearSelection() {
        this.selectedContact=null;
        this.searchText = '';
        this.lastSearchtext = '';
        this.finalSearchText = '';
        this.displayContactList = [];
        console.log('Disappearing dropdown 4');
        this.showContactOption = false;
        this.previewRecordId = null;
        this.dispatchEvent(new CustomEvent('clear', {detail:{type:this.htmlAttribute}}));
    }

    handleSelection(event) {
        let target = event.target;
        let index = target.dataset.selectedindex;
        while(!index) {
            index = target.dataset.selectedindex;
            target = target.parentNode;    
        }
        this.selectedContact = this.displayContactList[index];
        console.log('Disappearing dropdown 1');
        this.showContactOption = false;
        this.displayContactList = [];
        this.searchText = '';
        this.lastSearchtext = '';
        this.finalSearchText = '';        
        console.log(JSON.stringify(this.selectedContact));
        this.dispatchEvent(new CustomEvent('select', {detail:  {
                value : this.selectedContact,
                type  : this.htmlAttribute
            }
        }));
    }

    @api
    setSelection(value) {
        this.selectedContact = value;
    }

    /* Handle Mouse Over*/
    handleMouseover() {    
        if(this.selectedContact!==null && this.selectedContact!==undefined) {
            this.previewRecordId = this.selectedContact.Id;
            //console.log('Preview Record ID :: ', this.previewRecordId);
            if(this.previewRecordId!==null && this.previewRecordId!==undefined) {
                clearTimeout(this.delayPricebookTimeout);
                this.delayPricebookTimeout = setTimeout(() => {
                    const toolTipDiv = this.template.querySelector('[data-id="disPricebookModelToolTip"]');
                    toolTipDiv.style.opacity = 1;
                    toolTipDiv.style.display = "block";
                }, 150);
            }
        }   
    }

    /* Handle Mouse Out*/
    handleMouseout() {
        if(this.previewRecordId!==null && this.previewRecordId!==undefined) {
            clearTimeout(this.delayPricebookTimeout);
            this.delayPricebookTimeout = setTimeout(() => {
                const toolTipDiv = this.template.querySelector('[data-id="disPricebookModelToolTip"]');
                toolTipDiv.style.opacity = 0;
                toolTipDiv.style.display = "none";
            },140);
        }
    }
}