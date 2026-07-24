using { ContractService } from './contract-service';

annotate ContractService.Contracts with @(
    UI.HeaderInfo: {
        TypeName: 'Contrato',
        TypeNamePlural: 'Contratos de Fornecedores',
        Title: { $Type: 'UI.DataField', Value: title },
        Description: { $Type: 'UI.DataField', Value: ID }
    },

    UI.SelectionFields: [
        vendorId,
        status,
        validFrom,
        validTo
    ],

    UI.LineItem: [
        { $Type: 'UI.DataField', Value: ID, Label: 'ID do Contrato' },
        { $Type: 'UI.DataField', Value: title, Label: 'Título' },
        { $Type: 'UI.DataField', Value: vendorId, Label: 'ID Fornecedor' },
        { $Type: 'UI.DataField', Value: vendor.BusinessPartnerName, Label: 'Nome do Fornecedor' },
        { $Type: 'UI.DataField', Value: totalValue, Label: 'Valor Total' },
        { $Type: 'UI.DataField', Value: validFrom, Label: 'Início da Vigência' },
        { $Type: 'UI.DataField', Value: validTo, Label: 'Fim da Vigência' },
        { $Type: 'UI.DataField', Value: status, Label: 'Status' }
    ],

    UI.Facets: [
        {
            $Type: 'UI.ReferenceFacet',
            ID: 'ContractHeaderFacet',
            Label: 'Informações Gerais',
            Target: '@UI.FieldGroup#HeaderInfo'
        },
        {
            $Type: 'UI.ReferenceFacet',
            ID: 'ContractItemsFacet',
            Label: 'Itens do Contrato',
            Target: 'items/@UI.LineItem'
        }
    ],
    UI.FieldGroup #HeaderInfo: {
        Data: [
            { $Type: 'UI.DataField', Value: title, Label: 'Título do Contrato' },
            { $Type: 'UI.DataField', Value: vendorId, Label: 'Fornecedor (ID S/4HANA)' },
            { $Type: 'UI.DataField', Value: totalValue, Label: 'Valor Total Accumulado' },
            { $Type: 'UI.DataField', Value: validFrom, Label: 'Válido De' },
            { $Type: 'UI.DataField', Value: validTo, Label: 'Válido Até' },
            { $Type: 'UI.DataField', Value: status, Label: 'Status da Aprovação' }
        ]
    }
);

annotate ContractService.ContractItems with @(
    UI.HeaderInfo: {
        TypeName: 'Item',
        TypeNamePlural: 'Itens do Contrato'
    },
    UI.LineItem: [
        { $Type: 'UI.DataField', Value: materialId, Label: 'ID do Material' },
        { $Type: 'UI.DataField', Value: quantity, Label: 'Quantidade' },
        { $Type: 'UI.DataField', Value: unitPrice, Label: 'Preço Unitário' },
        { $Type: 'UI.DataField', Value: itemValue, Label: 'Valor Total do Item' }
    ]
);