using { ContractService } from './contract-service';

annotate ContractService.Contracts with {
    vendorId @(
        Common.ValueList: {
            $Type: 'Common.ValueListType',
            Label: 'Selecionar Fornecedor (S/4HANA)',
            CollectionPath: 'BusinessPartners',
            Parameters: [
                {
                    $Type: 'Common.ValueListParameterInOut',
                    LocalDataProperty: vendorId,
                    ValueListProperty: 'BusinessPartner'
                },
                {
                    $Type: 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'BusinessPartnerFullName'
                }
            ]
        }
    );
};

annotate ContractService.Contracts with @(
    UI.HeaderInfo: {
        TypeName: 'Contrato',
        TypeNamePlural: 'Contratos de Fornecedores',
        Title: {
            $Type: 'UI.DataField',
            Value: title
        },
        Description: {
            $Type: 'UI.DataField',
            Value: ID
        }
    },

    UI.SelectionFields: [
        vendorId,
        status,
        validFrom,
        validTo
    ],

    UI.LineItem: [
        {
            $Type: 'UI.DataField',
            Value: ID,
            Label: 'ID do Contrato'
        },
        {
            $Type: 'UI.DataField',
            Value: title,
            Label: 'Título'
        },
        {
            $Type: 'UI.DataField',
            Value: vendorId,
            Label: 'Código do Fornecedor'
        },
        {
            $Type: 'UI.DataField',
            Value: vendorName,
            Label: 'Fornecedor'
        },
        {
            $Type: 'UI.DataField',
            Value: totalValue,
            Label: 'Valor Total'
        },
        {
            $Type: 'UI.DataField',
            Value: validFrom,
            Label: 'Início da Vigência'
        },
        {
            $Type: 'UI.DataField',
            Value: validTo,
            Label: 'Fim da Vigência'
        },
        {
            $Type: 'UI.DataField',
            Value: status,
            Label: 'Status'
        }
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
            {
                $Type: 'UI.DataField',
                Value: title,
                Label: 'Título do Contrato'
            },
            {
                $Type: 'UI.DataField',
                Value: vendorId,
                Label: 'Fornecedor'
            },
            {
                $Type: 'UI.DataField',
                Value: totalValue,
                Label: 'Valor Total Acumulado'
            },
            {
                $Type: 'UI.DataField',
                Value: validFrom,
                Label: 'Válido De'
            },
            {
                $Type: 'UI.DataField',
                Value: validTo,
                Label: 'Válido Até'
            },
            {
                $Type: 'UI.DataField',
                Value: status,
                Label: 'Status da Aprovação'
            }
        ]
    }
);

annotate ContractService.BusinessPartners with @(
    UI.HeaderInfo: {
        TypeName: 'Fornecedor',
        TypeNamePlural: 'Fornecedores'
    },

    UI.LineItem: [
        {
            $Type: 'UI.DataField',
            Value: BusinessPartner,
            Label: 'Código'
        },
        {
            $Type: 'UI.DataField',
            Value: BusinessPartnerFullName,
            Label: 'Nome'
        },
        {
            $Type: 'UI.DataField',
            Value: BusinessPartnerCategory,
            Label: 'Categoria'
        }
    ]
);

annotate ContractService.ContractItems with @(
    UI.HeaderInfo: {
        TypeName: 'Item',
        TypeNamePlural: 'Itens do Contrato'
    },

    UI.LineItem: [
        {
            $Type: 'UI.DataField',
            Value: materialId,
            Label: 'Material'
        },
        {
            $Type: 'UI.DataField',
            Value: quantity,
            Label: 'Quantidade'
        },
        {
            $Type: 'UI.DataField',
            Value: unitPrice,
            Label: 'Preço Unitário'
        },
        {
            $Type: 'UI.DataField',
            Value: itemValue,
            Label: 'Valor do Item'
        }
    ]
);