# Vendor Contract Management System 📄💼
> **Extensão Side-by-Side em SAP BTP para SAP S/4HANA**

Uma aplicação de nível empresarial e nativa em nuvem desenvolvida no **SAP Business Technology Platform (SAP BTP)** para otimizar o ciclo de vida de contratos de fornecedores. Construída como uma **Extensão Side-by-Side** para o **SAP S/4HANA**, esta solução segue rigorosamente os princípios de **SAP Clean Core**, desacoplando lógicas de negócios customizadas do ERP principal e fornecendo integração bidirecional contínua via APIs OData.

---

## 🚀 Principais Funcionalidades

* **Ciclo de Vida Completo do Contrato:** Gestão de rascunhos (*Drafts*), fluxos de aprovação, validações customizadas e mecanismos de rejeição de contratos.
* **Integração Direta com SAP S/4HANA:**
  * Criação automatizada de **Contratos de Compra** oficiais (`API_PURCHASECONTRACT_PROCESS_SRV_0002`) via OData *Deep Insert* após a aprovação do contrato.
  * Integração com **Dados Mestres de Parceiros de Negócio** (`API_BUSINESS_PARTNER`) para resolução de IDs de fornecedores e busca de perfis estendidos.
  * Integração com **Materiais** e imputação de custos (ex: Centros de Custo e Contas do Razão).
* **Cálculos Financeiros Automatizados:** Cálculos em tempo real na camada de rascunhos (`ContractItems.drafts`) para os valores líquidos dos itens e valor total acumulado do contrato no cabeçalho.
* **Imutabilidade e Governança:** Máquina de estados que aplica regras de negócio para bloquear alterações ou exclusões não autorizadas em contratos aprovados ou rejeitados.
* **UX Empresarial:** Desenvolvido com **SAP Fiori Elements** (*List Report* & *Object Page*) com suporte a criticalidade visual de status, internacionalização (i18n) e manipulação de rascunhos.

---

## 🏛 Arquitetura e Blueprint da Solução

```text
+-----------------------------------------------------------------------------------+
|                                  SAP BTP (Cloud Foundry)                          |
|                                                                                   |
|  +---------------------------+       +-----------------------------------------+  |
|  |   SAP Build Work Zone     |       |       SAP Fiori Elements (UI)           |  |
|  |     (Fiori Launchpad)     | <---> |  HTML5 Application Repository (Host/RT) |  |
|  +---------------------------+       +-----------------------------------------+  |
|                                                           |                       |
|                                                      OData v4                     |
|                                                           v                       |
|                                      +-----------------------------------------+  |
|                                      |      SAP CAP Node.js Service Layer      |  |
|                                      | (Draft Engine, Logic & Authorization)   |  |
|                                      +-----------------------------------------+  |
|                                          |                           |            |
|                                          v                           v            |
|                              +-----------------------+   +---------------------+  |
|                              |    SAP HANA Cloud     |   |    XSUAA Service    |  |
|                              |   (HDI Shared Schema) |   |  (Auth & Roles)     |  |
|                              +-----------------------+   +---------------------+  |
+-------------------------------------------------------------------|---------------+
                                                                    | Serviços OData
                                                                    v
                                                     +------------------------------+
                                                     |        SAP S/4HANA           |
                                                     | (Purchase Contracts & BPs)   |
                                                     +------------------------------+

