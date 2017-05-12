BEGIN { %ENV = () }

use strict;
use Test::More tests => 6;
use re::engine::PCRE;

ok("Hello, world" !~ /(?<=Moose|Mo), (world)/);
is($1, undef);
ok("Hello, world" =~ /(?<=Hello|Hi), (world)/);
is($1, 'world');

no re::engine::PCRE;
is(eval '"Hello, world" =~ /(?<=Moose|Mo), (world)/', undef);

if (fork) {
    ok(1);
} 

