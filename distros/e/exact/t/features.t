use Test::More tests => 2;
use Test::Exception;

use exact qw( nobundle switch state );

throws_ok( sub { say $^V }, qr/Can't locate object method "say"/, 'say' );
lives_ok( sub { state $x }, 'state' );
