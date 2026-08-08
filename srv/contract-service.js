const cds = require('@sap/cds');
const { SELECT, UPDATE, INSERT } = cds.ql;

class ContractService extends cds.ApplicationService {
    async init() {
        const { Contracts, ContractItems, BusinessPartners } = this.entities;

        this.BPsrv = await cds.connect.to('API_BUSINESS_PARTNER');
        this.s4ContractApi = await cds.connect.to('API_PURCHASECONTRACT_PROCESS_SRV_0002');


        this.on('approveContract', this._handleApproveContract.bind(this));
        this.on('rejectContract', this._handleRejectContract.bind(this));


        this.before(['UPDATE', 'DELETE'], ['Contracts', 'Contracts.drafts'], this._checkContractIsEditable.bind(this));
        this.before(['CREATE', 'UPDATE', 'NEW', 'SAVE'], 'Contracts.drafts', this._validateContract.bind(this));
        this.before(['CREATE', 'UPDATE'], 'Contracts', this._validateContract.bind(this));
        
        this.before('SAVE', 'Contracts', (req) => {
            req.data.status = 'P';
        });

        this.before(['CREATE', 'UPDATE'], 'ContractItems.drafts', this._calculateItemValue.bind(this));
        
        this.after(['CREATE', 'UPDATE', 'DELETE'], 'ContractItems.drafts', async (data, req) => {
            await this._recalculateContractTotalFromItem(data, req);
        });

        this.on('READ', BusinessPartners, (req) => this.BPsrv.run(req.query));
        this.on('READ', ['Contracts', 'Contracts.drafts'], this._enrichContractsWithVendorAndCriticality.bind(this));

        return super.init();
    }


    async _handleApproveContract(req) {
        const { Contracts } = this.entities;
        const ID = this._extractEntityId(req);

        if (!ID) {
            return req.error(400, 'MISSING_KEY', 'Identificador do contrato não fornecido.');
        }

        const contract = await SELECT.one.from(Contracts, ID).columns(c => {
            c('*');
            c.items(i => { i('*'); });
        });

        if (!contract) {
            return req.error(404, 'CONTRACT_NOT_FOUND', 'Contrato não encontrado para aprovação.');
        }

        if (contract.status === 'A') {
            return req.error(400, 'CONTRACT_ALREADY_APPROVED', 'Este contrato já está aprovado.');
        }

        try {
            const realSupplierCode = await this._getSupplierIdFromBP(contract.vendorId || '35');
            const formattedSupplier = String(realSupplierCode).padStart(10, '0');

            const s4Payload = this._buildS4ContractPayload(contract, formattedSupplier);

            const { A_PurchaseContract } = this.s4ContractApi.entities;
            const response = await this.s4ContractApi.tx(req).run(
                INSERT.into(A_PurchaseContract).entries(s4Payload)
            );

            const generatedContractNumber = response?.PurchaseContract ?? response?.d?.PurchaseContract;

            if (!generatedContractNumber) {
                throw new Error('O S/4HANA não retornou o número do contrato criado.');
            }

            await cds.tx(req).run(
                UPDATE(Contracts, ID).with({
                    status: 'A',
                    contractNumber: generatedContractNumber
                })
            );

            req.notify(`Contrato aprovado com sucesso! Criado no S/4HANA sob o número ${generatedContractNumber}.`);

            return await SELECT.one.from(Contracts, ID).columns(c => {
                c('*');
                c.items(i => { i('*'); });
            });

        } catch (error) {
            this._logS4Error(error);
            const rawResponse = error.reason?.response || error.response;
            const mainMessage = rawResponse?.data?.error?.message?.value || error.message;

            return req.error(500, 'S4_INTEGRATION_ERROR', `Falha ao integrar com o S/4HANA: ${mainMessage}`);
        }
    }

    async _handleRejectContract(req) {
        const { Contracts } = this.entities;
        const ID = this._extractEntityId(req);

        if (!ID) {
            return req.error(400, 'MISSING_KEY', 'Identificador do contrato não fornecido.');
        }

        const contract = await SELECT.one.from(Contracts).where({ ID });

        if (!contract) {
            return req.error(404, 'CONTRACT_NOT_FOUND', 'Contrato não encontrado para reprovação.');
        }

        if (contract.status === 'R') {
            return req.error(400, 'ALREADY_REJECTED', 'Este contrato já está reprovado.');
        }

        await cds.tx(req).run(
            UPDATE(Contracts).set({ status: 'R' }).where({ ID })
        );

        req.notify('Contrato reprovado com sucesso.');

        return await SELECT.one.from(Contracts).where({ ID });
    }

