use strict;
use warnings;
use Test::More;
use jQluster::Server::WebSocket;
use Test::Requires {
    "Twiggy::Server" => "0",
    "AnyEvent::WebSocket::Client" => "0.20",
    "Net::EmptyPort" => "0",
};
use Twiggy::Server;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use Net::EmptyPort qw(empty_port);
use JSON qw(encode_json decode_json);


sub set_timeout {
    my ($timeout) = @_;
    $timeout ||= 10;
    my $w; $w = AnyEvent->timer(after => $timeout, cb => sub {
        undef $w;
        fail("Timeout");
        exit 1;
    });
}

sub create_server {
    my @logs = ();
    my $port = empty_port();
    my $server = Twiggy::Server->new(
        host => "127.0.0.1",
        port => $port,
    );
    my $app = jQluster::Server::WebSocket->new(
        logger => sub {
            push(@logs, \@_);
            note("$_[0]: $_[1]");
        }
    );
    $server->register_service($app->to_app);
    return ($port, $server, \@logs);
}

{
    my $next_id = 0;
    sub set_id {
        my ($msg) = @_;
        $msg->{message_id} = $next_id;
        $next_id++;
        return $msg;
    }
}

sub send_msg {
    my ($conn, $msg) = @_;
    $conn->send(encode_json($msg));
}

sub receive_msg_cv {
    my ($conn) = @_;
    my $cv_recv = AnyEvent->condvar;
    $conn->on(next_message => sub {
        my ($conn, $msg) = @_;
        $cv_recv->send($msg->body);
    });
    return $cv_recv;
}

sub create_connection {
    my ($port, $remote_node_id) = @_;
    my $conn = AnyEvent::WebSocket::Client->new->connect("ws://127.0.0.1:$port/")->recv;
    note("websocket connection for $remote_node_id established.");
    my $registration = set_id({
        from => $remote_node_id, message_type => "register",
        body => { remote_id => $remote_node_id }
    });
    my $cv_reply = receive_msg_cv($conn);
    send_msg($conn, $registration);
    my $reply_str = $cv_reply->recv;
    note("$remote_node_id: register reply message received");
    my $reply = decode_json($reply_str);
    delete $reply->{message_id};
    is_deeply $reply, {
        message_type => "register_reply",
        from => undef, to => $remote_node_id,
        body => { error => undef,
                  in_reply_to => $registration->{message_id} },
    }, "remote_node_id $remote_node_id: register_reply message OK";
    return $conn;
}


set_timeout;

{
    my ($port, $server, $logs) = create_server();
    note("server port: $port");
    my $alice = create_connection($port, "alice");
    my $bob = create_connection($port, "bob");
    {
        my $cv_bob_recv = receive_msg_cv($bob);
        my $msg = set_id {
            from => "alice", to => "bob", message_type => "hoge"
        };
        send_msg($alice, $msg);
        my $got_msg = decode_json($cv_bob_recv->recv);
        is_deeply $got_msg, $msg, "message delivered alice -> bob";
    }

    my $alice2 = create_connection($port, "alice");

    {
        my @cv_alices = map { receive_msg_cv($_) } ($alice, $alice2);
        my $msg = set_id {
            from => "bob", to => "alice", message_type => "foobar"
        };
        send_msg($bob, $msg);
        my @got_msgs = map { decode_json($_->recv) } @cv_alices;
        is_deeply \@got_msgs, [$msg, $msg],
            "IDs with the same remote node ID should receive the same message";
    }

    undef $alice2;
    undef $alice;
    undef $bob;
    undef $server;

    my $wcv = AnyEvent->condvar;
    my $w; $w = AnyEvent->timer(after => 0.5, cb => sub {
        undef $w;
        $wcv->send;
    });
    $wcv->recv;

    my $unregister_count = 0;
    foreach my $log (@$logs) {
        unlike $log->[0], qr/warn|err|crit|alert|emer/, "warn/error messages should not appear.";
        if($log->[1] =~ /unregister/i) {
            $unregister_count++;
        }
    }
    is $unregister_count, 3, "3 remote nodes are successfully unregistered.";
}

done_testing;
