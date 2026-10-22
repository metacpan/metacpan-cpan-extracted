use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::UnblockHTTP2 qw(pump_until_idle);
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;
use Unblock::HTTP2::_nghttp2;

for my $native (0, 1) {
    subtest "multiplexed receive modes, native=$native" => sub {
        my (%tx, %events, %data);
        my $server = Unblock::HTTP2::Server->new(
            receive_body => 'buffered', max_buffered_body_bytes => 3,
            on_request => sub {
                my ($t, $r) = @_;
                my $path = $r->target;
                $tx{$path} = $t;
                push @{$events{$path}}, 'headers';
                $t->on_finish(sub { push @{$events{$path}}, 'finish:' . $_[0]->state });
                if ($path eq '/stream') {
                    $t->on_data(sub {
                        is $_[0], $t, 'same real transaction';
                        $data{$path} .= $_[1];
                        ok !exists $_[0]{receive_chunks}, 'stream has no accumulator';
                    });
                }
                if ($path eq '/cancel') { $t->cancel; push @{$events{$path}}, 'returned' }
            },
            on_request_end => sub {
                my ($t, $r) = @_;
                my $path = $r->target;
                ok $r->is_complete && !$r->is_mutable, 'complete frozen request';
                is $t, $tx{$path}, 'original transaction';
                is $r, $tx{$path}->request, 'original message';
                if ($path eq '/stream') { is $data{$path}, 'abcdef', 'stream exceeds buffer limit without buffering' }
                else { is $r->body, $path eq '/empty' ? '' : 'abc', 'buffer installed before completion' }
                push @{$events{$path}}, 'end';
                $t->respond(status => 200, body => 'ok');
            },
            on_error => sub { push @{$events{$_[0]->request->target}}, 'error'; die 'error observer' },
        );
        my $client = Unblock::HTTP2::Client->new(receive_body => 'buffered');
        my ($cd, $sd) = $native ? map { Unblock::HTTP2::_nghttp2::NativeDriver->new($_) } ($client, $server) : ();
        my $pump = sub {
            return pump_until_idle($client, $server) unless $native;
            for (1..1000) {
                my $moved = 0;
                for my $pair ([$cd,$sd], [$sd,$cd]) {
                    my ($from,$to)=@$pair;
                    next unless $from->want_write;
                    my ($status,$wire,$n)=$from->drain;
                    next unless $n;
                    # Feed fragmented native buffers, not a Perl-only shortcut.
                    for my $part (substr($wire,0,1),substr($wire,1)) {
                        next unless length $part;
                        $to->feed($part);
                    }
                    $moved += $n;
                }
                return unless $moved;
            }
            die 'native pair did not idle';
        };
        $pump->();
        my %client_tx;
        for my $path (qw(/buffer /stream /overflow /empty /cancel)) {
            $client_tx{$path} = $client->request(method => 'POST', target => $path,
                scheme => 'https', authority => 'test',
                body => $path eq '/empty' ? '' : $path eq '/stream' ? 'abcdef' : $path eq '/overflow' ? 'abcd' : 'abc',
                on_finish => sub { push @{$events{"client$path"}}, $_[0]->state },
                on_complete => sub { is $_[0]->response->body, 'ok', 'client buffer complete' },
            );
        }
        $pump->();
        for my $path (qw(/buffer /stream /empty)) {
            is_deeply $events{$path}, ['headers','end','finish:complete'], "$path completion order";
            is_deeply $events{"client$path"}, ['complete'], 'client finishes once';
        }
        is_deeply $events{'/overflow'}, ['headers','error','finish:error'], 'overflow isolated and notified';
        ok !exists $tx{'/overflow'}{receive_chunks}, 'overflow buffer released';
        is_deeply $events{'/cancel'}, ['headers','returned','finish:cancelled'], 'cancellation deferred until callback returns';
        ok !$server->is_closed && !$client->is_closed, 'other streams and connection survive';
    };
}

subtest 'fragmented body and cancellation during data' => sub {
    my ($tx,@events);
    my $server = Unblock::HTTP2::Server->new(receive_body => 'buffered', max_buffered_body_bytes => 3,
        on_request => sub {
            $tx=$_[0];
            $tx->on_finish(sub { push @events, 'finish' });
            $tx->on_data(sub { $_[0]->cancel; push @events, 'data-return' });
        },
        on_request_end => sub { fail 'cancelled request cannot complete' },
    );
    my $client = Unblock::HTTP2::Client->new;
    my $ct=$client->request(method=>'POST',target=>'/',scheme=>'https',authority=>'test',stream_body=>1);
    pump_until_idle($client,$server);
    $ct->write('a');
    pump_until_idle($client,$server);
    is_deeply \@events, ['data-return','finish'], 'data cancellation order';
    $tx->cancel;
    is scalar(@events), 2, 'no duplicate finish';
};


subtest 'fragmented buffered request, trailers, and transport failure cleanup' => sub {
    for my $fail (0, 1) {
        my ($tx,@events);
        my $server = Unblock::HTTP2::Server->new(receive_body=>'buffered',max_buffered_body_bytes=>3,
            on_request=>sub { $tx=$_[0]; $tx->on_finish(sub { push @events,$_[0]->state }) },
            on_request_end=>sub {
                is($_[1]->body,'abc','fragmented buffer installed');
                is($_[1]->trailer('x-end'),'yes','trailer preserved');
                push @events,'end'; $_[0]->respond(status=>204);
            },
            on_error=>sub { push @events,'error'; die 'error observer' },
        );
        my $client=Unblock::HTTP2::Client->new;
        my $ct=$client->request(method=>'POST',target=>'/',scheme=>'https',authority=>'test',stream_body=>1);
        pump_until_idle($client,$server);
        $ct->write('a');
        pump_until_idle($client,$server);
        eval { $tx->on_data(sub {}) };
        like($@,qr/already started/,'late stream selection rejected');
        if ($fail) {
            $server->transport_error('lost transport');
            is_deeply(\@events,[qw(error error)],'error callback and terminal observer run');
        } else {
            $ct->request->add_trailer('x-end'=>'yes');
            $ct->end('bc');
            pump_until_idle($client,$server);
            is_deeply(\@events,[qw(end complete)],'successful trailer completion');
        }
        ok(!exists $tx->{receive_chunks},'receive chunks released');
    }
};

done_testing;
