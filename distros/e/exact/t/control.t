use Test2::V0;

like( dies { say $^V }, qr/Can't locate object method "say"/, 'say' );

done_testing;
