use Test2::V0;
use exact ':5.10';

ok( lives { say $^V }, 'say' ) or note $@;
ok( lives { state $x }, 'state' ) or note $@;

done_testing;
