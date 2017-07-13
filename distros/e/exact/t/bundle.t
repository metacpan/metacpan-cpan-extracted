use Test::More tests => 3;
use Test::Exception;

use exact ':5.10';

lives_ok( sub { say $^V }, 'say' );

lives_ok( sub {
    my $var = 'string';
    given ($var) {
        when (/^abc/) { $var = 1 }
        when (/^def/) { $var = 2 }
        when (/^xyz/) { $var = 3 }
        default       { $var = 4 }
    }
}, 'switch' );

lives_ok( sub { state $x }, 'state' );
