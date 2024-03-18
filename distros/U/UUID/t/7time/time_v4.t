#
# test the time() function.
#
# this really tests the statement that times returned
# from other than v1, v6, and v7 are always 0.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID 'generate_v4';

ok 1, 'loaded';

my $sys_time = time;

generate_v4(my $u0);

my $uid_time = UUID::time($u0);
note scalar localtime($uid_time);

note 'uid time ', $uid_time;
note 'sys time ', $sys_time;

is $uid_time, 0, 'always 0';

done_testing;
