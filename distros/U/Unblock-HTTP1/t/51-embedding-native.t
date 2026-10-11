use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;
use Unblock::HTTP1::NativeABI;
use Unblock::HTTP1::_Native;

{
    package Local::NativeHost;
    sub new {
        bless { data => '', finished => 0, aborted => 0 }, $_[0];
    }
    sub unblock_send {
        my ($self, $data) = @_;
        $self->{data} .= $data;
        return;
    }
    sub unblock_finish { ++$_[0]{finished}; return }
    sub unblock_abort { ++$_[0]{aborted}; return }
}

subtest 'borrowed server input and host output use the same engine' => sub {
    my $host = Local::NativeHost->new;
    my $request;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            my ($tx, $req) = @_;
            $request = $req;
            $tx->respond(status => 200, body => 'native');
        },
    );
    my $driver = Unblock::HTTP1::_Native::BorrowedDriver->new($server);
    my $wire = "GET /native HTTP/1.1\r\nHost: example.test\r\n\r\n";
    my ($status, $used) = $driver->feed($wire);
    is($status, Unblock::HTTP1::NativeABI::INPUT_OK(),
        'borrowed server input accepted');
    is($used, length($wire), 'consumed full native input window');
    isa_ok($request, 'Uniform::HTTP::Request');
    is($request->target, '/native', 'native request target intact');
    like($host->{data}, qr/\AHTTP\/1\.1 200 OK\r\n/,
        'native read triggered automatic host output');
    like($host->{data}, qr/native\z/, 'native response body preserved');
};

subtest 'borrowed client response with named-fields request' => sub {
    my $host = Local::NativeHost->new;
    my $response;
    my $client = Unblock::HTTP1::Client->new(transport => $host);
    my $tx = $client->request(
        method => 'GET',
        target => '/',
        authority => 'example.test',
        on_response => sub { $response = $_[1] },
    );
    like($host->{data}, qr/\AGET \/ HTTP\/1\.1/,
        'named-fields request sent to host');
    my $driver = Unblock::HTTP1::_Native::BorrowedDriver->new($client);
    my $wire = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok";
    my ($status, $used) = $driver->feed($wire);
    is($status, Unblock::HTTP1::NativeABI::INPUT_OK(),
        'borrowed client input accepted');
    is($used, length($wire), 'consumed entire response');
    isa_ok($response, 'Uniform::HTTP::Response');
    ok($tx->is_complete, 'native client Transaction complete');
};

subtest 'native switch tail belongs to next consumer' => sub {
    my $host = Local::NativeHost->new;
    my ($tx, $notice);
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            ($tx) = @_;
            $tx->respond(
                status => 101,
                headers => [
                    [ Connection => 'Upgrade' ],
                    [ Upgrade => 'test-proto' ],
                ],
            );
        },
        on_switch => sub { ++$notice },
    );
    my $driver = Unblock::HTTP1::_Native::BorrowedDriver->new($server);
    my $wire = "GET / HTTP/1.1\r\nHost: example.test\r\n"
        . "Connection: Upgrade\r\nUpgrade: test-proto\r\n\r\nNEXT";
    my ($status, $used) = $driver->feed($wire);
    is($status, Unblock::HTTP1::NativeABI::INPUT_SWITCH(),
        'borrowed native input reports switch');
    is(substr($wire, $used), 'NEXT',
        'unconsumed native input tail is preserved');
    like($host->{data}, qr/HTTP\/1\.1 101 /,
        'server accepted upgrade handshake through host');
    is($notice, 1, 'switch callback fires once');
};

done_testing;
