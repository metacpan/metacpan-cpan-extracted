use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until_idle);
use Uniform::HTTP::Request;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my $server_saw_request = 0;
my @server_errors;
my @client_errors;

my $server = Unblock::HTTP2::Server->new(
    enable_connect_protocol => 0,

    on_request => sub {
        $server_saw_request = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @server_errors, $error;
    },
);

my $client = Unblock::HTTP2::Client->new;

# Finish the initial SETTINGS exchange before attempting Extended CONNECT.
pump_until_idle($client, $server);

my $request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'websocket',
    scheme    => 'https',
    authority => 'example.test',
    target    => '/chat',
);

my $ok = eval {
    $client->request(
        $request,
        stream_body => 1,
        on_error => sub {
            my ($stream, $error) = @_;
            push @client_errors, $error;
        },
    );
    1;
};

ok !$ok,
    'Extended CONNECT is refused when peer did not enable the protocol setting';
like $@, qr/(?:protocol|setting|invalid|request)/i,
    'peer-setting refusal is reported by the HTTP/2 stack';

if ($ok) {
    pump_until_idle($client, $server);
}

ok !$server_saw_request,
    'disabled peer never receives an Extended CONNECT request';

done_testing;
