import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import checkHighNetWorthStatus from '@salesforce/apex/HighNetWorthClientController.checkHighNetWorthStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hasCustomPermission from '@salesforce/customPermission/High_Net_Worth_Client_Service_Representative';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import WEBSITE_FIELD from '@salesforce/schema/Account.Website';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import TYPE_FIELD from '@salesforce/schema/Account.Type';
import BILLING_STREET_FIELD from '@salesforce/schema/Account.BillingStreet';
import BILLING_CITY_FIELD from '@salesforce/schema/Account.BillingCity';
import BILLING_STATE_FIELD from '@salesforce/schema/Account.BillingState';
import BILLING_COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountry';
import BILLING_POSTAL_CODE_FIELD from '@salesforce/schema/Account.BillingPostalCode';

export default class HighNetWorthClientPage extends LightningElement {

    @api recordId;
    @track isHighNetWorth = false;
    @track isEditMode = false;
    @track totalOpportunityAmount = 0;
    @track hasAccess = true;
    @track isLoading = true;
    @track error;

    accountFields = [
        NAME_FIELD,
        PHONE_FIELD,
        WEBSITE_FIELD,
        INDUSTRY_FIELD,
        TYPE_FIELD,
        BILLING_STREET_FIELD,
        BILLING_CITY_FIELD,
        BILLING_STATE_FIELD,
        BILLING_COUNTRY_FIELD,
        BILLING_POSTAL_CODE_FIELD
    ];

    @wire(getRecord, { recordId: '$recordId', fields: '$accountFields' })
    wiredAccount(result) {
        this.accountRecord = result;
        if (result.error) {
            this.error = result.error;
            this.hasAccess = false;
            this.isLoading = false;
        } else if (result.data) {
            this.hasAccess = true;
            this.checkHighNetWorthStatus();
        }
    }

    @wire(checkHighNetWorthStatus, { accountId: '$recordId' })
    wiredHighNetworthStatus(result){
        if (result.error) {
            this.error = result.error;
            this.isLoading = false;
        } else if (result.data) {
            this.isHighNetWorth = result.data.isHighNetWorth;
            this.totalOpportunityAmount = result.data.totalAmount;
            this.determineEditMode();
            this.isLoading = false;
        }
    }

    get hasCustomPermission() {
        return hasCustomPermission;
    }

    get showInsufficientPrivileges() {
        return !this.hasAccess;
    }

    get showContent() {
        return this.hasAccess && !this.isLoading;
    }

    get highNetWorthBadgeClass() {
        return this.isHighNetWorth ? 'slds-badge slds-theme_success' : 'slds-badge slds-theme_default';
    }

    get highNetWorthStatus() {
        return this.isHighNetWorth ? 'High Net Worth Client' : 'Standard Client';
    }

    get formattedAmount() {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(this.totalOpportunityAmount);
    }

    get editButtonLabel() {
        return this.isEditMode ? 'Cancel Edit' : 'Edit';
    }

    get showEditButton() {
        return this.hasAccess && (!this.isHighNetWorth || this.hasCustomPermission);
    }

    get editIconName() {
        return this.isEditMode ? 'utility:close' : 'utility:edit';
    }


    checkHighNetWorthStatus() {
        // This method is called after the account record is loaded
        // The wire method will handle the actual check
    }

    determineEditMode() {
        if (this.isHighNetWorth && this.hasCustomPermission) {
            // High net worth client with special permission - inline edit mode
            this.isEditMode = true;
        } else if (this.isHighNetWorth && !this.hasCustomPermission) {
            // High net worth client without special permission - read-only mode
            this.isEditMode = false;
        } else {
            // Regular client - default behavior (read-only initially, can be toggled)
            this.isEditMode = false;
        }
    }

    handleEdit() {
        if (this.isHighNetWorth && !this.hasCustomPermission) {
            // Should not reach here, but adding as safety
            this.showToast('Error', 'You do not have permission to edit High Net Worth Client records', 'error');
            return;
        }
        this.isEditMode = !this.isEditMode;
    }

    handleSuccess(event) {
        this.isEditMode = false;
        this.showToast('Success', 'Record updated successfully', 'success');
        
        // Refresh the high net worth status in case opportunities changed
        return refreshApex(this.highNetWorthResult);
    }

    handleError(event) {
        this.showToast('Error', 'Error updating record: ' + event.detail.message, 'error');
    }

    handleCancel() {
        this.isEditMode = false;
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    // Handle form submit for custom validation if needed
    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
}