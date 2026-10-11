use strict;
use warnings;
use Test::More;

use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

{
    package Local::HTTP2::Host;

    sub new {
        return bless {
            queue     => [],
            calls     => 0,
            paused    => 0,
            finish    => 0,
            aborted   => [],
        }, shift;
    }

    sub unblock_send {
        my ($self, $bytes) = @_;
        die 'empty wire write' unless length $bytes;
        push @{ $self->{queue} }, $bytes;
        ++$self->{calls};
        if ($self->{pause_once}) {
            delete $self->{pause_once};
            $self->{paused} = 1;
            return 0;  # Entire buffer accepted, but host now congested.
        }
        return;         # No congestion information.
    }

    sub unblock_finish { ++$_[0]{finish}; return }
    sub unblock_abort  { push @{ $_[0]{aborted} }, $_[1]; return }
}

sub transfer {
    my ($host, $peer) = @_;
    my @buffers = splice @{ $host->{queue} };
    $peer->input($_) for @buffers;
    return scalar @buffers;
}

sub pump_idle {
    my ($client, $client_host, $server, $server_host) = @_;
    for (1 .. 1000) {
        my $count = transfer($client_host, $server);
        $count += transfer($server_host, $client);
        return unless $count;
    }
    die 'attached transport pair never became idle';
}

my $client_host = Local::HTTP2::Host->new;
my $server_host = Local::HTTP2::Host->new;
my @requests;
my @errors;
my $server = Unblock::HTTP2::Server->new(
    transport => $server_host,
    on_request => sub {
        my ($tx, $request) = @_;
        push @requests, [ $tx, $request->target ];
    },
    on_error => sub {
        my ($tx, $error) = @_;
        push @errors, "server: $error";
    },
);
my $client = Unblock::HTTP2::Client->new(transport => $client_host);

ok @{ $client_host->{queue} }, 'client constructor sends preface automatically';
ok @{ $server_host->{queue} }, 'server constructor sends settings automatically';
my (%body, %done, %status, @informational);

for my $target ('/first', '/second') {
    $client->request(
        method => 'GET', target => $target,
        scheme => 'https', authority => 'example.test',
        on_response => sub {
            my ($tx, $response) = @_;
            $status{$target} = $response->status;
        },
        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            $body{$target} .= $bytes;
        },
        on_complete => sub { ++$done{$target} },
        on_error => sub {
            my ($tx, $error) = @_;
            push @errors, "client: $error";
        },
        on_informational => sub {
            my ($tx, $response) = @_;
            push @informational, $response->status;
        },
    );
}

pump_idle($client, $client_host, $server, $server_host);
is scalar @requests, 2, 'two concurrent requests reach server with attached transport';
is_deeply [ sort map { $_->[1] } @requests ],
    [qw(/first /second)], 'both request targets decoded';
is scalar keys %done, 0, 'responses can be deferred outside input callback';

$requests[1][0]->send_informational(status => 103);
$requests[1][0]->respond(status => 200, body => 'second-response');
$requests[0][0]->respond(status => 201, body => 'first-response');

ok @{ $server_host->{queue} },
    'later response automatically sends without another read event';
pump_idle($client, $client_host, $server, $server_host);

is $status{'/first'}, 201, 'first stream status preserved';
is $status{'/second'}, 200, 'second stream status preserved';
is $body{'/first'}, 'first-response', 'first stream body preserved';
is $body{'/second'}, 'second-response', 'second stream body preserved';
is_deeply \@informational, [103], 'named-field informational response arrives';
is $done{'/first'}, 1, 'first stream completed';
is $done{'/second'}, 1, 'second stream completed';
is_deeply \@errors, [], 'no application errors';

{
    my $host = Local::HTTP2::Host->new;
    $host->{pause_once} = 1;
    my $slow = Unblock::HTTP2::Client->new(transport => $host);
    ok $host->{paused}, 'host pauses after fully accepting first buffer';
    my $first_count = $host->{calls};

    my $drained = 0;
    my $stream = $slow->request(
        method => 'POST', target => '/',
        scheme => 'https', authority => 'example.test',
        stream_body => 1,
        on_drain => sub { ++$drained },
    );
    is $stream->write('queued-body'), 0,
        'stream write reports blocked attached host after accepting bytes';
    is $host->{calls}, $first_count,
        'blocked host receives no more buffers before resume_output';
    $slow->resume_output;
    ok $host->{calls} > $first_count,
        'resume_output flushes protocol output that was left in nghttp2';
    ok $drained, 'producer is notified when host congestion clears';
    is scalar @{ $host->{aborted} }, 0, 'host was not aborted by congestion';
    $slow->close;
    is $host->{finish}, 1, 'graceful close finishes host after queued output';
    $slow->input_eof;
    is $host->{finish}, 1, 'EOF after close does not finish twice';
}

{
    my $host = Local::HTTP2::Host->new;
    my $engine = Unblock::HTTP2::Client->new(transport => $host);
    my $manual = eval { $engine->output; 1 };
    ok !$manual, 'manual output cannot steal an attached host buffer';
    like $@, qr/attached transport/, 'manual output error explains ownership';

    $engine->transport_error('socket broken');
    is scalar @{ $host->{aborted} }, 1, 'transport error aborts host once';
    ok $engine->is_closed, 'transport error closes connection';
    $engine->transport_error('socket broken again');
    is scalar @{ $host->{aborted} }, 1, 'transport error is idempotent';
}

done_testing;
