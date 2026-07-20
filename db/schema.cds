namespace sapanalytics.vendorcontracts;

using { cuid, managed, Country} from '@sap/cds/common';

type ContractStatus : String enum {
    Draft = 'D';
    PendingApproval = 'P';
    Approved = 'A';
    Rejected = 'R';
    Terminated = 'T';
}

entity Contracts : cuid, managed {
    contractNumber : String(10)  @title: 'Contract Number';
    title          : String(100) @assert.notNull @title: 'Title';
    description    : String(500) @title: 'Description';
    status         : ContractStatus default 'D' @title: 'Status';
    validFrom      : Date @assert.notNull @title: 'Valid From';
    validTo        : Date @title: 'Valid To';
    totalValue     : Decimal(15,2) @title: 'Total Value';
    currency       : String(3) default 'BRL' @title: 'Currency';

    vendorId       : String(10) @assert.notNull @title: 'Vendor ID';

    items          : Composition of many ContractItems on items.contract = $self;
}

entity ContractItems : cuid {
    contract       : Association to Contracts;
    itemNumber     : Integer @title: 'Item Number';
    materialId     : String(18) @assert.notNull @title: 'Material ID';
    quantity       : Decimal(13,3) @assert.notNull @title: 'Quantity';
    unitPrice      : Decimal(11,2) @assert.notNull @title: 'Unit Price';
    itemValue      : Decimal(15,2) @title: 'Item Value';
    uom            : String(3) default 'PC' @title: 'Unit of Measure';
}