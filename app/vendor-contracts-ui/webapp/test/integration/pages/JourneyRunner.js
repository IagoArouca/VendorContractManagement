sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"sapanalytics/vendorcontracts/vendorcontractsui/test/integration/pages/ContractsList",
	"sapanalytics/vendorcontracts/vendorcontractsui/test/integration/pages/ContractsObjectPage",
	"sapanalytics/vendorcontracts/vendorcontractsui/test/integration/pages/ContractItemsObjectPage"
], function (JourneyRunner, ContractsList, ContractsObjectPage, ContractItemsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('sapanalytics/vendorcontracts/vendorcontractsui') + '/test/flp.html#app-preview',
        pages: {
			onTheContractsList: ContractsList,
			onTheContractsObjectPage: ContractsObjectPage,
			onTheContractItemsObjectPage: ContractItemsObjectPage
        },
        async: true
    });

    return runner;
});