    _extractEntityId(req) {
        const param = req.params?.[0];
        if (typeof param === 'object' && param !== null) {
            return param.ID;
        }
        return param || req.data?.ID;
    }

    async _checkContractIsEditable(req) {
        const ID = this._extractEntityId(req);
        if (!ID) return;

        const { Contracts } = this.entities;
        const target = req.target.name.endsWith('.drafts') ? Contracts.drafts : Contracts;

        const contract = await SELECT.one.from(target).where({ ID });

        if (contract && (contract.status === 'A' || contract.status === 'R')) {
            const actionLabel = req.event === 'DELETE' ? 'excluído' : 'alterado';
            return req.error(403, 'CONTRACT_LOCKED', `Este contrato já está ${contract.status === 'A' ? 'Aprovado' : 'Reprovado'} e não pode ser ${actionLabel}.`);
        }
    }

    async _validateContract(req) {
        const { validFrom, validTo, vendorId, items } = req.data;

        if (validFrom && validTo && new Date(validTo) < new Date(validFrom)) {
            return req.error(400, 'CONTRACT_VALID_TO_BEFORE_FROM', 'A data de término do contrato não pode ser anterior à data de início.');
        }

        if (vendorId) {
            try {
                const realSupplierId = await this._getSupplierIdFromBP(vendorId);
                if (!realSupplierId) {
                    return req.error(404, 'VENDOR_NOT_FOUND_IN_S4', `O Parceiro de Negócios ${vendorId} não possui um cadastro de Fornecedor estendido no S/4HANA.`);
                }
            } catch (error) {
                console.error('[validateContract] Aviso na verificação do S/4HANA:', error.message);
            }
        }

        if (Array.isArray(items)) {
            let totalAccumulated = 0;
            items.forEach(item => {
                if (item.quantity !== undefined && item.unitPrice !== undefined) {
                    item.itemValue = item.quantity * item.unitPrice;
                    totalAccumulated += item.itemValue;
                }
            });
            req.data.totalValue = totalAccumulated;
        }
    }

    async _calculateItemValue(req) {
        const { ContractItems } = this.entities;
        const { ID, quantity, unitPrice } = req.data;

        let currentQuantity = quantity;
        let currentUnitPrice = unitPrice;

        if (ID && (currentQuantity === undefined || currentUnitPrice === undefined)) {
            const existingItem = await SELECT.one.from(ContractItems.drafts).where({ ID });
            if (existingItem) {
                if (currentQuantity === undefined) currentQuantity = existingItem.quantity;
                if (currentUnitPrice === undefined) currentUnitPrice = existingItem.unitPrice;
            }
        }

        const q = Number(currentQuantity || 0);
        const p = Number(currentUnitPrice || 0);
        req.data.itemValue = q * p;
    }

    async _recalculateContractTotalFromItem(data, req) {
        const { ContractItems, Contracts } = this.entities;
        let contractId = data.up__ID || req.data?.up__ID;

        if (!contractId && data.ID) {
            const item = await SELECT.one('up__ID').from(ContractItems.drafts).where({ ID: data.ID });
            contractId = item?.up__ID;
        }

        if (!contractId) return;

        const items = await SELECT.from(ContractItems.drafts).where({ up__ID: contractId });

        let totalAccumulated = 0;
        items.forEach(item => {
            if (item.quantity !== undefined && item.unitPrice !== undefined) {
                totalAccumulated += (item.quantity * item.unitPrice);
            }
        });

        await cds.tx(req).run(
            UPDATE(Contracts.drafts)
                .set({ totalValue: totalAccumulated })
                .where({ ID: contractId })
        );
    }

    async _enrichContractsWithVendorAndCriticality(req, next) {
        const contracts = await next();
        if (!contracts) return contracts;

        const contractsArray = Array.isArray(contracts) ? contracts : [contracts];

        contractsArray.forEach(contract => {
            switch (contract.status) {
                case 'A': contract.statusCriticality = 3; break;
                case 'R': contract.statusCriticality = 1; break;
                case 'P': contract.statusCriticality = 2; break;
                default:  contract.statusCriticality = 0; break;
            }
        });

        const rawVendorIds = [...new Set(contractsArray.map(c => c.vendorId).filter(Boolean))];
        if (rawVendorIds.length === 0) return contracts;

        const formattedVendorIds = rawVendorIds.map(id => String(id).padStart(10, '0'));

        try {
            const vendors = await this.BPsrv.run(
                SELECT.from('API_BUSINESS_PARTNER.A_BusinessPartner')
                    .columns('BusinessPartner', 'BusinessPartnerFullName')
                    .where({ BusinessPartner: { in: formattedVendorIds } })
            );

            const vendorMap = new Map();
            vendors.forEach(v => {
                const fullName = v.BusinessPartnerFullName || '';
                const paddedId = v.BusinessPartner;
                const cleanId = String(parseInt(v.BusinessPartner, 10));

                vendorMap.set(paddedId, fullName);
                vendorMap.set(cleanId, fullName);
            });

            contractsArray.forEach(contract => {
                if (contract.vendorId) {
                    const name = vendorMap.get(contract.vendorId) || vendorMap.get(String(contract.vendorId).padStart(10, '0'));
                    contract.vendorName = name || '';
                }
            });
        } catch (err) {
            console.error('[enrichContracts] Erro ao buscar Business Partners:', err.message);
        }

        return contracts;
    }

