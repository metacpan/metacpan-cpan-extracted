use strict;
use warnings;

use Test::Needs 'HTTP::Message::PSGI';
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;

use Test::LWP::UserAgent;
use Scalar::Util 'refaddr';
use HTTP::Request::Common;

my $app_foo = sub {
    my $env = shift;
    return [ '200', ['Content-Type' => 'text/plain' ], [ 'this is the foo app' ]];
};

my $app_foo2 = sub {
    my $env = shift;
    return [ '200', ['Content-Type' => 'text/html' ], [ 'this is the alternative foo app' ]];
};

my $app_bar = sub {
    my $env = shift;
    return [ '200', ['Content-Type' => 'text/html' ], [ 'this is the bar app' ]];
};

my $app_bar2 = sub {
    my $env = shift;
    return [ '200', ['Content-Type' => 'text/plain' ], [ 'this is the alternative bar app' ]];
};

my $app_baz = sub {
    my $env = shift;
    return [ '200', ['Content-Type' => 'image/jpeg' ], [ 'this is the baz app' ]];
};

{
    my $useragent = Test::LWP::UserAgent->new;
    my $useragent2 = Test::LWP::UserAgent->new;

    Test::LWP::UserAgent->register_psgi('foo', $app_foo);
    $useragent->register_psgi('bar', $app_bar);
    Test::LWP::UserAgent->register_psgi('bar', $app_bar2);
    $useragent2->register_psgi('baz', $app_baz);

    test_send_request('foo app (registered globally)', $useragent, GET('http://foo'),
        '200', [ 'Content-Type' => 'text/plain' ], 'this is the foo app');

    $useragent->register_psgi('foo' , $app_foo2);

    test_send_request('foo app (registered on the object)', $useragent, GET('http://foo'),
        '200', [ 'Content-Type' => 'text/html' ], 'this is the alternative foo app');

    # the object registration takes priority
    test_send_request('bar app (registered on the object)', $useragent, GET(URI->new('http://bar')),
        '200', [ 'Content-Type' => 'text/html' ], 'this is the bar app');

    test_send_request('baz app (registered on the second object)', $useragent2, GET('http://baz'),
        '200', [ 'Content-Type' => 'image/jpeg' ], 'this is the baz app');

    test_send_request('unmatched request', $useragent, GET('http://quux'),
        '404', [ ], '');


    $useragent->unregister_psgi('bar', 'this_instance_only');

    test_send_request('backup bar app is now available to this instance', $useragent, GET('http://bar'),
        '200', [ 'Content-Type' => 'text/plain' ], 'this is the alternative bar app');

    $useragent->unregister_psgi('bar');

    test_send_request('bar app (was registered on the instance, but now removed everywhere)',
        $useragent, GET('http://bar'),
        '404', [ ], '');


    # mask a mapping from just this one instance
    $useragent->unregister_psgi('foo', 'instance_only');

    test_send_request('foo app was registered on both, but now removed from the instance only',
        $useragent, GET('http://foo'),
        '200', [ 'Content-Type' => 'text/plain' ], 'this is the foo app');

    test_send_request('foo app (registered globally; still available for other instances)',
        $useragent2, GET('http://foo'),
        '200', [ 'Content-Type' => 'text/plain' ], 'this is the foo app');

    # mask the global mapping entirely
    $useragent->register_psgi('foo', undef);
    test_send_request('foo app was registered globally, but now removed from the instance only',
        $useragent, GET('http://foo'),
        '404', [ ], '');


    $useragent->unmap_all('this_instance_only');

    test_send_request('baz app is not available on this instance', $useragent, GET('http://baz'),
        '404', [ ], '');

    test_send_request('baz app is still available on other instances', $useragent2, GET('http://baz'),
        '200', [ 'Content-Type' => 'image/jpeg' ], 'this is the baz app');

    $useragent->unmap_all;

    test_send_request('bar app now removed', $useragent, GET('http://baz'),
        '404', [ ], '');

    test_send_request('baz app now removed', $useragent, GET('http://baz'),
        '404', [ ], '');
}

sub test_send_request
{
    my ($name, $useragent, $request, $expected_code, $expected_headers, $expected_content) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    note "\n", $name;

    my $response = $useragent->request($request);

    # response is what we stored in the useragent
    isa_ok($response, 'HTTP::Response');
    is(
        refaddr($useragent->last_http_response_received),
        refaddr($response),
        'last_http_response_received',
    );

    cmp_deeply(
        $useragent->last_http_request_sent,
        all(
            isa('HTTP::Request'),
            $request,
        ),
        "$name - request",
    );

    my %header_spec = @$expected_headers;

    cmp_deeply(
        $response,
        methods(
            code => $expected_code,
            ( map { [ header => $_ ] => $header_spec{$_} } keys %header_spec ),
            content => $expected_content,
            request => $useragent->last_http_request_sent,
        ),
        "$name - response",
    );

    ok(
        HTTP::Date::parse_date($response->header('Client-Date')),
        'Client-Date is a timestamp',
    );
}

done_testing;
