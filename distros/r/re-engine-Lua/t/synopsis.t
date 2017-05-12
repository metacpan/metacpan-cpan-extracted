use strict;
use Test::More tests => 3;
use re::engine::Lua;

if ("bewb" =~ /(.)(.)/) {
    is($1, "b");
    is($2, "e");
    is($', "wb");
}
