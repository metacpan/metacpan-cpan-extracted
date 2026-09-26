use strict;
use warnings;
use Test::More;

use Trog::TOTP;

# The base32 form of each RFC 6238 test secret, as this module has always
# written it: RFC 4648 upper case, without padding.  An enrolled user's
# authenticator holds these strings, so a change of encoder must not move them.
my @secrets = (
    [ '',       '12345678901234567890',                                             '94287082', 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ' ],
    [ 'SHA256', '12345678901234567890123456789012',                                 '46119246', 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZA' ],
    [ 'SHA512', '1234567890123456789012345678901234567890123456789012345678901234', '90693936', 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNA' ],
);

foreach my $case (@secrets) {
    my ( $algo, $secret, $otp, $base32 ) = @$case;
    my $name = sprintf '%d byte secret', length $secret;

    my $from_raw = Trog::TOTP->new();
    $from_raw->algorithm($algo) if $algo;
    ok( $from_raw->validate_otp( secret => $secret, when => 59, digits => 8, otp => $otp, tolerance => 1 ), "$name: the RFC code validates" );
    is( $from_raw->base32secret, $base32, "$name: and encodes as it always has" );

    my $from_base32 = Trog::TOTP->new( base32secret => $base32 );
    is( $from_base32->secret, $secret, "$name: which decodes back to the secret" );

    my $lower = Trog::TOTP->new( base32secret => lc $base32 );
    is( $lower->secret, $secret, "$name: in lower case too, as some authenticators show it" );
}

done_testing();
