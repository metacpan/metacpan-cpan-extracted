use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Auth;
use Uniform::HTTP::Auth::Digest;

my $auth = Uniform::HTTP::Auth->new;
my $digest = Uniform::HTTP::Auth::Digest->new(
    _random_bytes => sub { return "\x04" x 24 },
);

my $first = $auth->parse_challenges(
    'Digest realm="Members", nonce="old-nonce", algorithm=SHA-256, qop="auth"'
)->[0];

my %args = (
    username       => 'user',
    password       => 'secret',
    method         => 'GET',
    request_target => '/',
);

my $one = $digest->authorization(
    challenge => $first,
    origin    => 'https://one.example:443',
    %args,
);
my $two = $digest->authorization(
    challenge => $first,
    origin    => 'https://one.example:443',
    %args,
);
like $one, qr/\bnc=00000001\b/, 'first use of nonce starts at one';
like $two, qr/\bnc=00000002\b/, 'reuse of nonce increments nonce count';

my $other_origin = $digest->authorization(
    challenge => $first,
    origin    => 'https://two.example:443',
    %args,
);
like $other_origin, qr/\bnc=00000001\b/,
    'same nonce at another origin has independent state';

my $stale = $auth->parse_challenges(
    'Digest realm="Members", nonce="fresh-nonce", algorithm=SHA-256, qop="auth", stale=true'
)->[0];

my $retry = $digest->authorization(
    challenge => $stale,
    origin    => 'https://one.example:443',
    %args,
);
like $retry, qr/\bnonce="fresh-nonce"/, 'stale retry uses replacement nonce';
like $retry, qr/\bnc=00000001\b/, 'replacement nonce starts a fresh nonce-count sequence';

done_testing;
