use Test::More;
use Test::Exception;
use Test::TCP qw(wait_port);
use LWP::UserAgent;

BEGIN {
    *describe = *it = \&subtest;
}

use Test::Fake::HTTPD;

plan skip_all => "disable SSL" unless Test::Fake::HTTPD::enable_ssl();

extra_daemon_args
    SSL_key_file  => 'certs/server-key.pem',
    SSL_cert_file => 'certs/server-cert.pem';

describe 'run_https_server' => sub {
    my $httpd = run_https_server {
        my $req = shift;
        [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
    };

    it 'should return a server info' => sub {
        my $port = $httpd->port;

        ok $httpd->port;
        is $httpd->host_port => "127.0.0.1:$port";
        is $httpd->endpoint  => "https://127.0.0.1:$port";
    };

    it 'should receive correct response' => sub {
        my $ua = LWP::UserAgent->new(ssl_opts => {
            SSL_verify_mode => 0,
            verify_hostname => 0,
        });

        my $res = $ua->get($httpd->endpoint);

        is $res->code => 200;
        is $res->header('Content-Type') => 'text/plain';
        is $res->content => 'Hello World';
    };
};

done_testing;
