#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

{
	package Local::Dummy;
	use Test::Requires 'Attean';
	use Test::Requires { 'Types::Namespace' => '1.10' };
	use Test::Requires { 'Types::Attean' => '0.024' };
	use Test::Requires { 'RDF::Trine' => '1.000' };
}

use Types::URI qw( to_Uri to_Iri );
use Types::Namespace qw( to_Namespace );
use Types::Attean qw(to_AtteanIRI);
use Attean::IRI;
use URI;

my $atteaniri = Attean::IRI->new('http://www.example.net/');

{
	my $uri = to_Uri($atteaniri);
	isa_ok($uri, 'URI');
	is("$uri", 'http://www.example.net/', "Correct string URI to Uri");
	
	my $iri = to_Iri($atteaniri);
	isa_ok($iri, 'IRI');
	is($iri->as_string, 'http://www.example.net/', "Correct string URI to Iri");
}

_test_to_attean(URI->new('http://www.example.net/'));

_test_to_attean(IRI->new('http://www.example.net/'));

_test_to_attean(URI::Namespace->new('http://www.example.net/'));

_test_to_attean('http://www.example.net/');

sub _test_to_attean {
	my $uri = shift;
	my $airi = to_AtteanIRI($uri);
	isa_ok($airi, 'Attean::IRI');
	is($airi->as_string, 'http://www.example.net/', 'Correct string URI from ' . ref($uri));
	ok($airi->equals($atteaniri), 'Is the same URI');
}

done_testing;
