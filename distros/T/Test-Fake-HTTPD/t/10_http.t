use Test::More;
use Test::Exception;
use Test::TCP qw(wait_port);
use LWP::UserAgent;

BEGIN {
    *describe = *it = \&subtest;
}

use Test::Fake::HTTPD;

describe 'run_http_server' => sub {
    my $httpd = run_http_server {
        my $req = shift;
        [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
    };

    it 'should return a server info' => sub {
        my $port = $httpd->port;

        ok $port > 0;
        is $httpd->host_port => "127.0.0.1:$port";
        is $httpd->endpoint  => "http://127.0.0.1:$port";
    };

    it 'should receive correct response' => sub {
        my $ua = LWP::UserAgent->new;

        my $res = $ua->get($httpd->endpoint);

        is $res->code => 200;
        is $res->header('Content-Type') => 'text/plain';
        is $res->content => 'Hello World';
    };
};

done_testing;
