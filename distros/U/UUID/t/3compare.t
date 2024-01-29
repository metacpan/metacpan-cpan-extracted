use strict;
use warnings;
use Test::More;
use UUID ();


UUID::generate_time(my $bin1);
ok 1, 'generate 1';
UUID::generate_time(my $bin2);
ok 1, 'generate 2';

my $tmp1 = UUID::compare($bin1,$bin2);
my $tmp2 = UUID::compare($bin2,$bin1);

ok $tmp1, 'forward different';
ok $tmp2, 'reverse different';

is $tmp1, -$tmp2, 'compare different';

$bin1 = $bin2;

is UUID::compare($bin1,$bin2), 0, 'compare same';

done_testing;
