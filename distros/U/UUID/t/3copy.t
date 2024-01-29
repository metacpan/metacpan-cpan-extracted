use strict;
use warnings;
use Test::More;
use UUID ();


my ($bin1, $bin2, $str1, $str2);

UUID::generate_time($bin1);
ok 1, 'generate1';

UUID::generate_time($bin2);
ok 1, 'generate2';

isnt $bin1, $bin2, 'different';

UUID::copy($bin2, $bin1);
ok 1, 'copy';

is UUID::compare($bin1, $bin2), 0, 'compare';

is $bin2, $bin1, 'same';

# copying bogus uuid should give null
$bin1 = 'xxx';
$bin2 = 'yyy';
UUID::copy($bin2,$bin1);
ok 1, 'copy bogus';
UUID::unparse($bin1,$str1);
UUID::unparse($bin2,$str2);
note 'uuid 1 : ', $str1;
note 'uuid 2 : ', $str2;
ok UUID::is_null($bin2), 'bogus null';
is $bin1, 'xxx', 'unchanged';

# make sure we get back the same scalar we passed in
my ($save1, $save2);
$bin1 = '1234567890123456';
UUID::generate( $bin2 );
$save1 = \$bin2;
UUID::copy( $bin2, $bin1 );
$save2 = \$bin2;
is $save1, $save2, 'same ref';
is $$save1, $$save2, 'same val';

done_testing;
