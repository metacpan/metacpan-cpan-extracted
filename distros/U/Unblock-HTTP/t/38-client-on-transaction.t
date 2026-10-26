use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Unblock::HTTP::Client;

{ package AdmissionHost;
  sub new { bless { wire => '', aborted => 0 }, shift }
  sub unblock_send { $_[0]{wire} .= $_[1]; 1 }
  sub unblock_finish { }
  sub unblock_abort { ++$_[0]{aborted} }
}

sub fixture {
    my (@queue, $ready);
    my $host = AdmissionHost->new;
    my $client = Unblock::HTTP::Client->new(http1 => {},
        max_connections_per_origin => 1,
        defer => sub { push @queue, $_[0] },
        connect_stream => sub { $ready = $_[2] });
    return ($client, $host, sub { $ready->(transport => $host) },
        sub { my $budget = 20; while (@queue) { die 'defer loop' unless $budget--; shift(@queue)->() } });
}

subtest 'queued streamed body uses real assigned transaction exactly once' => sub {
    my ($client, $host, $connect, $flush) = fixture();
    my (@admitted, @finished, $op);
    $op = $client->request(url => 'http://example.test/', method => 'POST', stream_body => 1,
        on_transaction => sub {
            my ($tx) = @_;
            is(refaddr($tx), refaddr($op->transaction), 'operation already has same transaction');
            push @admitted, $tx;
            $tx->write('one');
            $tx->end('two');
        },
        on_finish => sub { push @finished, $_[0] },
    );
    is_deeply(\@admitted, [], 'nothing called before connection');
    my $engine = $connect->();
    is(scalar(@admitted), 1, 'one admission');
    like($host->{wire}, qr/3\r\none\r\n3\r\ntwo\r\n0\r\n\r\n\z/, 'streamed body sent once');
    $engine->input("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n");
    $flush->();
    is($op->state, 'complete', 'request completed');
    is_deeply(\@finished, \@admitted, 'same terminal transaction');
    $client->shutdown;
};

subtest 'queued cancellation never admits' => sub {
    my ($client, $host, $connect, $flush) = fixture();
    my $calls = 0;
    my $op = $client->request(url => 'http://example.test/',
        on_transaction => sub { ++$calls });
    $op->cancel;
    $connect->();
    $flush->();
    is($calls, 0, 'cancelled queue has no transaction notification');
    is($host->{wire}, '', 'no request transmitted');
    $client->shutdown;
};

for my $action ('cancel', 'throw') {
    subtest "admission $action cleans up once" => sub {
        my ($client, $host, $connect, $flush) = fixture();
        my (@error, @finish, $op);
        $op = $client->request(url => 'http://example.test/', stream_body => 1,
            on_transaction => sub {
                die "producer failed\n" if $action eq 'throw';
                $op->cancel;
            },
            on_error => sub { push @error, [@_] },
            on_finish => sub { push @finish, $_[0] },
        );
        $connect->();
        $flush->();
        is($op->state, $action eq 'throw' ? 'error' : 'cancelled', 'operation terminal state');
        is(scalar(@finish), 1, 'one terminal callback');
        is(refaddr($finish[0]), refaddr($op->transaction), 'terminal receives actual transaction');
        is(scalar(@error), $action eq 'throw' ? 1 : 0, 'error count');
        like($op->error, qr/producer failed/, 'exception preserved') if $action eq 'throw';
        is($client->pool_stats->{active}, 0, 'active operation removed');
        $client->shutdown;
    };
}
done_testing;
