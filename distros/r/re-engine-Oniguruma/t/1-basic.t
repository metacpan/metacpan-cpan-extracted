BEGIN { %ENV = () }

use strict;
use Test::More tests => 6;
use re::engine::Oniguruma;

# ok("Hello, world" !~ /(?<=Moose|Mo), (world)/);
ok("Hello, world" !~ /(?<=Moose), (world)/);
is($1, undef);
# ok("Hello, world" =~ /(?<=Hello|Hi), (world)/);
ok("Hello, world" =~ /(?<=Hello), (world)/);
is($1, 'world');

no re::engine::Oniguruma;
is(eval '"Hello, world" =~ /(?<=Moose|Mo), (world)/', undef);

if (fork) {
    ok(1);
} 

