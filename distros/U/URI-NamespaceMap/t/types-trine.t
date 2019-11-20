#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Requires { 'RDF::Trine' => '0' };
use Types::Namespace qw( to_NamespaceMap to_Namespace to_Uri to_Iri );
use lib 't/lib';

use CommonTest qw(test_to_ns);


use RDF::Trine qw(iri);
use_ok('RDF::Trine::NamespaceMap');


test_to_ns(RDF::Trine::Namespace->new('http://www.example.net/'));
test_to_ns(RDF::Trine::iri('http://www.example.net/'));


my $data = { foo => 'http://example.org/foo#',
				 bar => 'http://example.com/bar/' };
my $map = RDF::Trine::NamespaceMap->new( $data );
my $urimap = to_NamespaceMap($map);
isa_ok($urimap, 'URI::NamespaceMap');
my $result;
while (my ($prefix, $uri) = $urimap->each_map) {
  isa_ok($uri, 'URI::Namespace');
  $result->{$prefix} = $uri->as_string;
}
is(scalar keys(%{$result}), 2, 'Two elements in the result hash');
cmp_deeply($result, $data, 'Roundtrips OK');

done_testing;
