use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Unblock::HTTP1::Client;

sub request {
    my ($path) = @_;
    return Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => $path,
        headers => [ [ Host => 'example.test' ] ],
    );
}

subtest 'unsolicited second response cannot satisfy queued request' => sub {
    my @event;
    my $second_error;

    my $client = Unblock::HTTP1::Client->new;

    my $first = $client->request(
        request('/one'),
        on_complete => sub { push @event, 'first-complete' },
        on_error    => sub { push @event, 'first-error' },
    );

    my $second = $client->request(
        request('/two'),
        on_response => sub { push @event, 'second-response' },
        on_complete => sub { push @event, 'second-complete' },
        on_error    => sub {
            $second_error = $_[1];
            push @event, 'second-error';
        },
    );

    my $first_wire = $client->output;
    like($first_wire, qr/\AGET \/one HTTP\/1\.1\r\n/,
        'only the first serialized request is emitted initially');
    unlike($first_wire, qr/GET \/two /,
        'second request is not pipelined');

    $client->input(
        "HTTP/1.1 200 OK\r\n" .
        "Content-Length: 3\r\n\r\n" .
        "one" .
        "HTTP/1.1 200 OK\r\n" .
        "Content-Length: 3\r\n\r\n" .
        "two"
    );

    ok($first->is_complete, 'first response completes normally');
    is($second->state, 'error', 'queued transaction is failed');
    like($second_error, qr/unexpected bytes after final HTTP\/1 response/,
        'queued transaction receives an explicit response-boundary error');
    ok($client->is_closed, 'connection closes after unsolicited response bytes');
    is($client->output, '', 'second request is never emitted after poisoning attempt');
    is_deeply(
        \@event,
        [ qw(first-complete second-error) ],
        'unsolicited second response is never dispatched to queued transaction',
    );
};

subtest 'extra bytes after an otherwise complete response close reuse' => sub {
    my @event;
    my $client = Unblock::HTTP1::Client->new;

    my $tx = $client->request(
        request('/one'),
        on_complete => sub { push @event, 'complete' },
        on_error    => sub { push @event, 'error' },
    );
    $client->output;

    $client->input(
        "HTTP/1.1 204 No Content\r\n\r\nEXTRA"
    );

    ok($tx->is_complete, 'completed response remains successful');
    is_deeply(\@event, [ 'complete' ],
        'completed transaction is not retroactively converted to an error');
    ok($client->is_closed, 'connection is not reusable with extra received bytes');
};


subtest 'idle unsolicited response bytes close the connection' => sub {
    my @event;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        request('/one'),
        on_complete => sub { push @event, 'complete' },
        on_error    => sub { push @event, 'error' },
    );
    $client->output;

    $client->input(
        "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
    );

    ok($tx->is_complete, 'first response completes normally');
    ok(!$client->is_closed, 'connection is idle and reusable after first response');

    $client->input(
        "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
    );

    ok($client->is_closed, 'unsolicited idle response closes connection');
    is_deeply(\@event, [ 'complete' ],
        'completed transaction is not retroactively failed');

    my $ok = eval {
        $client->request(request('/two'));
        1;
    };
    ok(!$ok, 'closed poisoned connection cannot accept a later request');
    like($@, qr/connection is closed/,
        'later request failure is explicit');
};

subtest 'idle CRLF keepalive noise can be discarded' => sub {
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        request('/one'),
        on_error => sub { die "unexpected first request error: $_[1]" },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 204 No Content\r\n\r\n"
    );

    ok($tx->is_complete, 'first transaction completes');
    $client->input("\r\n\r\n");
    ok(!$client->is_closed, 'CRLF-only idle bytes are discarded');

    my $second = $client->request(
        request('/two'),
        on_error => sub { die "unexpected second request error: $_[1]" },
    );
    like($client->output, qr/\AGET \/two HTTP\/1\.1\r\n/,
        'connection remains usable after idle CRLF discard');
    ok(!$second->is_terminal, 'second transaction remains active');
};

done_testing;
