use strict;
use warnings;
use Test::More;
use Unblock::HTTP1::Server;
use Unblock::HTTP1::Client;

{
    package OwnershipHost;
    sub new { bless { writes => [], block => 1 }, shift }
    sub unblock_send { push @{ $_[0]{writes} }, $_[1]; return !$_[0]{block} }
    sub unblock_finish { $_[0]{finished}++ }
    sub unblock_abort { die $_[1] }
}
my $get = "GET / HTTP/1.1\r\nHost: host.test\r\n\r\n";
my $ok = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n";

subtest 'retained server transactions do not own serialized payloads' => sub {
    my $host = OwnershipHost->new;
    my (@tx, @finish);
    my $body = 'a' x 262144;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            my ($tx) = @_;
            push @tx, $tx;
            $tx->on_finish(sub { push @finish, $_[0]->state });
            $tx->respond(status => 200, body => $body);
        },
    );
    $server->input($get);
    $body = 'b' x 262144;
    $server->input($get . $get);
    is(scalar @{ $host->{writes} }, 1, 'congested host receives no second send');
    is_deeply(\@finish, ['complete'], 'queued responses wait for host acceptance');
    ok(!exists $_->{send_plan}{wire}, 'wire payload ownership left transaction') for @tx;
    is($tx[0]->response->body, 'a' x 262144, 'first canonical body retained');
    is($tx[1]->response->body, 'b' x 262144, 'queued canonical body retained');
    $host->{block} = 0;
    $server->resume_output;
    is_deeply(\@finish, [('complete') x 3], 'queued terminal notifications exactly once');
    is(scalar @{ $host->{writes} }, 2, 'queued pipeline coalesced in one send');
    my $head = "HTTP/1.1 200 OK\r\nContent-Length: 262144\r\n\r\n";
    is(join('', @{ $host->{writes} }),
        $head . ('a' x 262144) . ($head . ('b' x 262144)) x 2,
        'all serialized bytes remain in request order');
};

subtest 'client dispatch transfers wire while queued requests keep their body' => sub {
    my $host = OwnershipHost->new;
    my $client = Unblock::HTTP1::Client->new(transport => $host);
    my $body = 'c' x 262144;
    my @tx = map { $client->request(method => 'POST', target => '/',
        headers => [['Host', 'host.test']], body => $body) } 1 .. 2;
    $body = 'changed';
    ok(!exists $tx[0]{send_plan}{wire}, 'dispatched client wire no longer retained');
    ok(!defined $tx[1]{send_plan}, 'queued request has no premature serialization');
    $client->input($ok);
    ok(!exists $tx[1]{send_plan}{wire}, 'next dispatch transfers serialization');
    is(scalar @{ $host->{writes} }, 1, 'next request waits through output congestion');
    $host->{block} = 0;
    $client->resume_output;
    $client->input($ok);
    ok($_->is_complete, 'retained client transaction complete') for @tx;
    is($_->request->body, 'c' x 262144, 'canonical request body retained') for @tx;
    is(join('', @{ $host->{writes} }),
        ("POST / HTTP/1.1\r\nHost: host.test\r\nContent-Length: 262144\r\n\r\n" . ('c' x 262144)) x 2,
        'each queued request emitted exactly once');
};

subtest 'streaming output takes a value snapshot before caller mutation' => sub {
    my $tx;
    my $server = Unblock::HTTP1::Server->new(on_request => sub {
        ($tx) = @_;
        $tx->respond(status => 200, headers => [['Content-Length', '6']], stream_body => 1);
    });
    $server->input($get);
    like($server->output, qr/Content-Length: 6\r\n\r\n\z/, 'drain initial headers');
    my $bytes = 'abc';
    $tx->write($bytes);
    substr($bytes, 0, 1) = 'x';
    $tx->end($bytes);
    is($server->output, 'abcxbc', 'empty-queue assignment and append preserve snapshots');
    ok($tx->is_complete, 'stream framing state survives wire transfer');
};

done_testing;
