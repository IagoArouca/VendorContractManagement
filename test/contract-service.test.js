const cds = require('@sap/cds');
const request = require('supertest');

describe('Contract Service - Testes de Lógica e Validação (End-to-End)', () => {
    const testEnv = cds.test(__dirname + '/..');
    let app;

    beforeAll(async () => {
        await testEnv;
        app = request(cds.app);
    });

    afterAll(async () => {
        if (cds.db) await cds.db.disconnect();
        await cds.shutdown();
    });

    const authHeader = 'Basic ' + Buffer.from('manager:manager').toString('base64');

    it('1. Deve rejeitar a criação de um contrato onde a data final é anterior à data inicial', async () => {
        const payloadInvalido = {
            title: 'Contrato com Datas Inválidas',
            validFrom: '2026-08-01',
            validTo: '2026-07-01',
            vendorId: '1000001'
        };

        const response = await app
            .post('/browse/Contracts')
            .set('Authorization', authHeader)
            .send(payloadInvalido);

        expect(response.status).toBe(400);
        expect(response.body.error).toBeDefined();
    });

    it('2. Deve criar contrato com itens (Deep Insert) e calcular valor do item e total do contrato', async () => {
        const payloadComItens = {
            title: 'Contrato com Deep Insert de Itens',
            validFrom: '2026-01-01',
            validTo: '2026-12-31',
            vendorId: '1000001',
            items: [
                {
                    materialId: 'MAT-100',
                    quantity: 10,
                    unitPrice: 15.50
                },
                {
                    materialId: 'MAT-200',
                    quantity: 2,
                    unitPrice: 50.00
                }
            ]
        };

        const createResponse = await app
            .post('/browse/Contracts')
            .set('Authorization', authHeader)
            .send(payloadComItens);

        expect(createResponse.status).toBe(201);
        const contractId = createResponse.body.ID;

        const getResponse = await app
            .get(`/browse/Contracts(ID=${contractId},IsActiveEntity=false)?$expand=items`)
            .set('Authorization', authHeader);

        expect(getResponse.status).toBe(200);
        expect(Number(getResponse.body.totalValue)).toBe(255.00);
        expect(getResponse.body.items).toHaveLength(2);
    });

    it('3. Deve ativar o Draft corretamente', async () => {
        const create = await app
            .post('/browse/Contracts')
            .set('Authorization', authHeader)
            .send({
                title: 'Contrato para Ativação',
                validFrom: '2026-01-01',
                validTo: '2026-12-31',
                vendorId: '1000001',
                items: [
                    {
                        materialId: 'MAT-100',
                        quantity: 5,
                        unitPrice: 20
                    }
                ]
            });

        expect(create.status).toBe(201);
        const id = create.body.ID;

        const activate = await app
            .post(`/browse/Contracts(ID=${id},IsActiveEntity=false)/ContractService.draftActivate`)
            .set('Authorization', authHeader)
            .send({});

        expect([200, 201, 204]).toContain(activate.status);
    });
});