const cds = require('@sap/cds');
const { SELECT, UPDATE } = require('@sap/cds/lib/ql/cds-ql');

class ContractService extends cds.ApplicationService {
    async init() {
        const { Contracts, ContractItems } = this.entities;

        this.before(['CREATE', 'UPDATE'], 'Contracts', async (req) => {
            const { validFrom, validTo } = req.data;

            if(validFrom && validTo && new Date(validTo) < new Date(validFrom)) {
                return req.error(400, 'CONTRACT_VALID_TO_BEFORE_FROM', 'A data de término do contrato não pode ser anterior a data de início. ');
            }
        });

        this.before(['CREATE', 'UPDATE'], 'ContractItems', async (req)=> {
            const { quantity, unitPrice } = req.data;
            if(quantity !== undefined && unitPrice !== undefined) {
                req.data.itemValue = quantity * unitPrice;
            }
        });

        this.after(['CREATE', 'UPDATE', 'DELETE'], 'ContractItems', async (item, req) => {
            const contractId = item.contract_ID || req.data.contract_ID;
            if(!contractId) return;

            const result = await cds.tx(req).run(
                SELECT.one(['sum(itemValue) as total']).from(ContractItems).where({ contract_ID: contractId })
            );

            const totalSum = result?.total || 0;

            await cds.tx(req).run(
                UPDATE(Contracts).set({ totalValue: totalSum }).where({ ID: contractId})
            );
        });

        this.on('approveContract', async (req) => {
            const { contractId } = req.data;

            const contract = await cds.tx(req).run(
                SELECT.one.from(Contracts).where({ ID: contractId })
            );

            if(!contract) {
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