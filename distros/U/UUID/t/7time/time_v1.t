#
# test the time() function.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID 'generate_v1';

ok 1, 'loaded';

my $sys_time = time;
generate_v1(my $b0);
my $uid_time = UUID::time($b0);

UUID::unparse($b0, my $s0);
note 'new uuid ', $s0;

note 'sys time ', scalar localtime($sys_time);
note 'uid time ', scalar localtime($uid_time);

note 'sys time ', $sys_time;
note 'uid time ', $uid_time;

# sys time may be larger than actual due to rounding.
cmp_ok $sys_time, '<=' , $uid_time+1,   'compare ok';

cmp_ok $sys_time - $uid_time, '<=', 2,  'interval ok';

# relaxing, this one seems to be a problem on the smokers.
cmp_ok $uid_time - $sys_time, '<=', 20, 'rollover ok';

done_testing;
