BEGIN { %ENV = () }

use strict;
use Test::More tests => 6;
use re::engine::Lua;

ok("Hello, world" !~ /Moose, (world)/);
is($1, undef);
ok("Hello, world" =~ /Hello, (world)/);
is($1, 'world');

no re::engine::Lua;
ok(!eval '"Hello, world" =~ /(?=Moose|Mo), (world)/');

SKIP:
{
    skip('fork? on Windows', 1) if ($^O eq 'MSWin32');
if (fork) {
    ok(1);
}
}

