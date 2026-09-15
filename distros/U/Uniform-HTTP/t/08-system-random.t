use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Auth;
use Uniform::HTTP::Auth::Digest;

my $auth = Uniform::HTTP::Auth->new;
my $challenge = $auth->parse_challenges(
    'Digest realm="Members", nonce="system-random", algorithm=SHA-256, qop="auth"'
)->[0];

my $digest = Uniform::HTTP::Auth::Digest->new;
my $value = $digest->authorization(
    challenge      => $challenge,
    username       => 'user',
    password       => 'secret',
    method         => 'GET',
    request_target => '/',
);

like $value, qr/\bcnonce="[0-9a-f]{48}"/, 'cnonce comes from 24 bytes of system randomness';
like $value, qr/\bnc=00000001\b/, 'system-random path produces normal Digest state';

done_testing;
