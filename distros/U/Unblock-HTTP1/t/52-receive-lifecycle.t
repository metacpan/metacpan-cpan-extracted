use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;
use Unblock::HTTP1::_Native;

sub feed {
    my ($server, $native, $wire) = @_;
    return $server->input($wire) unless $native;
    return Unblock::HTTP1::_Native::_borrowed_input_once($server, $wire);
}

for my $native (0, 1) {
    for my $framing ('fixed', 'chunked', 'empty', 'none') {
        for my $stream (0, 1) {
            subtest "native=$native framing=$framing stream=$stream" => sub {
                my (@events, $tx, $request, $data);
                my $server = Unblock::HTTP1::Server->new(
                    receive_body => 'buffered', max_buffered_body_bytes => 3,
                    on_request => sub {
                        ($tx, $request) = @_;
                        push @events, 'headers';
                        $tx->on_finish(sub {
                            is $_[0], $tx, 'same terminal transaction';
                            is $_[0]->state, 'complete', 'committed terminal state';
                            push @events, 'finish';
                            $_[0]->cancel;
                        });
                        $tx->on_data(sub {
                            is $_[0], $tx, 'same data transaction';
                            $data .= $_[1];
                            push @events, 'data';
                        }) if $stream;
                    },
                    on_request_end => sub {
                        is refaddr($_[1]), refaddr($request), 'same message';
                        ok $_[1]->is_complete, 'complete before callback';
                        ok !$_[1]->is_mutable, 'frozen before callback';
                        my $body = $framing =~ /fixed|chunked/ ? 'abc' : '';
                        is $_[1]->body, $body, 'buffer installed' unless $stream;
                        is $data || '', $body, 'stream delivered' if $stream;
                        is $_[1]->trailer('X-End'), 'yes', 'trailers retained'
                            if $framing eq 'chunked';
                        push @events, 'end';
                        $_[0]->respond(status => 200, body => 'ok');
                        push @events, 'responded';
                    },
                );
                my $head = "POST / HTTP/1.1\r\nHost: test\r\n";
                my $tail = '';
                if ($framing eq 'fixed') { $head .= "Content-Length: 3\r\n"; $tail = 'abc' }
                elsif ($framing eq 'chunked') { $head .= "Transfer-Encoding: chunked\r\n"; $tail = "3\r\nabc\r\n0\r\nX-End: yes\r\n\r\n" }
                elsif ($framing eq 'empty') { $head .= "Content-Length: 0\r\n" }
                feed($server, $native, $head . "\r\n" . $tail);
                is_deeply \@events, ['headers', ($stream && length($tail) ? 'data' : ()), 'end', 'responded', 'finish'], 'callback order';
                ok !exists $tx->{receive_chunks}, 'accumulator released';
                eval { $tx->on_finish(sub {}) };
                like $@, qr/terminal/, 'late finish registration rejected';
            };
        }
    }
}

subtest 'fragmentation, bounded overflow, and throwing error observer' => sub {
    for my $overflow (0, 1) {
        my ($tx, @events);
        my $server = Unblock::HTTP1::Server->new(
            receive_body => 'buffered', max_buffered_body_bytes => 3,
            on_request => sub {
                $tx = $_[0];
                $tx->on_finish(sub { push @events, $_[0]->state });
            },
            on_request_end => sub { push @events, 'end'; $_[0]->respond(status => 204) },
            on_error => sub { push @events, 'error'; die 'observer failed' },
        );
        $server->input("POST / HTTP/1.1\r\nHost: test\r\nContent-Length: " . ($overflow ? 4 : 3) . "\r\n\r\na");
        eval { $tx->on_data(sub {}) };
        like $@, qr/already started/, 'late data registration rejected';
        $server->input('b');
        $server->input($overflow ? 'cd' : 'c');
        is_deeply \@events, $overflow ? ['error', 'error'] : ['end', 'complete'], 'overflow has error and finish, no success';
        ok !exists $tx->{receive_chunks}, 'no retained accumulator';
        ok $server->is_closed, 'overflow closes connection' if $overflow;
    }
};

