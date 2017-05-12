#!perl -T

use Test::More;
use Test::Exception;

use HTTP::Headers;

BEGIN {
    use_ok 'WebService::XING::Response';
}

my $res;
my $headers = HTTP::Headers->new;
my @required = qw(code message headers content);

dies_ok { $res = WebService::XING::Response->new } 'missing required attributes';

for my $attr (@required) {
    dies_ok {
        $res = WebService::XING::Response->new(map { $_ => 1 } grep { $attr ne $_ } @required)
    } "missing attribute $attr";
}

lives_ok {
    $res = WebService::XING::Response->new(
        code => 201,
        message => 'Created',
        headers => $headers,
        content => { id => '42', value => 'lalala' },
    );
} 'create a WebService::XING::Response 2xx response';

is $res->as_string, '201 Created', 'as_string() works correctly';
is $res, '201 Created', 'stringifies with as_string()';
ok $res == 201, 'numifies to code attribute';
ok $res->is_success, 'is_success returns true';
ok $res, 'use is_success() in boolean context';

lives_ok {
    $res = WebService::XING::Response->new(
        code => 403,
        message => 'Forbidden',
        headers => $headers,
        content => {
            error_name => 'INVALID_OAUTH_TOKEN',
            message => 'Invalid OAuth token',
        },
    );
} 'create a WebService::XING::Response 4xx response';

is $res->as_string, '403 Forbidden', 'as_string() works correctly';
is $res, '403 Forbidden', 'stringifies with as_string()';
ok $res == 403, 'numifies to code attribute';
ok !$res->is_success, 'is_success returns false';
ok !$res, 'use is_success() in boolean context';

done_testing;
