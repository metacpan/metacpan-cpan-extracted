use Test2::V0;
use exact qw( nobundle switch state );

eval 'say $^V';
ok( length($@) > 0, 'say include skipped' );

ok( lives { state $x }, 'state included ok' ) or note $@;

done_testing;
