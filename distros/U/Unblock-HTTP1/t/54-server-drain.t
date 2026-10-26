use strict;
use warnings;
use Test::More;
use Unblock::HTTP1::Server;
use Unblock::HTTP1::_Native;

{
    package DrainHost;
    sub new { bless { wire => '', finished => 0, aborted => 0 }, shift }
    sub unblock_send { $_[0]{wire} .= $_[1]; return !$_[0]{blocked} }
    sub unblock_finish { ++$_[0]{finished}; $_[0]{on_finish}->() if $_[0]{on_finish} }
    sub unblock_abort { ++$_[0]{aborted} }
}
my $get = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
for my $native (0, 1) {
    my $label = $native ? 'borrowed input' : 'portable input';
    subtest $label => sub {
        my $host = DrainHost->new;
        my ($server, $tx, @seen, @finish);
        $server = Unblock::HTTP1::Server->new(
            transport => $host, receive_body => 'buffered',
            on_request => sub {
                ($tx) = @_;
                push @seen, 'headers';
                $tx->on_finish(sub { push @finish, $_[0]->state });
                $server->drain->drain;
            },
            on_request_end => sub { push @seen, $_[1]->body },
        );
        my $driver = $native ? Unblock::HTTP1::_Native::BorrowedDriver->new($server) : undef;
        my $feed = sub { $native ? $driver->feed($_[0]) : $server->input($_[0]) };
        $feed->("POST / HTTP/1.1\r\nHost: localhost\r\nContent-Length: 4\r\n\r\nab");
        ok($server->want_read, 'draining admitted body still reads');
        is($host->{finished}, 0, 'does not finish partial body');
        $feed->('cd' . $get);
        is_deeply(\@seen, ['headers', 'abcd'], 'body completes, pipeline is not admitted');
        ok(!$server->want_read, 'no reads needed after admitted body');
        is($host->{finished}, 0, 'delayed response is retained');
        $host->{blocked} = 1;
        $tx->respond(status => 200, stream_body => 1);
        $tx->write('hello');
        $tx->end;
        is($host->{finished}, 0, 'queued body waits for output capacity');
        is_deeply(\@finish, [], 'terminal waits for accepted output');
        $host->{blocked} = 0;
        $server->resume_output;
        is($host->{finished}, 1, 'host finishes after all output is accepted');
        is_deeply(\@finish, ['complete'], 'application terminal observer preserved');
        like($host->{wire}, qr/5\r\nhello\r\n0\r\n\r\n\z/, 'no lost or replayed body');
        $server->drain->resume_output;
        is($host->{finished}, 1, 'drain is idempotent');
        is($host->{aborted}, 0, 'graceful drain does not abort');
    };
}

subtest 'idle and partially received headers finish immediately' => sub {
    for my $partial ('', 'GET / HTTP/1.1') {
        my $host = DrainHost->new;
        my $server = Unblock::HTTP1::Server->new(transport => $host,
            on_request => sub { fail('unadmitted request callback') });
        $server->input($partial) if length $partial;
        is($server->drain, $server, 'returns same engine');
        ok($server->is_closed, 'idle engine closes');
        is($host->{finished}, 1, 'idle host finishes once');
        $server->drain;
        is($host->{finished}, 1, 'repeated idle drain has no effect');
    }
};

subtest 'manual output and synchronous response stop at admitted request' => sub {
    my ($server, $count);
    $server = Unblock::HTTP1::Server->new(on_request => sub {
        ++$count;
        $server->drain;
        $_[0]->respond(status => 200, body => 'done');
    });
    $server->input($get . $get);
    is($count, 1, 'pipeline not admitted');
    ok($server->is_closed, 'manual engine closed');
    like($server->output, qr/done\z/, 'manual output remains available');
};

subtest 'host terminal notification during finish preserves accepted completion' => sub {
    my $host = DrainHost->new;
    my ($server, @finish);
    $server = Unblock::HTTP1::Server->new(transport => $host,
        on_request => sub {
            $_[0]->on_finish(sub { push @finish, $_[0]->state });
            $server->drain;
            $_[0]->respond(status => 200, body => 'accepted');
        });
    $host->{on_finish} = sub { $server->transport_error('host has closed') };
    $server->input($get);
    is_deeply(\@finish, ['complete'], 'completion precedes synchronous host teardown');
    is($host->{finished}, 1, 'finish only once');
};

done_testing;
