use Test::Most;

use exact qw( nobundle switch state );

throws_ok( sub { say $^V }, qr/Can't locate object method "say"/, 'say' );

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

done_testing;
