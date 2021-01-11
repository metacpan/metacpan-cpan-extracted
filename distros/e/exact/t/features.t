use Test2::V0;
use exact qw( nobundle switch state );

like( dies { say $^V }, qr/Can't locate object method "say"/, 'say' );
ok( lives { state $x }, 'state' ) or note $@;

done_testing;
