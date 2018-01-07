use Test::More tests => 2;
use Test::Exception;

use exact;

lives_ok( sub { say $^V }, 'say' );
lives_ok( sub { state $x }, 'state' );
