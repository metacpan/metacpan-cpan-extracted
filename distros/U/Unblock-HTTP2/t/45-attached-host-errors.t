use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

{
    package Local::H2Host;
    sub new {
        my ($class, %opt) = @_;
        return bless {
            sent     => [],
            aborts   => [],
            finishes => 0,
            %opt,
        }, $class;
    }
    sub unblock_send {
        my ($self, $bytes) = @_;
        die "host output failure\n" if $self->{die_on_send};
        if (my $cb = $self->{during_send}) {
            $cb->($bytes);
        }
        push @{ $self->{sent} }, $bytes;
        if ($self->{pause_once}) {
            delete $self->{pause_once};
            return 0;
        }
        return;
    }
    sub unblock_finish { ++$_[0]{finishes}; return }
    sub unblock_abort  { push @{ $_[0]{aborts} }, $_[1]; return }
}

{
    my $host = Local::H2Host->new;
    my $client = Unblock::HTTP2::Client->new(transport => $host);
    @{ $host->{sent} } = ();

    $client->ping('12345678');
    ok @{ $host->{sent} }, 'ping automatically emits connection output';

    @{ $host->{sent} } = ();
    $client->update_settings(initial_window_size => 131_072);
    ok @{ $host->{sent} }, 'updated settings automatically emit output';

    @{ $host->{sent} } = ();
    $client->goaway(error_code => 0);
    ok @{ $host->{sent} }, 'GOAWAY automatically emits output';
    is scalar @{ $host->{aborts} }, 0,
        'ordinary HTTP/2 controls do not abort the host';

    $client->close;
    is $host->{finishes}, 1, 'explicit close gracefully finishes host';
    $client->close;
    is $host->{finishes}, 1, 'close after finish is idempotent';
}

{
    my $host = Local::H2Host->new(pause_once => 1);
    my $client = Unblock::HTTP2::Client->new(transport => $host);
    my $first = scalar @{ $host->{sent} };
    ok $first, 'preface accepted into host before pause';
    $client->close;
    is scalar @{ $host->{sent} }, $first,
        'close does not bypass the blocked host';
    is $host->{finishes}, 0,
        'host finish waits for resume after congestion';
    $client->resume_output;
    ok @{ $host->{sent} } >= $first,
        'resume preserves previously accepted wire output';
    is $host->{finishes}, 1,
        'graceful host finish occurs after pending output handoff';
    is_deeply $host->{aborts}, [], 'graceful close never aborts host';
}

{
    my $host = Local::H2Host->new(die_on_send => 1);
    my $client = Unblock::HTTP2::Client->new(transport => $host);
    ok $client->is_closed, 'send exception closes the engine';
    is scalar @{ $host->{aborts} }, 1,
        'send exception aborts the host exactly once';
    like $host->{aborts}[0], qr/host output failure/,
        'host exception reason is preserved';
    is $host->{finishes}, 0, 'send failure is not graceful finish';
    $client->transport_error('again');
    is scalar @{ $host->{aborts} }, 1,
        'transport error after abort never repeats the abort callback';
}

{
    my $host = Local::H2Host->new;
    my $client = Unblock::HTTP2::Client->new(transport => $host);
    my @errors;
    my $tx = $client->request(
        method => 'GET',
        scheme => 'https',
        authority => 'example.test',
        target => '/',
        on_error => sub { push @errors, $_[1] },
    );
    ok !$tx->is_terminal, 'active stream exists before read EOF';
    $client->input_eof;
    ok $tx->is_error, 'read EOF fails incomplete HTTP/2 stream';
    is scalar @errors, 1, 'read EOF delivers one transaction error';
    is $host->{finishes}, 1, 'clean read EOF finishes outgoing queue';
    $client->input_eof;
    is scalar @errors, 1, 'repeated read EOF does not fail twice';
}

{
    my $host = Local::H2Host->new;
    my $client = Unblock::HTTP2::Client->new(transport => $host);
    undef $host;
    $client->ping('12345678');
    ok $client->is_closed, 'missing weak host is treated as a transport error';
    like $client->close_reason, qr/transport was destroyed/,
        'missing host has an informative error';
}

{
    my $host = Local::H2Host->new;
    my $client;
    $host->{during_send} = sub {
        return unless $client;
        $client->input('not allowed while sending');
    };
    $client = Unblock::HTTP2::Client->new(transport => $host);
    $client->ping('12345678');
    ok $client->is_closed,
        'reentrant input from host send is rejected and closes session';
    is scalar @{ $host->{aborts} }, 1,
        'reentrant host send triggers immediate abort';
    like $host->{aborts}[0], qr/cannot be called from unblock_send/,
        'reentrant host failure reports the offending action';
}


{
    my $client_host = Local::H2Host->new;
    my $server_host = Local::H2Host->new;
    my $client = Unblock::HTTP2::Client->new(
        transport => $client_host,
        on_settings => sub { die "settings callback exploded\n" },
    );
    my $server = Unblock::HTTP2::Server->new(
        transport => $server_host,
    );
    for my $bytes (@{ $server_host->{sent} }) {
        last if $client->is_closed;
        $client->input($bytes);
    }

    ok $client->is_closed, 'control callback exception closes HTTP/2 session';
    is scalar @{ $client_host->{aborts} }, 1,
        'control callback exception aborts host immediately';
    is $client_host->{finishes}, 0,
        'control callback exception does not perform a graceful finish';
    like $client_host->{aborts}[0], qr/on_settings callback failed/,
        'fatal callback error includes the callback name';
    like $client_host->{aborts}[0], qr/settings callback exploded/,
        'fatal callback error preserves the original exception';
}

done_testing;
