use Test::More;
use Test::Exception;


use strict;
use Module::Load::Conditional qw[check_install];

my $xmlns = check_install( module => 'XML::CommonNS');
my $rdfns = check_install( module => 'RDF::NS', version => 20130802);
my $rnscu = check_install( module => 'RDF::NS::Curated');
my $rdfpr = check_install( module => 'RDF::Prefixes');

unless (defined $xmlns || defined $rdfns || defined $rnscu || defined $rdfpr) {
	plan skip_all => 'None of the namespace modules XML::CommonNS, RDF::NS::Curated, RDF::NS or RDF::Prefixes are installed'
}

if (defined $rdfns) {
	require RDF::NS;
	unless (defined($RDF::NS::VERSION)) {
		diag('RDF::NS appears to be installed, but no version was found. Not using');
		$rdfns = undef;
	}
	elsif ($RDF::NS::VERSION < 20130802) {
		plan skip_all => 'RDF::NS is old, please upgrade. Skipping tests, other functionality is usually OK.';
	}
}

my $diag = "Status for optional modules: ";
$diag .= (defined $rnscu) ? " With " : " Without ";
$diag .= "RDF::NS::Curated,";
$diag .= (defined $xmlns) ? " with " : " without ";
$diag .= "XML::CommonNS,";
$diag .= (defined $rdfns) ? " with " : " without ";
$diag .= "RDF::NS,";
$diag .= (defined $rdfpr) ? " with " : " without ";
$diag .= "RDF::Prefixes.";
note($diag);

use_ok('URI::NamespaceMap') ;

SKIP: {
	skip "XML::CommonNS, RDF::NS::Curated or RDF::NS needed", 7 unless(defined $xmlns || defined $rdfns || defined $rnscu);
	my $map		= URI::NamespaceMap->new( [ 'foaf', 'rdf' ] );
	isa_ok( $map, 'URI::NamespaceMap' );
	ok($map->namespace_uri('foaf'), 'FOAF returns something');
	ok($map->namespace_uri('rdf'), 'RDF returns something');
	is($map->namespace_uri('foaf')->as_string, 'http://xmlns.com/foaf/0.1/', 'FOAF URI string OK');
	is($map->namespace_uri('rdf')->as_string, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', 'RDF URI string OK');
	$map->guess_and_add('dc');
	ok($map->namespace_uri('dc'), 'DC returns something');
	note('DC prefix differs between different modules');
	is($map->namespace_uri('dc')->as_string,
		(defined $rnscu) ? 'http://purl.org/dc/terms/' : 'http://purl.org/dc/elements/1.1/',
		'DC URI string OK');
}

SKIP: {
	skip "RDF::NS or RDF::NS::Curated needed", 5 unless (defined $rdfns || defined $rnscu);
	my $map		= URI::NamespaceMap->new( [ 'foaf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', 'xsd' ] );
	isa_ok( $map, 'URI::NamespaceMap' );
	is($map->namespace_uri('foaf')->as_string, 'http://xmlns.com/foaf/0.1/', 'FOAF URI string OK');
	is($map->namespace_uri('rdf')->as_string, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', 'RDF URI string OK');
	is_deeply([sort $map->list_prefixes], ['foaf', 'rdf', 'xsd' ], 'Prefix listing OK');

}

SKIP: {
	skip "RDF::NS or RDF::NS::Curated needed", 5 unless(defined $rdfns || defined $rnscu);
	my $map		= URI::NamespaceMap->new( [ 'foaf', 'rdfs' ] );
	isa_ok( $map, 'URI::NamespaceMap' );
	ok($map->namespace_uri('foaf'), 'FOAF returns something');
	is($map->namespace_uri('foaf')->as_string, 'http://xmlns.com/foaf/0.1/', 'FOAF URI string OK');
	ok($map->namespace_uri('rdfs'), 'RDFS returns something') || diag('RDF::NS is version ' . $RDF::NS::VERSION . ' and may need upgrading');
	is($map->namespace_uri('rdfs')->as_string, 'http://www.w3.org/2000/01/rdf-schema#', 'RDFS URI string OK');
}

SKIP: {
	skip "RDF::NS needed", 2 unless(defined $rdfns);
	my $map		= URI::NamespaceMap->new( [ 'acl' ] );
	isa_ok( $map, 'URI::NamespaceMap' );
	ok($map->namespace_uri('acl'), 'acl returns something') || diag('RDF::NS is version ' . $RDF::NS::VERSION . ' and may need upgrading');
}

SKIP: {
	skip "RDF::Prefixes and RDF::NS or RDF::NS::Curated needed", 5 unless((defined $rdfns || defined $rnscu) && defined $rdfpr);
	my $map		= URI::NamespaceMap->new( [ 'http://example.org/ns/sdfhkd4f#', 'http://www.w3.org/2000/01/rdf-schema#' ] );
	isa_ok( $map, 'URI::NamespaceMap' );
	ok($map->namespace_uri('sdfhkd4f'), 'Keyboard cat returns something');
	ok($map->namespace_uri('rdfs'), 'RDFS returns something');
	is($map->namespace_uri('sdfhkd4f')->as_string, 'http://example.org/ns/sdfhkd4f#', 'Keyboard cat URI string OK');
	is($map->namespace_uri('rdfs')->as_string, 'http://www.w3.org/2000/01/rdf-schema#', 'RDFS URI string OK');
}

SKIP: {
	skip "RDF::Prefixes", 11 unless(defined $rdfpr);
	my $map		= URI::NamespaceMap->new( [ 'http://www.w3.org/2000/01/rdf-schema#', 'http://usefulinc.com/ns/doap#' ] );
	isa_ok( $map, 'URI::NamespaceMap' );
	ok($map->namespace_uri('rdfs'), 'RDFS returns something');
	ok($map->namespace_uri('doap'), 'DOAP returns something');
	is($map->namespace_uri('rdfs')->as_string, 'http://www.w3.org/2000/01/rdf-schema#', 'RDFS URI string OK');
	is($map->namespace_uri('doap')->as_string, 'http://usefulinc.com/ns/doap#', 'DOAP URI string OK');
	$map->guess_and_add('http://www.w3.org/2002/07/owl#');
	ok($map->namespace_uri('owl'), 'owl returns something');
	is($map->namespace_uri('owl')->as_string, 'http://www.w3.org/2002/07/owl#', 'owl URI string OK');
	$map->guess_and_add('http://example.org/isa#');
	ok($map->namespace_uri('isax'), 'isax returns something');
	is($map->namespace_uri('isax')->as_string, 'http://example.org/isa#', 'isax URI string OK');
	my $map2		= URI::NamespaceMap->new( [ 'http://example.org/does#' ] );
	isa_ok( $map2, 'URI::NamespaceMap' );
	ok($map2->namespace_uri('doesx'), 'doesx returns something');
}


done_testing;
