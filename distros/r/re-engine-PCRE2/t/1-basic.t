BEGIN { %ENV = () }

use strict;
use Test::More tests => 6;
use re::engine::PCRE2;

# implemented in perl5 since 5.29.9 [perl #132367]
# before pcre extension only: perl: Variable length lookbehind not implemented
ok("Hello, world" !~ /(?<=Moose|Mo), (world)/);
ok(!$1); # v5.29.9 returns '', before undef

ok("Hello, world" =~ /(?<=Hello|Hi), (world)/);
is($1, 'world');

no re::engine::PCRE2;
ok(!eval '"Hello, world" =~ /(?<=Moose|Mo), (world)/'); # undef or ''

if (fork) {
    ok(1);
}

