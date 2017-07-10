use Test::Most;

throws_ok( sub { say $^V }, qr/Can't locate object method "say"/, 'say' );

done_testing;
