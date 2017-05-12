use Test::Pod::Coverage tests => 1;

pod_coverage_ok( "XML::SAX::IncrementalBuilder::LibXML", {
		coverage_class => 'Pod::Coverage::CountParents',
		trustme => [qw(characters start_element end_element start_document xml_decl)]
	});
