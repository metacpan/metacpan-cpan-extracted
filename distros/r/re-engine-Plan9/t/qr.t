use strict;

use Test::More tests => 2;

use re::engine::Plan9;

my $re = qr/aoeu/;

isa_ok($re, "re::engine::Plan9");
is("$re", "aoeu");
