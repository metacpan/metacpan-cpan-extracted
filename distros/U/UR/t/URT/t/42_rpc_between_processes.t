use strict;
use warnings;
use File::Basename;
BEGIN { use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..'; }
use URT;
use above "UR";
use Test::More;# skip_all => "fork() causes intermittent failure in TAP output";
use Test::Fork;

use IO::Socket;

# TCP sockets are used when running separate processes for
# debugging the test
# Let the system pick a socket for us, and then close it.  We'll use ReuseAddr
# when we re-open it
our $PORT;
{
    my $s = IO::Socket::INET->new(Listen => 1, Proto => 'tcp');
    $PORT = $s->sockport();
}
STDOUT->autoflush(1);
STDERR->autoflush(1);

my($to_server,$to_client);
if ($ARGV[0] and $ARGV[0] ne '--parent' and $ARGV[0] ne '--child') {
  ($to_server, $to_client) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC);

} elsif ($ARGV[0] and $ARGV[0] eq '--child') {
    # This is for debugging the test case.
    # It will start up just the child part
    note('Starting up the child portion');
    &Child();
    exit(0);
}

plan tests => 35;
my $pid;
if ($ARGV[0] and $ARGV[0] eq '--parent') {
    1;  # do nothing special
#} elsif (! ($pid = fork())) {
#    # child - server
#    &Child();
#    exit(0);
#}
} else {
    $pid = fork_ok(6, \&Child);
}

END { 
    unless ($ARGV[0]) {
        if ($pid) {
            note("killing child PID $pid\n");
            kill 'TERM', $pid;
        } elsif (getppid() != 1) {
            note("Child is exiting early... killing parent");
            kill 'TERM', getppid();
        }
    }
}

# parent

#plan tests => 28;
unless ($to_server) {
    sleep(1);  # Give the child a change to get started

    $to_server = IO::Socket::INET->new(PeerHost => '127.0.0.1',
                                       PeerPort => $PORT);
}
$to_client && $to_client->close();

ok($to_server, 'Created a socket connected to the child process ' . $!);


my @join_args = ('one','two','three','four');
my $msg = UR::Service::RPC::Message->create(
                           #target_class => 'URT::RPC::Thingy',
                           method_name  => 'join',
                           params       => ['-', @join_args],
                           'wantarray'  => 0,
                         );
ok($msg, 'Created an RPC message');
ok($msg->send($to_server), 'Sent RPC message from client');

my $resp = UR::Service::RPC::Message->recv($to_server,1);
ok($resp, 'Got a response message back from the server');
my $expected_return_value = join('-',@join_args);
my @return_values = $resp->return_value_list;
is(scalar(@return_values), 1, 'Response had a single return value');
is($return_values[0], $expected_return_value, 'Response return value is correct');
is($resp->exception, undef, 'Response correctly has no exception');



$msg = UR::Service::RPC::Message->create(
                           target_class => 'URT::RPC::Thingy',
                           method_name  => 'illegal',
                           params       => \@join_args,
                           'wantarray'  => 0,
                         );
ok($msg, 'Created another RPC message');
ok($msg->send($to_server), 'Sent RPC message from client');

$resp = UR::Service::RPC::Message->recv($to_server,1);
ok($resp, 'Got a response message back from the server');
@return_values = $resp->return_value_list;
is(scalar(@return_values), 0, 'Response return value is correctly empty');
is($resp->exception, 'Not allowed', 'Response excpetion is correctly set');



$msg = UR::Service::RPC::Message->create(
                           target_class => 'URT::RPC::Thingy',
                           method_name  => 'some_undefined_function',
                           params       => [],
                           'wantarray' => 0,
                         );
ok($msg, 'Created third RPC message encoding an undefined function call');
ok($msg->send($to_server), 'Sent RPC message from client');

$resp = UR::Service::RPC::Message->recv($to_server,1);
ok($resp, 'Got a response message back from the server');
@return_values = $resp->return_value_list;
is(scalar(@return_values), 0, 'Response return value is correctly empty');
ok($resp->exception =~ m/(Can't locate object method|Undefined sub).*some_undefined_function/,
   'Response excpetion correctly reflects calling an undefined function');

my $string = 'a string with some words';
my $pattern = '(\w+) (\w+) (\w+)';
my $regex = qr($pattern);
$msg = UR::Service::RPC::Message->create(
                           target_class => 'URT::RPC::Thingy',
                           method_name  => 'match',
                           params       => [$string, $regex],
                           'wantarray' => 0,
                        );
ok($msg, 'Created RPC message for match in scalar context');
ok($msg->send($to_server), 'Sent RPC message to server');

$resp = UR::Service::RPC::Message->recv($to_server,1);
ok($resp, 'Got a response message back from the server');
@return_values = $resp->return_value_list;
is(scalar(@return_values), 1, 'Response had a single value');
is($return_values[0], 1, 'Response had the correct return value');
is($resp->exception, undef, 'There was no exception');





$msg = UR::Service::RPC::Message->create(
                           target_class => 'URT::RPC::Thingy',
                           method_name  => 'match',
                           params       => [$string, $regex],
                           'wantarray' => 1,
                      );
ok($msg, 'Created RPC message for match in list context');
ok($msg->send($to_server), 'Sent RPC message to server');

$resp = UR::Service::RPC::Message->recv($to_server,1);
ok($resp, 'Got a response message back from the server');
my @expected_return_value = qw(a string with);
is_deeply($resp->return_value_arrayref, \@expected_return_value, 'Response had the correct return value');
is($resp->exception, undef, 'There was no exception');


sub Child {
    #plan tests => 6;

    ok(UR::Object::Type->define(
            class_name => 'URT::RPC::Listener',
            is => 'UR::Service::RPC::TcpConnectionListener'),
       'Created class for RPC socket Listener');

    ok(UR::Object::Type->define(
            class_name => 'URT::RPC::Thingy',
            is => 'UR::Service::RPC::Executer'),
       'Created class for RPC executor');

    unless ($to_client) {
        $to_client = IO::Socket::INET->new(LocalPort => $PORT,
                                                  Proto => 'tcp',
                                                  Listen => 5,
                                                  Reuse => 1);
    }
    $to_server && $to_server->close();

    ok($to_client, 'Created TCP listen socket');

    my $listen_executer = URT::RPC::Listener->create(fh => $to_client);
    ok($listen_executer, 'Created RPC executer for the listen socket');

    my $rpc_server = UR::Service::RPC::Server->create();
    ok($rpc_server, 'Created an RPC server');

    ok($rpc_server->add_executer($listen_executer), 'Added the listen executer to the server');
    #$rpc_server->add_executer($listen_executer);

    note('Child process entering the event loop');
    while(1) {
        $rpc_server->loop(undef);
    }
}



# END of the main script




package URT::RPC::Listener;

sub worker_class_name {
    'URT::RPC::Thingy';
}

package URT::RPC::Thingy;

sub authenticate {
    my($self,$msg) = @_;

    if ($msg->method_name eq 'illegal') {
        #$URT::RPC::Thingy::exception++;
        $msg->exception('Not allowed');
        return;
    } else {
        return 1;
    }
}


sub join {
    my($joiner,@args) = @_;

    #$URT::RPC::Thingy::join_called++;
    my $string = join($joiner, @args);
    return $string;
}


# A thing that will return different values in scalar and list context
sub match {
    my($string, $regex) = @_;

#    my $pattern = qr($pattern);
    return $string =~ $regex;
}

    



