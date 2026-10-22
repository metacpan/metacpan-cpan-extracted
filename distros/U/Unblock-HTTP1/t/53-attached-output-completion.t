use strict;
use warnings;
use Test::More;

use Unblock::HTTP1::Server;

{
    package OutputHost;
    sub new { my ($class, %args) = @_; bless { %args, writes => [], aborted => 0 }, $class }
    sub unblock_send {
        my ($self, $bytes) = @_;
        push @{ $self->{writes} }, $bytes;
        die "host hard output limit exceeded\n" if $self->{reject};
        return $self->{block} ? 0 : 1;
    }
    sub unblock_finish { $_[0]{finished}++ }
    sub unblock_abort { $_[0]{aborted}++; $_[0]{abort_reason} = $_[1] }
}

my $get = "GET /a HTTP/1.1\r\nHost: host.test\r\n\r\n";

subtest 'attached reject does not report a completed response' => sub {
    my $host = OutputHost->new(reject => 1);
    my (@finish, @errors, $tx);
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            ($tx) = @_;
            $tx->on_finish(sub { push @finish, [ $_[0]->state, $_[0]->error ] });
            $tx->respond(status => 200, body => 'hello');
        },
        on_error => sub { push @errors, $_[1] },
    );
    $server->input($get);
    is(scalar(@{ $host->{writes} }), 1, 'a host send was attempted');
    is($host->{aborted}, 1, 'rejecting host aborted once');
    is($tx->state, 'error', 'real transaction reports transport error');
    is(scalar(@finish), 1, 'transaction finishes exactly once');
    is($finish[0][0], 'error', 'on_finish sees failure, never premature success');
    like($finish[0][1], qr/hard output limit/, 'terminal error preserves host rejection');
    is(scalar(@errors), 1, 'connection reports one error');
};

subtest 'accepted but blocked bytes allow local completion' => sub {
    my $host = OutputHost->new(block => 1);
    my (@finish, $tx);
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            ($tx) = @_;
            $tx->on_finish(sub { push @finish, $_[0]->state });
            $tx->respond(status => 200, body => 'accepted');
        },
    );
    $server->input($get);
    is($tx->state, 'complete', 'false from host means accepted whole output');
    is_deeply(\@finish, ['complete'], 'accepted response terminal exactly once');
    is($host->{aborted}, 0, 'congestion is not host rejection');
    is(scalar(@{ $host->{writes} }), 1, 'only one accepted output send');
};

subtest 'attached pipelining retires only after host accepts each response' => sub {
    my $host = OutputHost->new;
    my (@respond, @finish);
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            my ($tx, $request) = @_;
            my $target = $request->target;
            push @respond, $target;
            $tx->on_finish(sub { push @finish, [ $target, $_[0]->state ] });
            $tx->respond(status => 200, body => $target);
        },
    );
    $server->input($get . "GET /b HTTP/1.1\r\nHost: host.test\r\n\r\n");
    is_deeply(\@respond, ['/a', '/b'], 'second pipelined request still dispatched');
    is_deeply(\@finish, [['/a', 'complete'], ['/b', 'complete']],
        'both accepted responses finish in order');
    is($host->{aborted}, 0, 'healthy pipelined output does not abort');
    like(join('', @{ $host->{writes} }), qr/\/a.*\/b/s,
        'responses serialized in original request order');
};

subtest 'manual output retains existing completion timing' => sub {
    my ($tx, @finish);
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            ($tx) = @_;
            $tx->on_finish(sub { push @finish, $_[0]->state });
            $tx->respond(status => 200, body => 'manual');
        },
    );
    $server->input($get);
    is_deeply(\@finish, ['complete'], 'manual output keeps existing lifecycle');
    like($server->output, qr/manual/, 'manual output contains response body');
};

done_testing;
