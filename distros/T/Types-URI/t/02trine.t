use strict;
use warnings;
use Test::More;
use Test::Requires { 'RDF::Trine' => '1.000' };
use Types::URI qw( to_Uri );

my $uri = to_Uri(RDF::Trine::iri('http://www.example.net/'));
isa_ok($uri, 'URI');
is("$uri", 'http://www.example.net/');
done_testing;
