use strict;

use Test::More tests => 1;

use re::engine::Plugin (
    comp => sub {
        my $re = shift;
        $re->minlen(length("str") + 1); # make "str" too short
    },
    exec => sub { fail "exec called" },
);

pass "making match";
"str" =~ /pattern/;
