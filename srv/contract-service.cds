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
        as projection on my.Contracts {

            *,
            virtual vendorName : String(255),
            virtual statusCriticality : Integer

        } actions {
            @cds.odata.bindingparameter.name: '_it'
            @Common.SideEffects: { TargetProperties: ['_it/status'] }
            action approveContract() returns Contracts;

            @cds.odata.bindingparameter.name: '_it'
            @Common.SideEffects: { TargetProperties: ['_it/status'] }
            action rejectContract() returns Contracts;
        };


    @readonly
    entity BusinessPartners as projection on external.A_BusinessPartner {
        key BusinessPartner,
        BusinessPartnerFullName,
        BusinessPartnerGrouping,
        BusinessPartnerCategory
    };

    @readonly
    entity ContractStatuses as projection on my.ContractStatuses;



}