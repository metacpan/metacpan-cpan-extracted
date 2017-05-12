use Test::Pod::Coverage tests => 1;

pod_coverage_ok( "XML::Generator::XMPP", {
		coverage_class => 'Pod::Coverage::CountParents',
	});