    async _getSupplierIdFromBP(bpId) {
        if (!bpId) return null;
        const formattedBP = String(bpId).padStart(10, '0');

        try {
            const bpSupplierLink = await this.BPsrv.run(
                SELECT.one('A_BusinessPartnerToSupplier')
                    .from('API_BUSINESS_PARTNER.A_BusinessPartnerToSupplier')
                    .columns('Supplier')
                    .where({ BusinessPartner: formattedBP })
            );

            if (bpSupplierLink?.Supplier) {
                return bpSupplierLink.Supplier;
            }
        } catch (error) {
            console.warn(`[_getSupplierIdFromBP] Aviso ao buscar Supplier do BP ${bpId}:`, error.message);
        }

        return formattedBP;
    }

    _buildS4ContractPayload(contract, formattedSupplier) {
        const formatDateForS4 = (dateVal, defaultOffsetDays = 0) => {
            let d = dateVal ? new Date(dateVal) : new Date();
            if (isNaN(d.getTime())) d = new Date();
            if (defaultOffsetDays > 0) d.setDate(d.getDate() + defaultOffsetDays);
            return d.toISOString().split('T')[0];
        };

        return {
            PurchaseContractType: contract.type || 'MK',
            CompanyCode: contract.companyCode || s4Config.companyCode,
            PurchasingGroup: contract.purchasingGroup || s4Config.purchasingGroup,
            PurchasingOrganization: contract.purchasingOrg || s4Config.purchasingOrg,
            Supplier: formattedSupplier,
            ValidityStartDate: formatDateForS4(contract.validFrom, 0),
            ValidityEndDate: formatDateForS4(contract.validTo, 365),
            DocumentCurrency: contract.currency || s4Config.currency,
            to_PurchaseContractItem: (contract.items || []).map((item, index) => {
                const quantity = Math.max(1, Math.floor(Number(item.quantity || 1)));
                const price = Number(item.unitPrice || 50);

                if (!quantity || quantity <= 0) {
                    throw new Error(`A quantidade do item ${index + 1} é inválida.`);
                }
                if (price === undefined || price === null || isNaN(price)) {
                    throw new Error(`O preço unitário do item ${index + 1} é obrigatório.`);
                }

                return {
                    PurchaseContractItem: String((index + 1) * 10),
                    Material: String(item.materialId),
                    Plant: item.plant || s4Config.plant,
                    TargetQuantity: String(quantity),
                    OrderQuantityUnit: item.uom || 'PC',
                    ContractNetPriceAmount: price.toFixed(2),
                    NetPriceQuantity: '1',
                    OrderPriceUnitToOrderUnitNmrtr: '1',
                    OrdPriceUnitToOrderUnitDnmntr: '1',
                    AccountAssignmentCategory: item.accountAssignmentCategory || 'K',
                    DocumentCurrency: contract.currency || s4Config.currency,
                    to_PurCtrAccount: {
                        results: [
                            {
                                AccountAssignment: "01",
                                Quantity: String(quantity),
                                OrderQuantityUnit: item.uom || "PC",
                                DocumentCurrency: contract.currency || s4Config.currency,
                                GLAccount: item.glAccount || s4Config.glAccount,
                                CostCenter: item.costCenter || s4Config.costCenter
                            }
                        ]
                    }
                };
            })
        };
    }

    _logS4Error(error) {
        console.error('=================== ERRO DETALHADO DO S/4HANA ===================');
        const rawResponse = error.reason?.response || error.response;
        const sapErrorData = rawResponse?.data;

        if (sapErrorData) {
            console.error('Status HTTP:', rawResponse.status);
            console.dir(sapErrorData, { depth: null, colors: true });
        } else {
            console.dir(error, { depth: null, colors: true });
        }
        console.error('================================================================');
    }
}

module.exports = ContractService;