use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# correct usage
    generate_v1(my $u0);
    copy(my $u1, $u0);
    ok defined($u1),    'new uuid defined 0';
    is length($u1), 16, 'new length right 0';
    is $u1 cmp $u0, 0,  'new same as old 0';
}

{# copy a looks-like-binary-uuid string
    my $u0 = '0123456789abcdef';
    copy(my $u1, $u0);
    ok defined($u1),    'new uuid defined 1';
    is length($u1), 16, 'new length right 1';
    is $u1 cmp $u0, 0,  'new same as old 1';
}

{# copy an odd string
    my $u0 = 'f00bar';
    copy(my $u1, $u0);
    ok defined($u1),    'new uuid defined 2';
    is length($u1), 16, 'new length right 2';
    ok is_null($u1),    'new is null 2';
}

{# copy a number
    my $u0 = 8675309;
    copy(my $u1, $u0);
    ok defined($u1),    'new uuid defined 3';
    is length($u1), 16, 'new length right 3';
    ok is_null($u1),    'new is null 3';
}

{# copy undef
    my $u0 = undef;
    copy(my $u1, $u0);
    ok defined($u1),    'new uuid defined 4';
    is length($u1), 16, 'new length right 4';
    ok is_null($u1),    'new is null 4';
}

done_testing;
