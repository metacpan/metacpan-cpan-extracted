var main_url = 'http://zonemaster.rd.nic.fr:5080/';

casper.test.begin('Zonemaster test GR27 - Verify the existence of Afnic and IIS logo', 3, function suite(test) {

	casper.start();

	casper.thenOpen(main_url, function(response) {
		test.assert(response != undefined && response.status == 200 , 'Page loaded');
	});

	// Existence of Afnic Logo
	casper.then(function() {
		this.test.assertResourceExists('/images/Afnic-logo.png', 'Afnic Logo exists');
	});

	// Existence of IIS Logo
        casper.then(function() {
                this.test.assertResourceExists('/images/IIS-logo.png', 'IIS Logo exists');
        });

	casper.run(function() {
		test.done();
	});
	
});
