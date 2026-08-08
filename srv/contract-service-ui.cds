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

annotate ContractService.Contracts with {
    vendorName @(
        Common.Label: 'Fornecedor',
        Core.Computed: true
    );
};

annotate ContractService.Contracts with {
    status @(
        Common.Label: 'Status',
        Common.ValueListWithFixedValues: true,
        Common.ValueList: {
            $Type: 'Common.ValueListType',
            CollectionPath: 'ContractStatuses',
            Parameters: [
                {
                    $Type: 'Common.ValueListParameterInOut',
                    LocalDataProperty: status,
                    ValueListProperty: 'code'
                },
                {
                    $Type: 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'text'
                }
            ]
        },
        UI.Criticality: statusCriticality,
        UI.CriticalityRepresentation: #WithIcon
    );
};



annotate ContractService.Contracts with @(
    UI.HeaderInfo: {
        TypeName: 'Contrato',
        TypeNamePlural: 'Contratos de Fornecedores',
        Title: {
            $Type: 'UI.DataField',
            Value: title
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
            Value: companyCode,
            Label: 'Empresa'
        },
        {
            $Type: 'UI.DataField',
            Value: totalValue,
            Label: 'Valor Total'
        },
        {
            $Type: 'UI.DataField',
            Value: currency,
            Label: 'Moeda'
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
            Criticality: statusCriticality,
            CriticalityRepresentation: #WithIcon,
            Label: 'Status'
        }
    ],

    UI.Identification: [
        {
            $Type: 'UI.DataFieldForAction',
            Action: 'ContractService.approveContract',
            Label: 'Aprovar Contrato',
            Determining: true,
            Criticality: #Success,
            @UI.Hidden: (status = 'A' or status = 'R')
        },
        {
            $Type: 'UI.DataFieldForAction',
            Action: 'ContractService.rejectContract',
            Label: 'Reprovar Contrato',
            Determining: true,
            Criticality: #Negative,
            @UI.Hidden: (status = 'A' or status = 'R')
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
            ID: 'OrganizationalFacet',
            Label: 'Dados Organizacionais S/4HANA',
            Target: '@UI.FieldGroup#OrgInfo'
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
                Label: 'Fornecedor ID'
            },
            {
                $Type: 'UI.DataField',
                Value: vendorName,
                Label: 'Nome do Fornecedor'
            },
            {
                $Type: 'UI.DataField',
                Value: contractNumber,
                Label: 'Nº Contrato (S/4HANA)'
            },
            {
                $Type: 'UI.DataField',
                Value: totalValue,
                Label: 'Valor Total Acumulado'
            },
            {
                $Type: 'UI.DataField',
                Value: currency,
                Label: 'Moeda'
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
                Label: 'Status',
                Criticality: statusCriticality,
                CriticalityRepresentation: #WithIcon,
            }
        ]
    },

    UI.FieldGroup #OrgInfo: {
        Data: [
            {
                $Type: 'UI.DataField',
                Value: companyCode,
                Label: 'Empresa (Company Code)'
            },
            {
                $Type: 'UI.DataField',
                Value: purchasingOrg,
                Label: 'Org. Compras (Purchasing Org)'
            },
            {
                $Type: 'UI.DataField',
                Value: purchasingGroup,
                Label: 'Grupo Compras (Purchasing Group)'
            },
            {
                $Type: 'UI.DataField',
                Value: contractType,
                Label: 'Tipo de Contrato'
            }
        ]
    }
);

annotate ContractService.Contracts with @(
    Common.SideEffects #ItemChanges: {
        SourceEntities: [ items ],
        TargetProperties: [ 'totalValue' ]
    },

    Common.SideEffects #ApproveContract: {
        TriggerAction: 'ContractService.approveContract',
        TargetProperties: [ 'status', 'contractNumber' ]
    },

    Capabilities.UpdateRestrictions: {
        Updatable: (status = 'P' or status = 'D')
    },

    Capabilities.DeleteRestrictions: {
        Deletable: (status = 'P' or status = 'D')
    },

    UI.UpdateHidden: (status = 'A' or status = 'R')
);


annotate ContractService.ContractItems with {
    quantity @( Common.Scale: 0 );
};

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
            Value: plant,
            Label: 'Centro (Plant)'
        },
        {
            $Type: 'UI.DataField',
            Value: quantity,
            Label: 'Quantidade'
        },
        {
            $Type: 'UI.DataField',
            Value: uom,
            Label: 'Unid. Medida'
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
        },
        {
            $Type: 'UI.DataField',
            Value: costCenter,
            Label: 'Centro de Custo'
        },
        {
            $Type: 'UI.DataField',
            Value: glAccount,
            Label: 'Conta Razão'
        }
    ],

    UI.Facets: [
        {
            $Type: 'UI.ReferenceFacet',
            ID: 'ItemGeneralFacet',
            Label: 'Detalhes do Item',
            Target: '@UI.FieldGroup#ItemDetails'
        },
        {
            $Type: 'UI.ReferenceFacet',
            ID: 'ItemAccountingFacet',
            Label: 'Atribuição Contábil / Logística',
            Target: '@UI.FieldGroup#ItemAccounting'
        }
    ],

    UI.FieldGroup #ItemDetails: {
        Data: [
            {
                $Type: 'UI.DataField',
                Value: materialId,
                Label: 'ID do Material'
            },
            {
                $Type: 'UI.DataField',
                Value: quantity,
                Label: 'Quantidade'
            },
            {
                $Type: 'UI.DataField',
                Value: uom,
                Label: 'Unidade de Medida'
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
    },

    UI.FieldGroup #ItemAccounting: {
        Data: [
            {
                $Type: 'UI.DataField',
                Value: plant,
                Label: 'Centro (Plant)'
            },
            {
                $Type: 'UI.DataField',
                Value: accountAssignmentCategory,
                Label: 'Categoria de Atribuição Contábil'
            },
            {
                $Type: 'UI.DataField',
                Value: costCenter,
                Label: 'Centro de Custo'
            },
            {
                $Type: 'UI.DataField',
                Value: glAccount,
                Label: 'Conta Razão (G/L Account)'
            }
        ]
    }
);

annotate ContractService.ContractItems with @(
    Common.SideEffects #ItemValueChange: {
        SourceProperties: [
            'quantity',
            'unitPrice'
        ],
        TargetProperties: [
            'itemValue',
            'contract/totalValue'
        ],
        TargetEntities: [
            contract
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