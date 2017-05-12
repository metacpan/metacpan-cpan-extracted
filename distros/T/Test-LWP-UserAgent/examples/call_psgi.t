use strict;
use warnings;

use Test::More 0.88;
use Test::Needs 'HTTP::Message::PSGI';
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::LWP::UserAgent;
use HTTP::Request::Common;

my $useragent = Test::LWP::UserAgent->new;
$useragent->register_psgi('example.com' => sub {
        my $env = shift;
        # logic here...
        [ '200', [ 'Content-Type' => 'text/plain' ], [ 'some body' ] ],
    }
);

# <something which calls the code being tested...>
my $response = $useragent->request(POST('http://example.com/success:3000', [ a => 1 ]));

my $last_request = $useragent->last_http_request_sent;
is($last_request->uri, 'http://example.com/success:3000', 'URI');
is($last_request->content, 'a=1', 'POST content');

# <now test that your code responded to the 200 response properly...>
is($response->code, '200', 'response code is correct');


done_testing;
