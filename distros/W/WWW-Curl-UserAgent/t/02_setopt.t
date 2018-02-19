use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 25;

use HTTP::Request;
use Sub::Override;
use Test::MockObject;

use WWW::Curl::Easy;

BEGIN {
    use_ok('WWW::Curl::UserAgent::Request');
}

{
    note 'request parameters';

    my %curlopt = request( HTTP::Request->new( GET => 'dummy', [ 'X-Foo' => 'bar' ] ) );

    is $curlopt{WWW::Curl::Easy::CURLOPT_CONNECTTIMEOUT_MS}, 6,       'connect timeout';
    is $curlopt{WWW::Curl::Easy::CURLOPT_HEADER},            0,       'no header';
    is $curlopt{WWW::Curl::Easy::CURLOPT_NOPROGRESS},        1,       'no progress';
    is $curlopt{WWW::Curl::Easy::CURLOPT_TIMEOUT_MS},        7,       'timeout';
    is $curlopt{WWW::Curl::Easy::CURLOPT_URL},               'dummy', 'url';
    is $curlopt{WWW::Curl::Easy::CURLOPT_FORBID_REUSE},      1,       'no keep-alive';
    is $curlopt{WWW::Curl::Easy::CURLOPT_FOLLOWLOCATION},    1,       'follow redirects';
    is $curlopt{WWW::Curl::Easy::CURLOPT_MAXREDIRS},         10,      'maximum of redirects';
    is_deeply $curlopt{WWW::Curl::Easy::CURLOPT_HTTPHEADER}, [ 'X-Foo: bar', 'Connection: close' ], 'http header';
}

{
    note 'GET request';

    my %curlopt = request( HTTP::Request->new( GET => 'dummy' ) );

    is $curlopt{WWW::Curl::Easy::CURLOPT_HTTPGET}, 1, 'GET request';
}

{
    note 'PUT request';

    my %curlopt = request( HTTP::Request->new( PUT => 'dummy', [], 'content' ) );

    is $curlopt{WWW::Curl::Easy::CURLOPT_HTTPGET}, undef, 'no GET request';
    is $curlopt{WWW::Curl::Easy::CURLOPT_UPLOAD},  1,     'PUT request';
    is $curlopt{WWW::Curl::Easy::CURLOPT_INFILESIZE}, length 'content', 'content length';
}

{
    note 'PATCH request';

    my %curlopt = request( HTTP::Request->new( PATCH => 'dummy', [], 'content' ) );

    is $curlopt{WWW::Curl::Easy::CURLOPT_HTTPGET}, undef, 'no GET request';
    is $curlopt{WWW::Curl::Easy::CURLOPT_UPLOAD},  1,     'PATCH request';
    is $curlopt{WWW::Curl::Easy::CURLOPT_INFILESIZE}, length 'content', 'content length';
}

{
    note 'POST request';

    my %curlopt = request( HTTP::Request->new( POST => 'dummy', [], 'content' ) );

    is $curlopt{WWW::Curl::Easy::CURLOPT_HTTPGET}, undef, 'no GET request';
    is $curlopt{WWW::Curl::Easy::CURLOPT_POST},    1,     'POST request';
    is $curlopt{WWW::Curl::Easy::CURLOPT_POSTFIELDSIZE}, length 'content', 'content length';
    is $curlopt{WWW::Curl::Easy::CURLOPT_COPYPOSTFIELDS}, 'content', 'content';
}

{
    note 'HEAD request';

    my %curlopt = request( HTTP::Request->new( HEAD => 'dummy', [], 'content' ) );

    is $curlopt{WWW::Curl::Easy::CURLOPT_HTTPGET}, undef, 'no GET request';
    is $curlopt{WWW::Curl::Easy::CURLOPT_NOBODY},  1,     'HEAD request';
}

{
    note 'DELETE request';

    my %curlopt = request( HTTP::Request->new( DELETE => 'dummy', [], 'content' ) );

    is $curlopt{WWW::Curl::Easy::CURLOPT_HTTPGET},       undef,    'no GET request';
    is $curlopt{WWW::Curl::Easy::CURLOPT_CUSTOMREQUEST}, 'DELETE', 'DELETE request';
}

sub request {
    my ($request) = @_;

    my $curl = Test::MockObject->new;
    $curl->set_isa('WWW::Curl::Easy');
    $curl->set_true('setopt');

    my $o = Sub::Override->new( 'WWW::Curl::Easy::new' => sub (;@) {$curl} );

    WWW::Curl::UserAgent::Request->new(
        http_request    => $request,
        connect_timeout => 6,
        timeout         => 7,
        keep_alive      => 0,
        followlocation  => 1,
        max_redirects   => 10,
    )->curl_easy;

    my %curlopt;
    while ( my @next = $curl->next_call ) {
        $curlopt{ $next[1][1] } = $next[1][2];
    }

    return %curlopt;
}
