use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# correct usage
    my $u0 = '00000000-0000-0000-0000-000000000000';
    my $b0 = 'original';
    ok !parse($u0, $b0), 'parse ok';
    ok defined($b0),     'parse defined';
    is length($b0), 16,  'parse length';
    ok is_null($b0),     'binary null';
}
{# parse random
    my $u0 = 'random string';
    ok parse($u0, my $b0),  'parse random fail';
    ok !defined($b0),       'parse random undefined';
}
{# parse empty
    my $u0 = '';
    ok parse($u0, my $b0),  'parse empty fail';
    ok !defined($b0),       'parse empty undefined';
}
{# parse number
    my $u0 = 8675309;
    ok parse($u0, my $b0),  'parse number fail';
    ok !defined($b0),       'parse number undefined';
}
{# parse undef
    my $u0 = undef;
    ok parse($u0, my $b0),  'parse undef fail';
    ok !defined($b0),       'parse undef undefined';
}

done_testing;
