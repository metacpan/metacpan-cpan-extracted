use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok("jQluster::Server");
}

sub create_fake_connection {
    my @log = ();
    return {
        log => \@log,
        sender => sub {
            push(@log, shift);
        }
    };
}

sub clear_log {
    foreach my $connection (@_) {
        @{$connection->{log}} = ();
    }
}

sub register_message {
    my ($message_id, $from) = @_;
    return {
        message_id => $message_id, message_type => "register",
        from => $from, to => undef,
        body => { remote_id => $from }
    };
}

sub create_server {
    my @logs = ();
    my $server = jQluster::Server->new(
        logger => sub { push(@logs, [@_]) }
    );
    return ($server, \@logs);
}

sub check_server_logs {
    my ($logs_ref) = @_;
    foreach my $log (@$logs_ref) {
        if(lc($log->[0]) eq "error") {
            fail("There is an error log: $log->[0]: $log->[1]");
            return;
        }
    }
    pass("No error log");
}

{
    note("--- registration");
    my @logs = ();
    my $s = new_ok("jQluster::Server", [logger => sub { push(@logs, [@_]) }]);
    my $alice = create_fake_connection();
    $s->register(
        unique_id => 1,
        message => register_message("hoge", "alice"),
        sender => $alice->{sender}
    );
    is(scalar(@{$alice->{log}}), 1, "1 message received after registration");
    my $msg = $alice->{log}[0];
    is_deeply($msg, {
        message_id => $msg->{message_id}, ## arbitrary
        message_type => "register_reply", from => undef, to => "alice",
        body => { error => undef, in_reply_to => "hoge" }
    });
    check_server_logs \@logs;
}

{
    note("--- duplicate registration");
    my ($s, $server_logs) = create_server();
    my $alice = create_fake_connection();
    $s->register(
        unique_id => "alice",
        message => register_message(1, "alice"),
        sender => $alice->{sender}
    );
    dies_ok {
        $s->register(
            unique_id => "alice",
            message => register_message(2, "alice"),
            sender => $alice->{sender}
        )
    } "duplicate registration should throw an exception";
}

{
    note("--- single destination");
    my ($s, $server_logs) = create_server();
    my $alice = create_fake_connection();
    my $bob = create_fake_connection();
    $s->register(
        unique_id => "$alice",
        message => register_message("alice_register", "alice"),
        sender => $alice->{sender}
    );
    $s->register(
        unique_id => "$bob",
        message => register_message("bob_register", "bob"),
        sender => $bob->{sender}
    );
    clear_log $alice, $bob;
    my $message = {
        message_id => "test", message_type => "test",
        from => "alice", to => "bob", body => { foo => "bar" }
    };
    $s->distribute($message);
    is_deeply($alice->{log}, [], "alice recieves nothing");
    is_deeply($bob->{log}, [$message], "bob receives a message");
    check_server_logs $server_logs;
}

{
    note("--- multiple destination");
    my ($s, $server_logs) = create_server();
    my @connections = map { create_fake_connection() } 1..2;
    foreach my $c (@connections) {
        $s->register(
            unique_id => "$c", message => register_message("$c", "carol"),
            sender => $c->{sender}
        );
    }
    clear_log @connections;
    my $message = {
        message_id => "test", message_type => "test",
        from => "alice", to => "carol", body => {hoge => 100}
    };
    $s->distribute($message);
    foreach my $i (0 .. $#connections) {
        my $c = $connections[$i];
        is_deeply($c->{log}, [$message], "connection $i received the message");
    }
    check_server_logs $server_logs;
}

{
    note("--- no destination");
    my ($s, $server_logs) = create_server();
    my $alice = create_fake_connection();
    $s->register(
        unique_id => "$alice", message => register_message("alice_register", "alice"),
        sender => $alice->{sender}
    );
    clear_log $alice;

    my $message = { message_id => "to_bob",
                    message_type => "select_and_get",
                    from => "alice", to => "bob", body => {
                        remote_id => "alice", eval_code => "hoge()",
                    } };
    $s->distribute($message);
    is(scalar(@{$alice->{log}}), 1, "alice received 1 message");
    my $alice_message = $alice->{log}[0];
    is($alice_message->{message_type}, "select_and_get_reply");
    is($alice_message->{from}, undef, "the message is from the server");
    is($alice_message->{to}, "alice");
    is($alice_message->{body}{in_reply_to}, "to_bob");
    ok(defined($alice_message->{body}{error}), "the message indicates error");
    check_server_logs $server_logs;
}

{
    note("--- unregister (single node in remote_id)");
    my ($s, $server_logs) = create_server();
    my $alice = create_fake_connection();
    $s->register(
        unique_id => "$alice",
        message => register_message("hoge", "alice"),
        sender => $alice->{sender}
    );
    my $bob = create_fake_connection();
    $s->register(
        unique_id => "$bob",
        message => register_message("foobar", "bob"),
        sender => $bob->{sender}
    );
    clear_log $alice, $bob;
    $s->unregister("$alice");
    $s->distribute({
        message_id => "buzz", message_type => "select_and_listen",
        from => "bob", to => "alice", body => {remote_id => "bob", eval_code => "hoge()"}
    });
    is_deeply($alice->{log}, [], "alice receives nothing because it is unregistered");
    is(scalar(@{$bob->{log}}), 1, "bob receives a message");
    my $bmessage = $bob->{log}[0];
    is($bmessage->{message_type}, "select_and_listen_reply");
    is($bmessage->{from}, undef);
    is($bmessage->{to}, "bob");
    is($bmessage->{body}{in_reply_to}, "buzz");
    ok(defined($bmessage->{body}{error}));
    check_server_logs $server_logs;
}

{
    note("--- unregister (multiple nodes in remote_id)");
    my ($s, $server_logs) = create_server();
    my @cs = map { create_fake_connection() } 1..2;
    foreach my $c (@cs) {
        $s->register(
            unique_id => "$c",
            message => register_message("$c", "carol"),
            sender => $c->{sender}
        );
    }
    clear_log @cs;
    $s->unregister("$cs[0]");
    my $message = {
        message_id => "hoge", message_type => "test",
        from => "bob", to => "carol", body => {error => undef}
    };
    $s->distribute($message);
    is_deeply($cs[0]{log}, [], "connection 0 receives nothing because it is already unregistered");
    is_deeply($cs[1]{log}, [$message], "connection 1 receives the message because it is still registered");
    check_server_logs $server_logs;
}

{
    note("--- unregister non-existent node");
    my ($s, $server_logs) = create_server();
    $s->unregister("hogehoge");
    is_deeply($server_logs, [], "unregister non-existent node does nothing. No logs.");
}

done_testing();

