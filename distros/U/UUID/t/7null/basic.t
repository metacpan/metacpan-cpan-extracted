use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# correct usage
    generate_v0(my $u0);
    ok is_null($u0), 'binary is null';
}
{# check not null uuid
    generate_v1(my $u0);
    ok !is_null($u0), 'binary not null';
}
{# check looks-like-binary-uuid string
    my $u0 = '123456789abcdef';
    ok !is_null($u0), 'certain string not null';
}
{# check random string
    my $u0 = '123456789';
    ok !is_null($u0), 'random string not null';
}
{# check number
    my $u0 = 123456789;
    ok !is_null($u0), 'number not null';
}
{# check undef
    my $u0 = undef;
    ok !is_null($u0), 'undef not null';
}

done_testing;
