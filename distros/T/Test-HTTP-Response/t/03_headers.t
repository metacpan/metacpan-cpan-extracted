use strict;
use warnings;
use HTTP::Response;
use HTTP::Message;
use Test::Builder::Tester;
use Test::More;
use Test::HTTP::Response;

# Create new cookies, headers, etc
my $headers = ['Cache-Control' => 'private', 'Content-Type' => 'text/html', 'X-Foo' => 20 ];
my $message = HTTP::Message->new( $headers, '<HTML><BODY><h1>Hello World</h1></BODY></HTML>');
my $response = HTTP::Response->new( 200, $message, $message->headers );

headers_match $response, {
    'Cache-Control' => qr/PRIVATE/i,
    'Content-Type' => 'text/html',
    'X-Foo' => sub { $_ == 20 }
};

test_out("not ok 1 - HTTP header field X-Foo matches");
test_err("#   Failed test 'HTTP header field X-Foo matches'\n#   at t/03_headers.t line ".(line_num()+3).".");
headers_match $response, {
    'X-Foo' => sub { $_ == 21 }
};

test_test('Fail for SubRef constraint');

diag "check headers_match is case insensitive";
headers_match $response, {
    'x-foo' => sub { $_ == 20 }
};

all_headers_match $response, {
    'Cache-Control' => qr/PRIVATE/i,
    'Content-Type' => 'text/html',
    'X-Foo' => sub { $_ == 20 }
};

diag "checking all_headers_match is case insensitive.";
all_headers_match $response, {
    'Cache-control' => qr/PRIVATE/i,
    'content-Type' => 'text/html',
    'X-foo' => sub { $_ == 20 }
};

test_out(q{ok 1 - HTTP header field Cache-control matches
ok 2 - HTTP header field content-Type matches
not ok 3 - Test for HTTP header field 'x-foo'
not ok 4 - Tests for all HTTP header fields});
test_err(q{#   Failed test 'Test for HTTP header field 'x-foo''
#   at t/03_headers.t line 55.
#   Failed test 'Tests for all HTTP header fields'
#   at t/03_headers.t line 55.});

all_headers_match $response, {
    'Cache-control' => qr/PRIVATE/i,
    'content-Type' => 'text/html',
};

test_test("all_headers_match fails on missing field");

done_testing();
