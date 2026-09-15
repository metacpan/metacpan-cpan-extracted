use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

my $request = Uniform::HTTP::Request->new(
    method => 'POST',
    target => '/items?draft=1',
    headers => [ [ Host => 'example.com' ] ],
);

isa_ok $request, 'Uniform::HTTP::Message';
is $request->method, 'POST', 'request method is retained';
is $request->target, '/items?draft=1', 'request target is retained exactly';
ok $request->target_is_exact, 'canonical request target is exact';
is $request->method('PATCH'), $request, 'method setter is chainable';
is $request->target('*'), $request, 'asterisk target is accepted';

my $response = Uniform::HTTP::Response->new(
    status  => 204,
    headers => [ [ 'X-Test', 'yes' ] ],
);

isa_ok $response, 'Uniform::HTTP::Message';
is $response->status, 204, 'response status is retained';
is $response->reason, undef, 'reason is not synthesized';
is $response->version, undef, 'version is not synthesized';
is $response->status(299), $response, 'status setter is chainable';
is $response->reason('Custom'), $response, 'reason setter is chainable';
is $response->reason, 'Custom', 'reason is retained';
is $response->reason(undef), $response, 'reason can be cleared';
is $response->reason, undef, 'cleared reason is undef';

done_testing;
