use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Auth;
use Uniform::HTTP::Auth::Digest;

my $auth = Uniform::HTTP::Auth->new;
my $parsed = $auth->parse_challenges(
    'Digest realm="http-auth@example.org", qop="auth, auth-int", algorithm=SHA-256, nonce="7ypf/xlj9XXwfDPEoM4URrv/xwf94BcCAzFZH4GiTo0v", opaque="FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS"'
);

ok !$parsed->[0]{malformed}, 'RFC Digest challenge parses';

my $cnonce = 'f2/wE4q74E6zIJEtWaHKaf5wv/H5QzzpXusqGemxURZJ';
my $digest = Uniform::HTTP::Auth::Digest->new(
    _random_bytes => sub {
        return "\x01" x 24;
    },
);

my $state_key = Uniform::HTTP::Auth::Digest::_state_key(
    '',
    $parsed->[0]{params}{realm},
    'Mufasa',
    $parsed->[0]{params}{nonce},
);
$digest->{nonce_state}{$state_key} = {
    count  => 0,
    cnonce => $cnonce,
};

my $value = $digest->authorization(
    challenge      => $parsed->[0],
    username       => 'Mufasa',
    password       => 'Circle of Life',
    method         => 'GET',
    request_target => '/dir/index.html',
);

like $value, qr/\bresponse="753927fa0e85d155564e2e272a28d1802ca10daf4496794697cf8db5856cb6c1"/,
    'SHA-256 Digest response matches RFC 7616 example';
like $value, qr/\bnc=00000001\b/, 'first nonce count is one';
like $value, qr/\bqop=auth\b/, 'auth preferred when offered';

my $value2 = $digest->authorization(
    challenge      => $parsed->[0],
    username       => 'Mufasa',
    password       => 'Circle of Life',
    method         => 'GET',
    request_target => '/dir/index.html',
);
like $value2, qr/\bnc=00000002\b/, 'nonce count increments';

my $unsupported = $auth->parse_challenges(
    'Digest realm="x", nonce="n", algorithm=SHA3-256, qop="auth", Basic realm="x"'
);
my $selected = $auth->select($unsupported);
is $selected->{scheme}, 'basic', 'unsupported Digest algorithm falls back to another scheme';

my $utf8_challenge = $auth->parse_challenges(
    'Digest realm="api@example.org", qop="auth", algorithm=SHA-512-256, nonce="5TsQWLVdgBdmrQ0XsxbDODV+57QdFR34I9HAbC/RVvkK", opaque="HRPCssKJSGjCrkzDg8OhwpzCiGPChXYjwrI2QmXDnsOS", charset=UTF-8, userhash=true'
)->[0];

my $digest_utf8 = Uniform::HTTP::Auth::Digest->new(
    _random_bytes => sub { return "\x02" x 24 },
);
my $utf8_key = Uniform::HTTP::Auth::Digest::_state_key(
    '',
    $utf8_challenge->{params}{realm},
    "J\x{00e4}s\x{00f8}n Doe",
    $utf8_challenge->{params}{nonce},
);
$digest_utf8->{nonce_state}{$utf8_key} = {
    count  => 0,
    cnonce => 'NTg6RKcb9boFIAS3KrFK9BGeh+iDa/sm6jUMp2wds69v',
};

my $utf8_value = $digest_utf8->authorization(
    challenge      => $utf8_challenge,
    username       => "J\x{00e4}s\x{00f8}n Doe",
    password       => 'Secret, or not?',
    method         => 'GET',
    request_target => '/doe.json',
);
like $utf8_value,
    qr/username="793263caabb707a56211940d90411ea4a575adeccb7e360aeb624ed06ece9b0b"/,
    'SHA-512-256 userhash matches RFC 7616 errata correction';
like $utf8_value,
    qr/response="3798d4131c277846293534c3edc11bd8a5e4cdcbff78b05db9d95eeb1cec68a5"/,
    'SHA-512-256 UTF-8 response matches RFC 7616 errata correction';

my $legacy_sess = $auth->parse_challenges(
    'Digest realm="legacy", nonce="nonce", algorithm=MD5-sess'
)->[0];
my $sess = Uniform::HTTP::Auth::Digest->new(
    _random_bytes => sub { return "\x03" x 24 },
);
my $sess_value = $sess->authorization(
    challenge      => $legacy_sess,
    username       => 'user',
    password       => 'pass',
    method         => 'GET',
    request_target => '/',
);
like $sess_value, qr/\bcnonce="[0-9a-f]+"/, 'legacy -sess without qop still sends cnonce';
unlike $sess_value, qr/\bnc=/, 'legacy no-qop Digest does not send nonce count';

done_testing;
