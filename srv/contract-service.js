const cds = require('@sap/cds');

class ContractService extends cds.ApplicationService {
    async init() {
        const { Contracts } = this.entities;

        const BPsrv = await cds.connect.to('API_BUSINESS_PARTNER');

        const validateContract = async(req) => {
            const { validFrom, validTo, vendorId, items } = req.data;

            if (validFrom && validTo && new Date(validTo) < new Date(validFrom)) {
                return req.error(400, 'CONTRACT_VALID_TO_BEFORE_FROM', 'A data de término do contrato não pode ser anterior a data de início. ');
            }

            if (vendorId) {
                try {
                    const vendorExists = await BPsrv.run(
                        SELECT.one('BusinessPartner')
                            .from('API_BUSINESS_PARTNER.A_BusinessPartner')
                            .where({ BusinessPartner: vendorId })
                    );

                    if (!vendorExists) {
                        return req.error(404, 'VENDOR_NOT_FOUND_IN_S4', `O fornecedor com ID ${vendorId} não existe no ERP S/4HANA.`);
                    }
                } catch (error) {
                    console.error('Aviso na verificação do S/4HANA:', error.message);
                }
            }

            if (items && Array.isArray(items)) {
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

        this.before(['CREATE', 'UPDATE', 'NEW', 'SAVE'], 'Contracts.drafts', validateContract);
        this.before(['CREATE', 'UPDATE'], 'Contracts', validateContract);
        this.on('READ', 'Contracts', async (req, next) => {
            const contracts = await next();
            if (!contracts) return contracts;

            const contractsArray = Array.isArray(contracts) ? contracts : [contracts];
            const vendorIds = contractsArray.map(c => c.vendorId).filter(Boolean);

            if (vendorIds.length === 0) return contracts;

            try {
                const vendors = await BPsrv.run(
                    SELECT.from('API_BUSINESS_PARTNER.A_BusinessPartner')
                        .columns('BusinessPartner', 'BusinessPartnerName', 'BusinessPartnerCategory')
                        .where({ BusinessPartner: { in: vendorIds } })
                );

                const vendorMap = new Map(vendors.map(v => [v.BusinessPartner, v]));

                contractsArray.forEach(contract => {
                    contract.vendor = vendorMap.get(contract.vendorId);
                });
            } catch (err) {
                console.error('Falha ao expandir Business Partner remotos:', err.message);
            }

            return contracts;
        });

        this.on('approveContract', async (req) => {
            const { contractId } = req.data;

            const contract = await cds.tx(req).run(
                SELECT.one.from(Contracts).where({ ID: contractId })
            );

            if (!contract) {
                return req.error(404, 'CONTRACT_NOT_FOUND', 'Contrato não encontrado para aprovação.');
            }

            await cds.tx(req).run(
                UPDATE(Contracts).set({ status: 'A' }).where({ ID: contractId })
            );

            return await cds.tx(req).run(
                SELECT.one.from(Contracts).where({ ID: contractId })
            );
        });

        

        return super.init();
    }
}

module.exports = ContractService;