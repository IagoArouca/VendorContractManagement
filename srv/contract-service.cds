using { sapanalytics.vendorcontracts as my } from '../db/schema';

service ContractService @(path: '/browse') {

    @odata.draft.enabled
    entity Contracts @(restrict: [
        { grant: ['READ'], to: 'Viewer' },
        { grant: ['*'], to: 'Manager' },
        { grant: ['Approval'], to: 'Approver' }
    ]) as projection on my.Contracts;

    entity ContractItems as projection on my.ContractItems;

    action approveContract(contractId: my.Contracts:ID) returns Contracts;
}