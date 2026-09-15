use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Auth;
use Uniform::HTTP::Request;

my $auth = Uniform::HTTP::Auth->new(
    schemes => ['digest'],
    origin => 'https://example.com:443',
    credentials => {
        username => 'user',
        password => 'secret',
    },
);
$auth->{digest}{_random_bytes} = sub { return "\x04" x 24 };

my $request = Uniform::HTTP::Request->new(
    method => 'POST',
    target => '/private?x=1',
    body   => 'content',
);

my $result = $auth->prepare_authentication(
    challenge_headers => [
        'Digest realm="Members", nonce="abc", qop="auth-int", algorithm=SHA-256'
    ],
    request => $request,
);

is $result->{scheme}, 'digest', 'Digest is prepared from a request object';
like $result->{value}, qr/\buri="\/private\?x=1"/,
    'exact request target is read from the request contract';
like $result->{value}, qr/\bqop=auth-int\b/,
    'buffered request body supports auth-int';

{
    package Local::UnbufferedRequest;
    sub new { bless {}, shift }
    sub method { 'GET' }
    sub target { '/streamed' }
    sub has_buffered_body { 0 }
    sub body { die 'body must not be read' }
}

my $unbuffered = Local::UnbufferedRequest->new;
my $auth_result = $auth->prepare_authentication(
    challenge_headers => [
        'Digest realm="Members", nonce="def", qop="auth", algorithm=SHA-256'
    ],
    request => $unbuffered,
);
is $auth_result->{scheme}, 'digest', 'duck-typed request contract is accepted';
like $auth_result->{value}, qr/\buri="\/streamed"/,
    'unbuffered request supplies method and target';

my $explicit = $auth->prepare_authentication(
    challenge_headers => [
        'Digest realm="Members", nonce="ghi", qop="auth", algorithm=SHA-256'
    ],
    request        => $request,
    method         => 'PUT',
    request_target => '/override',
);
like $explicit->{value}, qr/\buri="\/override"/,
    'explicit request target takes precedence';

eval {
    $auth->prepare_authentication(
        challenge_headers => ['Basic realm="Members"'],
        request => bless({}, 'Local::BadRequest'),
    );
};
like $@, qr/request must implement/, 'incomplete request contract is rejected';

done_testing;
