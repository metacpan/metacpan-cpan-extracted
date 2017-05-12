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
my $client_pem = "$Bin/client.pem";

subtest 'tls connection' => sub {
    my ($success, $content);

    test_tcp(
        client => sub {
            my $port = shift;

            alarm 2;
            local $SIG{ALRM} = sub {die};

            my $ua = LWP::UserAgent->new(
                ssl_opts => {
                    verify_hostname => 1,
                    SSL_ca_file     => $ca_cert,
                    SSL_key_file  => $client_pem,
                    SSL_cert_file => $client_pem,
                }
            );

            my $res = $ua->get("https://$host:$port");
            $success = $res->is_success or die $res->status_line;

            $content = $res->decoded_content;
        },
        server => sub {
            my $port   = shift;
            my $server = Plack::Loader->load(
                'Twiggy::TLS',
                host       => inet_ntoa(inet_aton($host)),
                port       => $port,
                tls_key    => $server_pem,
                tls_cert   => $server_pem,
                tls_ca     => $ca_cert,
                tls_verify => 'on',
            );

            $server->run(
                sub {
                    return [
                        200,
                        ['Content-Type' => 'text/plain'],
                        [shift->{'psgi.tls'}->client_certificate('cn')]
                    ];
                }
            );
        }
    );

    ok $success, "https connection success";
    is $content, 'user@localhost', "content is right";
};

done_testing;
