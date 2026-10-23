use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;

sub exercise_backend {
    my ($backend) = @_;
    my (@server_message, @client_message, @server_ping, @client_pong);
    my (@server_close, @client_close);

    my $server = Unblock::WebSocket::Server->new(
        backend => $backend,
        on_message => sub {
            my ($ws, $payload, $type) = @_;
            push @server_message, [ $payload, $type ];
        },
        on_ping => sub {
            my ($ws, $payload) = @_;
            push @server_ping, $payload;
        },
        on_close => sub {
            my ($ws, $code, $reason) = @_;
            push @server_close, [ $code, $reason ];
        },
    );

    my %client_option = (
        backend => $backend,
        on_message => sub {
            my ($ws, $payload, $type) = @_;
            push @client_message, [ $payload, $type ];
        },
        on_pong => sub {
            my ($ws, $payload) = @_;
            push @client_pong, $payload;
        },
        on_close => sub {
            my ($ws, $code, $reason) = @_;
            push @client_close, [ $code, $reason ];
        },
    );
    $client_option{random_bytes} = sub { "\x01\x02\x03\x04" }
        if $backend eq 'perl';

    my $client = Unblock::WebSocket::Client->new(%client_option);

    $client->send_text("hello \x{263a}");
    $server->input($client->output);

    $server->send_binary("\x00\x01\xff");
    $client->input($server->output);

    $client->ping('probe');
    $server->input($client->output);
    $client->input($server->output);

    $client->close(code => 1000, reason => 'done');
    $server->input($client->output);
    my $close_reply = $server->output;
    $client->input($close_reply);

    return {
        server_message  => \@server_message,
        client_message  => \@client_message,
        server_ping     => \@server_ping,
        client_pong     => \@client_pong,
        server_close    => \@server_close,
        client_close    => \@client_close,
        server_end      => $server->want_end ? 1 : 0,
        client_end      => $client->want_end ? 1 : 0,
        client_complete => $client->close_complete ? 1 : 0,
    };
}

my $perl = exercise_backend('perl');
is_deeply $perl->{server_message}, [ [ "hello \x{263a}", 'text' ] ],
    'reference backend delivered text';
is_deeply $perl->{client_message}, [ [ "\x00\x01\xff", 'binary' ] ],
    'reference backend delivered binary';

SKIP: {
    skip 'native engine is not available', 1
        unless Unblock::WebSocket->native_available;
    my $native = exercise_backend('native');
    is_deeply $native, $perl,
        'native public backend matches reference callback and close semantics';
}

done_testing;
