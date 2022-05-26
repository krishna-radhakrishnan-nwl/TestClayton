import { LightningElement,track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchProducts from "@salesforce/apex/ConsumerServiceButtonsController_NWL.searchProducts";


//custom labels
import CS_Comm_Search_No_Results  from '@salesforce/label/c.CS_Comm_Search_No_Results';
import QS_Material_Number  from '@salesforce/label/c.QS_Material_Number';
import QS_Product_Name  from '@salesforce/label/c.QS_Product_Name';
import QS_Brand  from '@salesforce/label/c.QS_Brand';
import QS_EAN_UPC  from '@salesforce/label/c.QS_EAN_UPC';
import QS_Catalog_Number  from '@salesforce/label/c.QS_Catalog_Number';
import QS_Model_Number  from '@salesforce/label/c.QS_Model_Number';
import QS_Color  from '@salesforce/label/c.QS_Color';
import QS_Size  from '@salesforce/label/c.QS_Size';
import QS_Region  from '@salesforce/label/c.QS_Region';
import QS_Material_Status  from '@salesforce/label/c.QS_Material_Status';
import Record_Type_RecordChooser_NWL  from '@salesforce/label/c.Record_Type_RecordChooser_NWL';
import QS_Web_Product_Name  from '@salesforce/label/c.QS_Web_Product_Name';
import QS_Consumer_Product_Name  from '@salesforce/label/c.QS_Consumer_Product_Name';
import QS_Category  from '@salesforce/label/c.QS_Category';
import QS_Country_Language  from '@salesforce/label/c.QS_Country_Language';
import QS_Material_Type  from '@salesforce/label/c.QS_Material_Type';
import QS_Mold_Number  from '@salesforce/label/c.QS_Mold_Number';
import QS_Old_Material_Number  from '@salesforce/label/c.QS_Old_Material_Number';
import QS_Division  from '@salesforce/label/c.QS_Division';
import QS_Search  from '@salesforce/label/c.QS_Search';
import QC_Reset from '@salesforce/label/c.QC_Reset';
import Cancel_Createworkorderproduct  from '@salesforce/label/c.Cancel_Createworkorderproduct';
import SearchCaseProduct from '@salesforce/label/c.SearchCaseProduct';
import ModifyClosedCases from '@salesforce/label/c.ModifyClosedCases';
import AddCaseProduct from '@salesforce/label/c.AddCaseProduct';

import LANG from '@salesforce/i18n/lang';

export default class addCaseProductBtn extends LightningElement {
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @track isModalOpen = false;

    lang = LANG;

    

    //these are the input fields to search by:
    materialNumber = '';
    materialDesc = '';
    jamaterialDesc;
    brandDesc = '';
    productUPC = '';
    productModelNumber = '';
    productColor = '';
    productSize = '';
    productRegion ='';
    productMaterialStatus = '';
    productRT = '';
    consumerProductName = '';
    webProductName = '';
    productCategory = '';
    productCountryLanguage = '';
    materialType ='';
    productMoldNumber ='';
    productCatalogNumber ='';
    oldMatNumber ='';
    productDivision ='';

    //handle displays:
    displayResults = '';
    displaySpinner = '';
    displayError = '';
    @api jaFields;
    
    @api caseStatus;
    @api caseId;
    @api caseBrand;
    @track techApparelBrand=false;
    @track rcpBrand=false;

    label = {
        CS_Comm_Search_No_Results,
        QS_Material_Number,
        QS_Product_Name,
        QS_Brand,
        QS_EAN_UPC,
        QS_Catalog_Number,
        QS_Model_Number,
        QS_Color,
        QS_Size,
        QS_Region,
        QS_Material_Status,
        Record_Type_RecordChooser_NWL,
        QS_Web_Product_Name,
        QS_Consumer_Product_Name,
        QS_Category,
        QS_Country_Language,
        QS_Material_Type,
        QS_Mold_Number,
        QS_Old_Material_Number,
        QS_Division,
        QS_Search,
        Cancel_Createworkorderproduct,
        QC_Reset,
        SearchCaseProduct,
        ModifyClosedCases,
        AddCaseProduct
    };

    //handle pressing enter for search
    keycheck(component){
        if (component.which == 13){
            this.searchForProducts()
        }
    }

    openModal() {
        // to open modal set isModalOpen track value as true
        //Closed cases should not be able to use the add case product button
        if (this.caseStatus === 'Closed') {
            this.dispatchEvent(
                new ShowToastEvent({                  
                    variant: 'info',
                    message: this.label.ModifyClosedCases,
                    mode: 'sticky'
                })
            );


        }else{
            this.isModalOpen = true;
            if(this.caseBrand == 'Tech Apparel'){
                this.techApparelBrand = true;
            }else if(this.caseBrand == 'Rubbermaid Commercial'){
                this.rcpBrand = true;
            }

            if(this.lang == 'ja'){
                this.jaFields = true;
            }else{
                this.jaFields = false;
            }

        }
    }

    handleReset(event){
        this.template.querySelectorAll('lightning-input[data-id="reset"]').forEach(element => {
          element.value = null;
        });
        this.materialNumber = '';
        this.materialDesc = '';
        this.brandDesc = '';
        this.productUPC = '';
        this.productModelNumber = '';
        this.productColor = '';
        this.productSize = '';
        this.productRegion ='';
        this.productMaterialStatus = '';
        this.productRT = '';
        this.consumerProductName = '';
        this.webProductName = '';
        this.productCategory = '';
        this.productCountryLanguage = '';
        this.materialType ='';
        this.productMoldNumber ='';
        this.productCatalogNumber ='';
        this.oldMatNumber ='';
        this.productDivision ='';
        this.displayResults=false;
        this.products=[];
      }

    closeModal() {
        // to close modal set isModalOpen track value as false
        this.displayResults = false;
        this.products = [];
        this.isModalOpen = false;
        this.handleReset();
    }

    submitDetails() {
        // to close modal set isModalOpen track value as false
        //Add your code to call apex method or do some processing
        this.isModalOpen = false;
    }

    get options() {
        return [
            { label: 'N/A', value: ''},
            { label: 'SAP', value: 'SAP Product' },
            { label: 'NON-SAP', value: 'Non-SAP Product' },
            { label: 'AFS', value: 'AFS SAP Product' },
            { label: 'Oracle', value: 'HF Product' },
        ];
    }

    handleMatNum(event){
        this.materialNumber = event.target.value;
    }
    handleMatDesc(event){      
        this.materialDesc = event.target.value;
    }

    handlejaMatDesc(event){
        this.jamaterialDesc = event.target.value;
    }
    handleBrandDesc(event){
        this.brandDesc = event.target.value;
    }
    handleUPC(event){
        this.productUPC = event.target.value;
    }
    handleModelNumber(event){
        this.productModelNumber = event.target.value;
    }
    handleColor(event){
        this.productColor = event.target.value;
    }
    handleSize(event){
        this.productSize = event.target.value;
    }
    handleRegion(event){
        this.productRegion = event.target.value;
    }
    handleMaterialStatus(event){
        this.productMaterialStatus = event.target.value;
    }
    handleproductRT(event){
        this.productRT = event.target.value;
    }
    handlewebProductName(event){
        this.webProductName = event.target.value;
    }
    handleConsumerProductName(event){
        this.consumerProductName = event.target.value;
    }
    handleproductCategory(event){
        this.productCategory = event.target.value;
    }
    handlematerialType(event){
        this.materialType = event.target.value;
    }
    handleproductMoldNumber(event){
        this.productMoldNumber = event.target.value;
    }
    handleproductCatalogNumber(event){
        this.productCatalogNumber = event.target.value;
        }
    handleoldMatNumber(event){
        this.oldMatNumber = event.target.value;
    }
    handleproductDivision(event){
        this.productDivision = event.target.value;
    }
    handleproductCountryLanguage(event){
        this.productCountryLanguage = event.target.value;
    }

    searchForProducts() {
        this.products = [];
        this.displayResults = false;
        this.displaySpinner = true;
        searchProducts({
            materialNumber: this.materialNumber,
            materialDesc: this.materialDesc,
            jamaterialDesc: this.jamaterialDesc,
            brandDesc: this.brandDesc,
            upc: this.productUPC,
            modelNumber: this.productModelNumber,
            color: this.productColor,
            size: this.productSize,
            region: this.productRegion,
            materialStatus: this.productMaterialStatus,
            webProductName: this.webProductName,
            consumerProductName: this.consumerProductName,
            productCategory: this.productCategory,
            countryLanguage: this.productCountryLanguage,
            materialType: this.materialType,
            moldNumber: this.productMoldNumber,
            catalogNumber: this.productCatalogNumber,
            oldMaterialNumber: this.oldMatNumber,
            division: this.productDivision,
            productRT: this.productRT})
            .then((result) => {
                if (result.length === 0) {
                    this.products = [];
                    this.message = CS_Comm_Search_No_Results;
                    this.displayResults = false;
                    this.displaySpinner = false;
                    this.displayError = true;
                } else {
                    this.products = result;
                    this.message = "";
                    this.displayResults = true;
                    this.displaySpinner = false;
                    this.displayError = false;
                }
                this.error = undefined;
            })
            .catch((error) => {
                this.displayResults = false;
                this.error = error;
                this.recordsList = undefined;
                this.displaySpinner = false;
                this.displayError = true;
                this.message = CS_Comm_Search_No_Results;
            });
    }



}