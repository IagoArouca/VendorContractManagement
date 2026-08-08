namespace sapanalytics.vendorcontracts;

using { API_BUSINESS_PARTNER as external } from '../srv/external/API_BUSINESS_PARTNER';
using { cuid, managed, sap.common.CodeList } from '@sap/cds/common';

type ContractStatus : String enum {
    @title: 'Draft'
    Draft = 'D';

    @title: 'Pending Approval'
    PendingApproval = 'P';

    @title: 'Approved'
    Approved = 'A';

    @title: 'Rejected'
    Rejected = 'R';

    @title: 'Terminated'
    Terminated = 'T';
}

entity ContractStatuses : CodeList {
    key code : ContractStatus;
        text : String(50);
}

entity Contracts : cuid, managed {
    @readonly
    contractNumber : String(10)  @title: 'Contract Number';
    title          : String(100) @assert.notNull @title: 'Title';
    description    : String(500) @title: 'Description';
    @readonly
    status         : ContractStatus default 'D' @title: 'Status';
    
    validFrom      : Date @assert.notNull @title: 'Inicio da Vigência';
    validTo        : Date @title: 'Fim da Vigência';
    @readonly
    totalValue     : Decimal(15,2) @title: 'Total Value';
    currency       : String(3) default 'BRL' @title: 'Currency';

    vendorId       : String(10) @assert.notNull @title: 'Fornecedor';

    companyCode    : String(4)  @title: 'Empresa (Company Code)';
    purchasingOrg  : String(4)  @title: 'Org. Compras (Purchasing Org)';
    purchasingGroup: String(3)  @title: 'Grupo Compras (Purchasing Group)';
    contractType   : String(4)  @title: 'Tipo de Contrato';


    items          : Composition of many ContractItems on items.contract = $self;
}

entity ContractItems : cuid {
    contract       : Association to Contracts;
    itemNumber     : Integer @title: 'Item Number';
    materialId     : String(18) @assert.notNull @title: 'Material ID';
    quantity       : Decimal(13,0) @assert.notNull @title: 'Quantity';
    unitPrice      : Decimal(11,2) @assert.notNull @title: 'Unit Price';
    @readonly
    itemValue      : Decimal(15,2) @title: 'Item Value';
    uom            : String(3) default 'PC' @title: 'Unit of Measure';

    plant                     : String(4)  @title: 'Centro (Plant)';
    accountAssignmentCategory : String(1)  @title: 'Cat. Classificação Contábil';
    glAccount                 : String(10) @title: 'Conta Razão (G/L Account)';
    costCenter                : String(10) @title: 'Centro de Custo (Cost Center)';
}