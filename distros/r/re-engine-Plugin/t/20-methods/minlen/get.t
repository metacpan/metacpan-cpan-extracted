use strict;

use Test::More tests => 3;

use re::engine::Plugin (
    comp => sub {
        my $re = shift;
        $re->minlen(2);
    },
    exec => sub {
        my $re = shift;
        my $minlen = $re->minlen;
        cmp_ok $minlen, '==', 2, 'minlen accessor';
    },
);

pass "making match";
"s" =~ /pattern/;
"st" =~ /pattern/;
"str" =~ /pattern/;
