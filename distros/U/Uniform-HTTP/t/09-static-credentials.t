use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Auth;

my $basic = Uniform::HTTP::Auth->new(
    origin => 'https://example.com:443',
    credentials => {
        username => 'Aladdin',
        password => 'open sesame',
    },
);

my $basic_result = $basic->prepare_authentication(
    challenge_headers => ['Basic realm="Members"'],
);

is $basic_result->{scheme}, 'basic', 'stored username/password satisfies Basic';
is $basic_result->{value}, 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==',
    'stored credentials are used later';

my $bearer = Uniform::HTTP::Auth->new(
    origin => 'https://api.example.com:443',
    credentials => {
        token => 'mF_9.B5f-4.1JqM',
    },
);

my $bearer_result = $bearer->prepare_authentication(
    challenge_headers => [
        'Digest realm="api", nonce="abc", qop="auth", algorithm=SHA-256, Bearer realm="api"',
    ],
);

is $bearer_result->{scheme}, 'bearer',
    'scheme without suitable stored credentials is skipped';
is $bearer_result->{value}, 'Bearer mF_9.B5f-4.1JqM',
    'stored token satisfies Bearer';

eval {
    Uniform::HTTP::Auth->new(
        credentials => {
            username => 'user',
            password => 'secret',
        },
    );
};
like $@, qr/origin is required/, 'static credentials require a bound origin';

eval {
    $basic->prepare_authentication(
        challenge_headers => ['Basic realm="Members"'],
        origin => 'https://other.example.com:443',
    );
};
like $@, qr/origin does not match/, 'bound credentials cannot be used for another origin';

eval {
    Uniform::HTTP::Auth->new(
        origin => 'https://example.com:443',
        credentials => { username => 'user' },
    );
};
like $@, qr/both username and password/, 'incomplete static username/password is rejected';

eval {
    Uniform::HTTP::Auth->new(
        origin => 'https://example.com:443',
        credentials => {},
    );
};
like $@, qr/token or username\/password/, 'empty static credentials are rejected';

eval {
    Uniform::HTTP::Auth->new(
        origin => 'https://example.com:443',
        credentials => { token => 'x' },
        typo => 1,
    );
};
like $@, qr/unknown constructor option/, 'unknown constructor options fail fast';

done_testing;
