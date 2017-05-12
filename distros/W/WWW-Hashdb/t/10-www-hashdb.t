use strict;
use warnings;

use Test::More;

plan tests => 3;

use_ok("WWW::Hashdb");

ok(my $hashdb = WWW::Hashdb->new(), "got instantce");
my @items = $hashdb->search("BURST CITY");
ok(@items > 1, 'number of items');