for my $where ('headers', 'data', 'end') {
    subtest "cancel during $where" => sub {
        my (@events, $tx);
        my $server = Unblock::HTTP1::Server->new(
            receive_body => 'buffered',
            on_request => sub {
                $tx = $_[0];
                $tx->on_finish(sub { push @events, 'finish'; is $_[0]->state, 'cancelled', 'cancelled state' });
                if ($where eq 'headers') { $tx->cancel; push @events, 'headers_return' }
                $tx->on_data(sub { $_[0]->cancel; push @events, 'data_return' }) if $where eq 'data';
            },
            on_request_end => sub { $_[0]->cancel; push @events, 'end_return' },
            on_error => sub { fail 'cancel is not error' },
        );
        $server->input("POST / HTTP/1.1\r\nHost: test\r\nContent-Length: 1\r\n\r\nx");
        $tx->cancel;
        is_deeply \@events, ["${where}_return", 'finish'], 'finish after callback unwinds, exactly once';
    };
}

subtest 'client buffering and synchronous registration' => sub {
    my (@events, $tx);
    my $client = Unblock::HTTP1::Client->new(receive_body => 'buffered', max_buffered_body_bytes => 3);
    $tx = $client->request(method => 'GET', target => '/', authority => 'test',
        on_response => sub { push @events, 'headers' },
        on_complete => sub { is $_[0]->response->body, 'abc', 'buffered client response'; push @events, 'complete'; die 'complete observer failed' },
        on_finish => sub { push @events, 'finish' },
    );
    $client->input("HTTP/1.1 404 Not Found\r\nContent-Length: 3\r\n\r\nab");
    $client->input('c');
    is_deeply \@events, [qw(headers complete finish)], 'finish survives completion exception';
    ok $tx->is_complete, '404 is successful HTTP exchange';
};

subtest 'truncation releases retained body' => sub {
    my ($tx, @events);
    my $server = Unblock::HTTP1::Server->new(receive_body => 'buffered',
        on_request => sub { $tx = $_[0]; $tx->on_finish(sub { push @events, 'finish' }) },
        on_request_end => sub { fail 'truncated request must not complete' },
        on_error => sub { push @events, 'error' },
    );
    $server->input("POST / HTTP/1.1\r\nHost: test\r\nContent-Length: 2\r\n\r\na");
    $server->input_eof;
    is_deeply \@events, [qw(error finish)], 'error before finish';
    ok !exists $tx->{receive_chunks}, 'truncated buffer released';
};


subtest 'queued cancellation finishes both affected client transactions' => sub {
    my @events;
    my $client=Unblock::HTTP1::Client->new;
    my $active=$client->request(method=>'GET',target=>'/',authority=>'test',
        on_error=>sub { push @events,'active-error' },
        on_finish=>sub { push @events,'active-finish' });
    my $queued=$client->request(method=>'GET',target=>'/next',authority=>'test',
        on_error=>sub { fail 'intentional cancel is not an error' },
        on_finish=>sub { push @events,'queued-finish' });
    $queued->cancel;
    ok($active->is_error,'active request fails when its connection is cancelled');
    ok($queued->is_cancelled,'queued request remains cancelled');
    is_deeply(\@events,[qw(active-error active-finish queued-finish)],'all affected transactions notified once');
};

subtest 'attached server cancellation does not call on_error' => sub {
    package CancelTestHost;
    sub unblock_send { 1 }
    sub unblock_finish { }
    sub unblock_abort { $_[0]{aborted}++ }
    package main;
    my $host=bless {},'CancelTestHost';
    my @events;
    my $server=Unblock::HTTP1::Server->new(transport=>$host,
        on_request=>sub { $_[0]->on_finish(sub { push @events,'finish' }); $_[0]->cancel; push @events,'returned' },
        on_error=>sub { fail 'cancel must not report transport error' },
    );
    $server->input("GET / HTTP/1.1\r\nHost: test\r\n\r\n");
    is_deeply(\@events,[qw(returned finish)],'attached cancel finishes after callback');
    is($host->{aborted},1,'host aborted once');
};

done_testing;
