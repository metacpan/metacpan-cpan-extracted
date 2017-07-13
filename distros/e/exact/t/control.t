use Test::More tests => 1;
use Test::Exception;

throws_ok( sub { say $^V }, qr/Can't locate object method "say"/, 'say' );
