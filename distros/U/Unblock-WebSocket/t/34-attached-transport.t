use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;

{
    package Local::WebSocket::Host;

    sub new {
        return bless {
            queue => [], calls => 0, finished => 0, aborted => [],
        }, shift;
    }

    sub unblock_send {
        my ($self, $bytes) = @_;
        die "empty write" unless length $bytes;
        push @{ $self->{queue} }, $bytes;
        ++$self->{calls};
        if (delete $self->{pause_once}) {
            return 0;  # All bytes accepted, host now congested.
        }
        return;         # Fully accepted, no congestion information.
    }

    sub unblock_finish { ++$_[0]{finished}; return }
    sub unblock_abort  { push @{ $_[0]{aborted} }, $_[1]; return }

    sub take {
        my ($self) = @_;
        return join '', splice @{ $self->{queue} };
    }
}

my @backend = ('perl');
push @backend, 'native' if Unblock::WebSocket->native_available;

for my $backend (@backend) {
    subtest $backend => sub {
        my $host = Local::WebSocket::Host->new;
        my (@messages, @drain, @errors, @closes);
        my $server = Unblock::WebSocket::Server->new(
            backend   => $backend,
            transport => $host,
            on_message => sub {
                my ($ws, $message, $type) = @_;
                push @messages, "$type:$message";
                $ws->send_text("reply:$message");
            },
            on_drain => sub { push @drain, 'ready' },
            on_error => sub { push @errors, $_[1] },
            on_close => sub { push @closes, [ $_[1], $_[2] ] },
        );
        my @replies;
        my $client = Unblock::WebSocket::Client->new(
            backend => $backend,
            on_message => sub { push @replies, $_[1] },
        );

        my $manual = eval { $server->output; 1 };
        ok !$manual, 'manual output cannot steal attached bytes';
        like $@, qr/attached transport/, 'clear ownership error';

        $client->send_text('incoming');
        $server->input($client->output);
        is_deeply \@messages, [ 'text:incoming' ],
            'input callback handled without recursive output dispatch';
        ok $host->{calls}, 'input callback output was sent automatically';
        $client->input($host->take);
        is_deeply \@replies, ['reply:incoming'], 'message delivered exactly once';

        $server->send_text('later');
        ok $host->{calls} >= 2, 'delayed send flushes without another input';
        $client->input($host->take);
        is_deeply \@replies, ['reply:incoming', 'later'],
            'delayed output delivered once';

        $host->{pause_once} = 1;
        is $server->send_text('accepted'), 0,
            'false host send return blocks producer after acceptance';
        my $calls = $host->{calls};
        is $server->send_text('queued'), 0,
            'next message is accepted by WebSocket but remains queued';
        is $host->{calls}, $calls, 'no host writes during congestion';
        is scalar @drain, 0, 'no premature drain during congestion';

        $client->input($host->take);
        is_deeply \@replies, ['reply:incoming', 'later', 'accepted'],
            'fully accepted congested buffer is not replayed';
        $server->resume_output;
        cmp_ok $host->{calls}, '>', $calls, 'resume sends remaining output';
        is scalar @drain, 1, 'on_drain wakes blocked application producer';
        $client->input($host->take);
        is_deeply \@replies,
            ['reply:incoming', 'later', 'accepted', 'queued'],
            'remainder delivered exactly once and in order';

        ok $server->is_open, 'server is still open after backpressure';
        $server->close;
        is $host->{finished}, 0, 'local Close frame alone does not finish host';
        $client->input($host->take);
        $server->input($client->output);
        ok $server->close_received, 'received peer Close response';
        is $host->{finished}, 1, 'finished only after both Close directions';
        is scalar @closes, 1, 'Close callback fires once';
        $server->input_eof;
        is $host->{finished}, 1, 'EOF does not repeat finish';
        is_deeply \@errors, [], 'normal exchange has no transport errors';
        is scalar @{ $host->{aborted} }, 0, 'normal exchange never aborts';
    };

    subtest "$backend paused close" => sub {
        my $host = Local::WebSocket::Host->new;
        my $server = Unblock::WebSocket::Server->new(
            backend => $backend, transport => $host,
        );
        my $client = Unblock::WebSocket::Client->new(backend => $backend);
        $host->{pause_once} = 1;
        $server->close;
        is $host->{finished}, 0, 'paused host has not finished';
        $client->input($host->take);
        $server->input($client->output);
        is $host->{finished}, 0, 'Close reply does not bypass host congestion';
        $server->resume_output;
        is $host->{finished}, 1, 'resume allows graceful host finish';
    };

    subtest "$backend errors" => sub {
        my $host = Local::WebSocket::Host->new;
        my (@errors, @closes);
        my $ws = Unblock::WebSocket::Server->new(
            backend => $backend, transport => $host,
            on_error => sub { push @errors, $_[1] },
            on_close => sub { push @closes, [ $_[1], $_[2] ] },
        );
        $ws->transport_error('TLS failed');
        $ws->transport_error('again');
        ok $ws->is_closed, 'transport error closes engine';
        is scalar @{ $host->{aborted} }, 1, 'abort called exactly once';
        is scalar @errors, 1, 'transport error callback exactly once';
        is scalar @closes, 1, 'abnormal closure callback exactly once';

        my $host2 = Local::WebSocket::Host->new;
        my $ws2 = Unblock::WebSocket::Server->new(
            backend => $backend, transport => $host2,
        );
        $ws2->input_eof;
        ok $ws2->is_closed, 'unexpected EOF terminates engine';
        is scalar @{ $host2->{aborted} }, 1, 'unexpected EOF aborts host';
        is $host2->{finished}, 0, 'unexpected EOF is not a clean finish';

        my $host3 = Local::WebSocket::Host->new;
        my $ws3 = Unblock::WebSocket::Server->new(
            backend => $backend, transport => $host3,
        );
        {
            no warnings 'redefine';
            local *Local::WebSocket::Host::unblock_send = sub { die "write failed\n" };
            $ws3->send_text('one');
        }
        is scalar @{ $host3->{aborted} }, 1,
            'host write exception causes immediate abort';
        ok $ws3->is_closed, 'failed host write closes WebSocket';
    };

    subtest "$backend compressed" => sub {
        my $config = {
            client_no_context_takeover => 1,
            server_no_context_takeover => 1,
        };
        my $host = Local::WebSocket::Host->new;
        my $ws = Unblock::WebSocket::Server->new(
            backend => $backend, transport => $host,
            permessage_deflate => $config,
        );
        my @received;
        my $client = Unblock::WebSocket::Client->new(
            backend => $backend, permessage_deflate => $config,
            on_message => sub { push @received, $_[1] },
        );
        $ws->send_text('compressed' x 100);
        $client->input($host->take);
        is_deeply \@received, ['compressed' x 100],
            'attached output preserves compressed messages';
    };
}

{
    my $error = eval {
        Unblock::WebSocket::Server->new(transport => bless({}, 'Local::Missing'));
        1;
    };
    ok !$error, 'transport must implement host operations';
    like $@, qr/unblock_send/, 'constructor explains missing operation';

    my $manual = Unblock::WebSocket::Server->new(backend => 'perl');
    my $resumed = eval { $manual->resume_output; 1 };
    ok !$resumed, 'manual connection cannot resume attached output';
    like $@, qr/no attached transport/, 'manual resume error is explicit';
}

done_testing;
