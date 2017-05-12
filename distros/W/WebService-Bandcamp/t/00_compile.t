use strict;
use Test::More 0.98;

use_ok $_ for qw(
    WebService::Bandcamp
);

my $bandcamp = new WebService::Bandcamp;
isa_ok $bandcamp, 'WebService::Bandcamp';
isa_ok $bandcamp->{http}, 'Furl::HTTP';


done_testing;

