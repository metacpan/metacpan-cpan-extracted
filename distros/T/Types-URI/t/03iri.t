use strict;
use warnings;
use Test::More;
use Test::Requires { 'IRI' => '0.004' };
use Types::URI qw( to_Uri to_Iri );

my $uri = to_Uri("IRI"->new('http://www.example.net/'));
isa_ok($uri, 'URI');
is("$uri", 'http://www.example.net/');

my $iri = to_Iri($uri);
isa_ok($iri, 'IRI');
is($iri->as_string, 'http://www.example.net/');

done_testing;
