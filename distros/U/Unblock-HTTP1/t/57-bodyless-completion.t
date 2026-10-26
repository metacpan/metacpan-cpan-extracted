use strict;
use warnings;
use Test::More;
use Unblock::HTTP1::Server;

my (@headers, @complete, @finished);
my $server = Unblock::HTTP1::Server->new(
    receive_body => 'buffered',
    on_request => sub {
        my ($tx, $request) = @_;
        push @headers, [
            $request->target, $request->is_complete, $request->is_mutable,
        ];
        $tx->on_finish(sub { push @finished, $_[0]->state });
    },
    on_request_end => sub {
        my ($tx, $request) = @_;
        push @complete, [
            $request->target, $request->body, $request->is_complete,
            $request->is_mutable, $tx->{receive_done},
        ];
        $tx->respond(status => 200, body => 'ok');
    },
);

my $wire =
    "GET /first HTTP/1.1\r\nHost: example.test\r\n\r\n"
    . "GET /second HTTP/1.1\r\nHost: example.test\r\n\r\n"
    . "POST /third HTTP/1.1\r\nHost: example.test\r\n"
    . "Content-Length: 4\r\n\r\nDATA";

is($server->input($wire), length($wire), 'all pipelined requests accepted');
is_deeply(
    \@headers,
    [
        ['/first', 1, 0],
        ['/second', 1, 0],
        ['/third', 0, 1],
    ],
    'bodyless canonical requests are already complete and immutable at headers',
);
is_deeply(
    \@complete,
    [
        ['/first', '', 1, 0, 1],
        ['/second', '', 1, 0, 1],
        ['/third', 'DATA', 1, 0, 1],
    ],
    'bodyless requests keep canonical state; buffered request finishes normally',
);
is_deeply(\@finished, [('complete') x 3],
    'all pipelined transactions finish exactly once');
my $output = $server->output;
is(scalar(() = $output =~ /HTTP\/1\.1 200 OK\r\n/g), 3,
    'all three responses serialized');
ok(!$server->is_closed, 'persistent HTTP1 connection remains reusable');

done_testing;
