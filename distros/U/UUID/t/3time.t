use strict;
use warnings;
use Test::More;
use UUID ();

my ($bin, $t, $str);

UUID::generate_time($bin);
ok 1, 'gen1';
$t = UUID::time($bin);
ok 1, 'time1';
isnt $t, 0, 'time1';
UUID::unparse($bin, $str);
ok 1, 'unparse1';
note 'UUID      : ', $str;
note 'UUID time : ', $t;
note 'sys time  : ', scalar(time);

UUID::generate_random($bin);
ok 1, 'gen2';
$t = UUID::time($bin);
ok 1, 'time2';
isnt $t, 0, 'time2';
UUID::unparse($bin, $str);
ok 1, 'unparse2';
note 'UUID      : ', $str;
note 'UUID time : ', $t;

UUID::clear($bin);
ok 1, 'gen3';
$t = UUID::time($bin);
ok 1, 'time3';
isnt $t, 0, 'time3';
UUID::unparse($bin, $str);
ok 1, 'unparse3';
note 'UUID      : ', $str;
note 'UUID time : ', $t;

done_testing;
