use strict;
use warnings;
use Test::More;
use MyNote;
use UUID;

ok 1, 'loaded';

my $u0 = 'boofar';
UUID::clear($u0);
is length($u0), 16, 'binary length';

UUID::unparse($u0, my $s0);
is length($s0), 36, 'string length';
is $s0, '00000000-0000-0000-0000-000000000000', 'value';

done_testing;
