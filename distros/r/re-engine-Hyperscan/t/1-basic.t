BEGIN { %ENV = () }

use strict;
use Test::More tests => 6;
use re::engine::Hyperscan;

ok("Hello, world" !~ /(?:Moose|Mo), (world)/);
is($1, undef);
ok("Hello, world" =~ /(?:Hello|Hi), (world)/);
is($1, 'world');

no re::engine::Hyperscan;
is(eval '"Hello, world" =~ /(?:Moose|Mo), (world)/', '');

if (fork) {
    ok(1);
}
