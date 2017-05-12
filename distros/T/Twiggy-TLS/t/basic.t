#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::TCP;
use Plack::Loader;
use LWP::UserAgent;
use FindBin '$Bin';
use Socket;

my $host       = "localhost";
my $ca_cert    = "$Bin/ca.pem";
my $server_pem = "$Bin/server.pem";

subtest 'tls connection' => sub {
    my ($success, $content);

    test_tcp(
        client => sub {
            my $port = shift;

            alarm 2;
            local $SIG{ALRM} = sub {die};

            my $ua =
              LWP::UserAgent->new(
                ssl_opts => {verify_hostname => 1, SSL_ca_file => $ca_cert});
            my $res = $ua->get("https://$host:$port");
            $success = $res->is_success or die $res->status_line;
            $content = $res->decoded_content;
        },
        server => sub {
            my $port   = shift;
            my $server = Plack::Loader->load(
                'Twiggy::TLS',
                host     => inet_ntoa(inet_aton($host)),
                port     => $port,
                tls_key  => $server_pem,
                tls_cert => $server_pem,
            );

            $server->run(
                sub {
                    my $env = shift;

                    return [
                        200,
                        ['Content-Type' => 'text/plain'],
                        [$env->{"psgi.url_scheme"}]
                    ];
                }
            );
        }
    );

    ok $success, "https connection success";
    is $content, "https", "returned content is right";
};

done_testing;
