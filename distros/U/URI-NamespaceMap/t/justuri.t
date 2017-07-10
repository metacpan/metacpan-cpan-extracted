use Test::More;

use strict;
use URI;

use_ok('URI::Namespace');

subtest 'Straightforward appends' => sub {
	my $foaf = URI::Namespace->new( 'http://xmlns.com/foaf/0.1/' );
	isa_ok( $foaf, 'URI::Namespace' );
	my $uri	= $foaf->as_string;
	is( $uri, 'http://xmlns.com/foaf/0.1/', 'expected resource object namespace from FOAF namespace map' );
	
	is($foaf->name->as_string, 'http://xmlns.com/foaf/0.1/name', 'expected resource object for FOAF namespace with name' );
	
	is($foaf->uri('Person')->as_string, 'http://xmlns.com/foaf/0.1/Person', 'expected resource object for FOAF namespace with Person when set with uri method' );
	
	is($foaf->uri('isa')->as_string, 'http://xmlns.com/foaf/0.1/isa', 'expected resource object for FOAF namespace with isa when set with uri method' );
};
 

subtest 'Missing hash on XSD' => sub {
	my $xsd = URI::Namespace->new( 'http://www.w3.org/2001/XMLSchema' );
	isa_ok( $xsd, 'URI::Namespace' );
	my $uri	= $xsd->as_string;
	is( $uri, 'http://www.w3.org/2001/XMLSchema', 'expected resource object for namespace from XSD namespace map' );
	
	is($xsd->integer->as_string, 'http://www.w3.org/2001/XMLSchema#integer', 'expected resource object for XSD namespace with integer' );
	
	is($xsd->uri('decimal')->as_string, 'http://www.w3.org/2001/XMLSchema#decimal', 'expected resource object for XSD namespace with decimal when set with uri method' );
};

subtest 'With hash on XSD' => sub {
	my $xsd = URI::Namespace->new( 'http://www.w3.org/2001/XMLSchema#' );
	isa_ok( $xsd, 'URI::Namespace' );
	my $uri	= $xsd->as_string;
	is( $uri, 'http://www.w3.org/2001/XMLSchema#', 'expected resource object for namespace from XSD namespace map with hash' );
	
	is($xsd->byte->as_string, 'http://www.w3.org/2001/XMLSchema#byte', 'expected resource object for XSD namespace with byte' );
	
	is($xsd->uri('long')->as_string, 'http://www.w3.org/2001/XMLSchema#long', 'expected resource object for XSD namespace with long when set with uri method' );
};

subtest 'Example without hash or slash' => sub {
	my $ex = URI::Namespace->new( 'http://www.example.org' );
	isa_ok( $ex, 'URI::Namespace' );
	my $uri	= $ex->as_string;
	is( $uri, 'http://www.example.org', 'expected resource object for namespace from EX namespace map without hash or slash' );
	
	is($ex->Order->as_string, 'http://www.example.orgOrder', 'expected resource object for EX namespace with Order' );
	
	is($ex->uri('Order')->as_string, 'http://www.example.orgOrder', 'expected resource object for EX namespace with Order when set with uri method' );
};



done_testing;
