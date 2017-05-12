
use strict;
use warnings;

use Test::More;
BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn needed" if $@;
}
plan tests => 1;

use re::engine::Lua;

TODO: {
local $TODO = "warn from XS";

warning_is { 'aaa' =~ /a/i }
   "flags not supported by re::engine::Lua"
}
