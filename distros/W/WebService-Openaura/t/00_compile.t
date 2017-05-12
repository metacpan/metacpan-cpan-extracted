use strict;
use Test::More 0.98;
use Data::Dumper;

use_ok $_ for qw(
    WebService::Openaura
);

my $openaura = new WebService::Openaura;

isa_ok $openaura, 'WebService::Openaura';
isa_ok $openaura->{http}, 'Furl::HTTP';

$openaura->api_key('YOUR_API_KEY');
is $openaura->api_key, 'YOUR_API_KEY';


done_testing;

