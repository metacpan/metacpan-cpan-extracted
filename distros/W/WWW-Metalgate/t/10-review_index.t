use strict;
use warnings;

use Test::More tests => 5;
use XXX;

use_ok("WWW::Metalgate::ReviewIndex");

my $index = WWW::Metalgate::ReviewIndex->new;
ok($index, 'got instance');
can_ok($index, "artists");
my @artists = $index->artists;
ok( @artists > 10, 'number of artists');
ok(1, "last test");
