use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Unblock::HTTP::Server;

BEGIN {
    eval { require Unblock::HTTP1::Client; require Unblock::HTTP2::Client; 1 }
        or plan skip_all => 'real HTTP1 and HTTP2 engines are required';
}

{
    package ReceiveTestHost;
    sub new { bless { output => '' }, shift }
    sub unblock_send { $_[0]{output} .= $_[1]; return 1 }
    sub unblock_finish { $_[0]{finished} = 1 }
    sub unblock_abort { $_[0]{aborted} = $_[1] }
}

for my $protocol ('http/1.1', 'h2') {
    for my $mode ('buffered', 'stream', 'empty', 'overflow', 'cancel') {
        subtest "$protocol $mode" => sub {
            my (@events, $tx, $request, $received);
            my $definition = Unblock::HTTP::Server->new(
                http1 => { max_buffered_body_bytes => 3 },
                http2 => { max_buffered_body_bytes => 3 },
                on_headers => sub {
                    ($tx, $request) = @_;
                    push @events, 'headers';
                    $tx->on_finish(sub { push @events, 'finish:' . $_[0]->state });
                    $tx->on_data(sub {
                        is(refaddr($_[0]), refaddr($tx), 'streaming keeps actual transaction');
                        $received .= $_[1];
                    }) if $mode eq 'stream';
                    $tx->cancel if $mode eq 'cancel';
                },
                on_request => sub {
                    my ($same_tx, $same_request) = @_;
                    is(refaddr($same_tx), refaddr($tx), 'transaction identity unchanged');
                    is(refaddr($same_request), refaddr($request), 'message identity unchanged');
                    ok($request->is_complete && !$request->is_mutable, 'completed frozen message');
                    if ($mode eq 'stream') {
                        is($received, 'abcdef', 'streamed body exceeds buffer cap');
                        ok(!$request->has_buffered_body, 'no full body accumulated');
                    } else {
                        is($request->body, $mode eq 'empty' ? '' : 'abc', 'complete engine-owned body');
                    }
                    push @events, 'request';
                    $tx->respond(status => 200, body => 'ok');
                    push @events, 'returned';
                },
                on_error => sub { push @events, 'error' },
            );
            my $host = ReceiveTestHost->new;
            my $server = $definition->attach_stream(transport => $host, protocol => $protocol);
            my $class = $protocol eq 'h2' ? 'Unblock::HTTP2::Client' : 'Unblock::HTTP1::Client';
            my $client = $class->new(receive_body => 'buffered');
            my $ct = $client->request(method => 'POST', target => '/', scheme => 'https', authority => 'test',
                body => $mode eq 'stream' ? 'abcdef' : $mode eq 'overflow' ? 'abcd' : $mode eq 'empty' ? '' : 'abc');
            for (1..100) {
                my $moved = 0;
                while ($client->want_write && !$server->is_closed) {
                    my $wire = $client->output;
                    last unless length $wire;
                    $server->input($wire);
                    $moved += length($wire);
                }
                if (length $host->{output}) {
                    my $wire = delete $host->{output};
                    $host->{output} = '';
                    $client->input($wire) unless $client->is_closed;
                    $moved += length($wire);
                }
                last unless $moved;
            }
            isa_ok($tx, $protocol eq 'h2' ? 'Unblock::HTTP2::Transaction' : 'Unblock::HTTP1::Transaction');
            if ($mode eq 'overflow') {
                is_deeply(\@events, [qw(headers error finish:error)], 'failed body skips application request');
            } elsif ($mode eq 'cancel') {
                is_deeply(\@events, [qw(headers finish:cancelled)], 'cancel is not an application error');
            } else {
                is_deeply(\@events, [qw(headers request returned finish:complete)], 'application callback sequence');
                is($ct->response->body, 'ok', 'response completed');
            }
        };
    }
}

done_testing;
