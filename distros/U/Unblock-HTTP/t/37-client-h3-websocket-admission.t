use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Unblock::WebSocket::Handshake; 1 }
        or plan skip_all => 'Unblock::WebSocket handshake is required';
}
use Unblock::HTTP::Client;

{
    package Local::H3SettingsHost;
    sub new { bless {}, shift }
    sub closed { 0 }
}
{
    package Local::H3SettingsEngine;
    sub new {
        bless {
            received => 0,
            enabled  => 0,
            requests => 0,
        }, shift;
    }
    sub failed { 0 }
    sub shutdown_started { 0 }
    sub remote_shutdown_id { undef }
    sub peer_settings_received { $_[0]{received} }
    sub peer_extended_connect_enabled { $_[0]{enabled} }
    sub request { ++$_[0]{requests}; return undef }
}
sub setup {
    my (@deferred, @errors, @finished, $connect_count, $cancel_count);
    my $client = Unblock::HTTP::Client->new(
        http3 => { websocket => 1 },
        max_connections_per_origin => 1,
        connect_quic => sub {
            ++$connect_count;
            return sub { ++$cancel_count };
        },
        defer => sub { push @deferred, $_[0] },
    );
    my $op = $client->connect_websocket(
        url => 'wss://example.test/settings', http_version => '3',
        on_error => sub { push @errors, $_[1] },
        on_finish => sub { push @finished, $_[0]->state },
    );
    my $pool = $op->{origin};
    $client->_abandon_connect($pool, $op);
    $op->{state} = 'queued';
    my $engine = Local::H3SettingsEngine->new;
    my $conn = {
        protocol => 'h3',
        host => Local::H3SettingsHost->new,
        engine => $engine,
        active => 0,
        credit_blocked => 0,
    };
    push @{ $pool->{connections} }, $conn;
    return ($client, $pool, $conn, $engine, $op,
        \@deferred, \@errors, \@finished, $connect_count);
}

{
    my ($client, $pool, $conn, $engine, $op,
        $later, $errors, $finished, $connected) = setup();
    $client->_pump($pool);
    is($op->state, 'queued', 'H3 CONNECT waits for initial peer SETTINGS');
    is($engine->{requests}, 0, 'cannot dispatch H3 CONNECT before SETTINGS');
    is($connected, 1, 'waiting does not open a second QUIC connection');
    is($client->pending_count, 1, 'pending operation retained while waiting');
    $engine->{received} = 1;
    $engine->{enabled} = 0;
    $client->_pump($pool);
    is($op->state, 'error', 'unsupported peer fails unsent H3 WebSocket');
    like($op->error, qr/peer has not enabled HTTP\/3 WebSocket Extended CONNECT/,
        'unsupported capability reported without fallback');
    is($engine->{requests}, 0, 'unsupported peer never receives CONNECT');
    is(scalar @$errors, 1, 'unsupported peer invokes on_error once');
    is_deeply($finished, ['error'], 'unsupported peer finishes once');
    is($client->pending_count, 0, 'failure removes pending admission');
}
{
    my ($client, $pool, $conn, $engine, $op,
        $later, $errors, $finished, $connected) = setup();
    $engine->{received} = 1;
    $engine->{enabled} = 1;
    $client->_pump($pool);
    is($engine->{requests}, 1, 'eligible H3 CONNECT attempts same request');
    is($op->state, 'queued', 'credit-blocked CONNECT returns to pending queue');
    is($conn->{credit_blocked}, 1, 'H3 stream-credit exhaustion is recorded');
    ok(!$op->transaction, 'credit exhaustion did not create a transaction');
    is($client->pending_count, 1, 'one unsent operation retained');
    $client->_pump($pool);
    is($engine->{requests}, 1, 'credit-blocked connection does not spin');
    is($connected, 1, 'credit exhaustion does not create another socket');
    $conn->{credit_blocked} = 0;
    $client->_pump($pool);
    is($engine->{requests}, 2, 'credit wakeup retries the original operation');
    is($client->pending_count, 1, 'failed second admission still pending');
    ok($op->cancel, 'cancel outstanding unsent H3 WebSocket');
    is($op->state, 'cancelled', 'cancelled H3 WebSocket is terminal');
    is($client->pending_count, 0, 'cancel releases pending queue slot');
    is_deeply($finished, ['cancelled'], 'cancellation callback fires once');
    is_deeply($errors, [], 'intentional cancellation has no error callback');
}

done_testing;
