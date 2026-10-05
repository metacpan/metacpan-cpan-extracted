use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

my $server = Unblock::HTTP1::Server->new(
    on_request => sub {
        my ($tx) = @_;
        $tx->send_informational(Uniform::HTTP::Response->new(
            status => 103,
            headers => [ [ Link => '</style.css>; rel=preload' ] ],
        ));
        $tx->respond(Uniform::HTTP::Response->new(status => 200, body => 'ok'));
    },
);

my @status;
my $client = Unblock::HTTP1::Client->new;
$client->request(
    Uniform::HTTP::Request->new(
        method => 'GET', target => '/', authority => 'example.test',
    ),
    on_informational => sub { push @status, $_[1]->status },
    on_response => sub { push @status, $_[1]->status },
    on_error => sub { die "client error: $_[1]" },
);
$server->input($client->output);
$client->input($server->output);
is_deeply(\@status, [103, 200], 'informational response precedes final response');


subtest 'respond rejects non-101 informational status' => sub {
    my $respond_error;
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            my $ok = eval {
                $tx->respond(Uniform::HTTP::Response->new(status => 103));
                1;
            };
            $respond_error = $@ unless $ok;

            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ));
        },
    );

    $server->input(
        "GET / HTTP/1.1\r\nHost: example.test\r\n\r\n"
    );

    like(
        $respond_error,
        qr/informational status must use send_informational/,
        'respond explains the informational API boundary',
    );
    is(
        $server->output,
        "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok",
        'only the final response reaches the wire',
    );
};

done_testing;
