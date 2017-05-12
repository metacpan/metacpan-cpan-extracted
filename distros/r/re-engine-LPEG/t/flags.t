
use strict;
use warnings;

use Test::More tests => 1;
use Test::Warn;
use re::engine::LPEG;

TODO: {
local $TODO = "warn from XS";

warning_is { 'aaa' =~ m{'a'}i }
   "flags not supported by re::engine::LPEG";
}
