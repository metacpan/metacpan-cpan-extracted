use strict;
use warnings;

use Test::More tests => 2;

use WWW::ProximoBus;

my $proximo = WWW::ProximoBus->new;

my $agencies = $proximo->agencies;
is(ref $agencies, 'HASH', 'agencies call returns a hashref');

my $items = $agencies->{items};
ok(@$items > 0, 'it has some items');




