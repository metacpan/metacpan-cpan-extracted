use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Auth;

my $auth = Uniform::HTTP::Auth->new;

my $newline = $auth->parse_challenges("Basic realm=\"x\"\r\nInjected: yes");
ok $newline->[0]{malformed}, 'newline in remote header is data error, not exception';

my $control = $auth->parse_challenges("Basic realm=\"bad\x01realm\"");
ok $control->[0]{malformed}, 'control byte in quoted parameter is malformed';
like $control->[0]{error}, qr/malformed quoted/, 'quoted control error is explicit';

my $error = eval { Uniform::HTTP::Auth->new(schemes => ['negotiate']); 1 };
ok !$error, 'unsupported configured built-in scheme croaks';
like $@, qr/unsupported authentication scheme/, 'unsupported scheme error is explicit';

my $bad_origin = Uniform::HTTP::Auth->new(credentials => sub { return });
eval {
    $bad_origin->prepare_authentication(
        challenge_headers => ['Basic realm="x"'],
        origin => 'https://user:pass@example.com/private',
    );
};
like $@, qr/normalized origin/, 'origin with credentials/path is rejected';

eval {
    $bad_origin->prepare_authentication(
        challenge_headers => ['Basic realm="x"'],
        origin => 'https://bad host.example:443',
    );
};
like $@, qr/whitespace or control/, 'origin containing whitespace is rejected';

my $digest = Uniform::HTTP::Auth->new(
    schemes => ['digest'],
    credentials => sub {
        return { username => 'user', password => 'secret' };
    },
);
eval {
    $digest->prepare_authentication(
        challenge_headers => [
            'Digest realm="x", nonce="n", algorithm=SHA-256, qop="auth-int"'
        ],
        origin         => 'https://example.com:443',
        method         => 'POST',
        request_target => '/',
        entity_body    => [],
    );
};
like $@, qr/entity_body must be a defined plain scalar/,
    'auth-int rejects non-scalar entity body';

done_testing;
