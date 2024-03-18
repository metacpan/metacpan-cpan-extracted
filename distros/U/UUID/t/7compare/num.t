#
# compare number to number.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# number to number
    my $u0 = 431;
    my $u1 = 432;
    is compare($u0, $u1), -1, 'numnum 0';
    is compare($u1, $u0),  1, 'numnum 1';
}

{# number to undef
    my $u0 = 431;
    my $u1 = undef;
    is compare($u0, $u1),  1, 'numund 0';
    is compare($u1, $u0), -1, 'numund 1';
}

{# undef to undef
    my $u0 = undef;
    my $u1 = undef;
    is compare($u0, $u1),  0, 'undund 0';
}

done_testing;
