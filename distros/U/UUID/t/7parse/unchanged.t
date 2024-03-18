#
# make sure original binary content is unchanged on fail.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# parse random
    my $u0 = 'random string';
    my $b0 = 'original';
    ok parse($u0, $b0), 'parse random fail';
    ok defined($b0),    'parse random defined';
    is $b0, 'original', 'parse random original';
}
{# parse empty
    my $u0 = '';
    my $b0 = 'original';
    ok parse($u0, $b0), 'parse empty fail';
    ok defined($b0),    'parse empty defined';
    is $b0, 'original', 'parse empty original';
}
{# parse number
    my $u0 = 8675309;
    my $b0 = 'original';
    ok parse($u0, $b0), 'parse number fail';
    ok defined($b0),    'parse number defined';
    is $b0, 'original', 'parse number original';
}
{# parse undef
    my $u0 = undef;
    my $b0 = 'original';
    ok parse($u0, $b0), 'parse undef fail';
    ok defined($b0),    'parse undef defined';
    is $b0, 'original', 'parse undef original';
}

done_testing;
