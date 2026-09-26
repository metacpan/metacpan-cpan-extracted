use strict;
use warnings;
use Test::More;

use Trog::TOTP;

# The constructor takes the secret, as its POD says, and does not replace it
# with a random one.  The codes are the RFC 6238 SHA1 vectors for that secret.
my $secret = '12345678901234567890';

my $totp = Trog::TOTP->new( secret => $secret, digits => 8 );
is( $totp->secret,       $secret,                            'new(secret => ...) keeps the secret it was given' );
is( $totp->base32secret, 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', 'and its base32 form follows it' );
is( $totp->expected_totp_code(59),         '94287082', 'so the code at 59 is the one RFC 6238 gives' );
is( $totp->expected_totp_code(1111111109), '07081804', 'and at 1111111109' );

my $both = Trog::TOTP->new( secret => 'not this one', base32secret => 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ' );
is( $both->secret, $secret, 'given both, base32secret wins, as it always has, so no caller that passes both sees a change' );

my $base32 = Trog::TOTP->new( base32secret => 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ' );
is( $base32->secret, $secret, 'new(base32secret => ...) still decodes to the secret' );

my $fresh = Trog::TOTP->new();
ok( length $fresh->secret >= 20, 'and with neither, a random secret of at least 20 bytes' );

done_testing();
