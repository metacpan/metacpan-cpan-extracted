use strict;

use Test::More 'no_plan';

use re::engine::TRE;

if ("str" =~ /(s)(t)(r)/x) {
    cmp_ok $1, 'eq', 's' => '$1 is s';
    cmp_ok $2, 'eq', 't' => '$2 is t';
    cmp_ok $3, 'eq', 'r' => '$3 is r';
}

my @chr = ('A' ..'Z', 'a' .. 'z', 0 .. 9);
my $str = join '', @chr;
my $re = join '', map { "($_)" } @chr;

no strict 'refs';
if ($str =~ /$re/x) {
    for (my $i = 1; $i <= @chr; $i++) {
        cmp_ok $$i, 'eq', $chr[$i-1];
    }
}
