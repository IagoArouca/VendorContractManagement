using { sapanalytics.vendorcontracts as my } from '../db/schema';
using { API_BUSINESS_PARTNER as external } from './external/API_BUSINESS_PARTNER';

service ContractService @(path:'/browse') {

    @odata.draft.enabled
    entity Contracts
        @(restrict: [
            { grant:['READ'], to:'Viewer' },
            { grant:['*'], to:'Manager' },
            { grant:['Approval'], to:'Approver' }
        ])
        as projection on my.Contracts
        actions {
            action approveContract() returns Contracts;
        };

    @readonly
    entity BusinessPartners as projection on external.A_BusinessPartner {
        key BusinessPartner,
        BusinessPartnerFullName,
        BusinessPartnerGrouping,
        BusinessPartnerCategory
    };
}