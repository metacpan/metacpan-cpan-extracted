use strict;
use warnings;
use Test::More;
use MyNote;
use UUID 'uuid6';

ok 1, 'loaded';

my $sys_time = time;

my $u0 = uuid6();
note $u0;

my @cluster = split /-/, $u0;
my $f0 = $cluster[0];
my $f1 = $cluster[1];
my $f2 = substr $cluster[2], 1;

my $val = join '', $f0, $f1, $f2;
note $val;

my $uid_time = 0;
while (length $val) {
    my $c = ord substr $val, 0, 1, '';
    $c -= 48;
    $c -=  7 if $c > 9;
    $c -= 32 if $c > 9;
    $uid_time = 16 * $uid_time + $c;
}

# uuid gregorian time since 14whenever.
# clock_reg += (((U64)0x01b21dd2) << 32) + 0x13814000;
# 122,192,928,000,000,000

$uid_time = $uid_time / 10000000 - 12219292800;

note 'uid time ', $uid_time;
note 'sys time ', $sys_time;

# sys time may be larger than actual due to rounding.
cmp_ok $sys_time, '<=' , $uid_time+1,   'compare ok';

cmp_ok $sys_time - $uid_time, '<=', 2,  'interval ok';

# relaxing, this one seems to be a problem on the smokers.
cmp_ok $uid_time - $sys_time, '<=', 20, 'rollover ok';

done_testing;
