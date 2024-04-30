use strict;
use warnings;
use Test::More;
use MyNote;
use UUID;

ok 1, 'loaded';

is UUID::_defer(), 0, 'defer init';

ok UUID::_defer(0.123), 'defer set';

my $rv = sprintf '%.3f', UUID::_defer();
is $rv, 0.123, 'defer ok';

done_testing;
