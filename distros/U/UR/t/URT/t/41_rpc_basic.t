use strict;
use warnings;
use Test::More;
plan tests => 40;

use File::Basename;
BEGIN { use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../.."; }
use URT;

use IO::Socket;

ok(UR::Object::Type->define(
        class_name => 'URT::RPC::Thingy',
        is => 'UR::Service::RPC::Executer'),
   'Created class for RPC executor');

my($to_server,$to_client) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC);
ok($to_server, 'Created socket');
ok($to_client, 'Created socket');

my $rpc_executer = URT::RPC::Thingy->create(fh => $to_client);

my $rpc_server = UR::Service::RPC::Server->create();
ok($rpc_server, 'Created an RPC server');

ok($rpc_server->add_executer($rpc_executer), 'Added the executer to the server');

#my $rpc_client = UR::Service::RPC::Client->create(fh => $to_server);
#ok($rpc_client, 'Created an RPC client');

my $count = $rpc_server->loop(1);
is($count, 0, 'RPC server ran the event loop and correctly processed 0 events');

my $retval;
my @join_args = ('one','two','three','four');

my $msg = UR::Service::RPC::Message->create(
                           target_class => 'URT::RPC::Thingy',
                           method_name  => 'join',
                           params       => ['-', @join_args],
                           'wantarray'  => 0,
                         );
ok($msg, 'Created an RPC message');
ok($msg->send($to_server), 'Sent RPC message from client');

do {
    local *STDERR;
    no warnings;
    $count = $rpc_server->loop(1);
    use warnings;
};

is($count, 1, 'RPC server ran the event loop and correctly processed 1 event');
is($URT::RPC::Thingy::join_called, 1, 'RPC server called the correct method');

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

$count = $rpc_server->loop(1);
is($count, 1, 'RPC server ran the event loop and correctly processed 1 event');
is($URT::RPC::Thingy::exception, 1, 'RPC server correctly rejected the method call');

$resp = UR::Service::RPC::Message->recv($to_server,1);
ok($resp, 'Got a response message back from the server');
is($resp->return_value, undef, 'Response return value is correctly empty');
is($resp->exception, 'Not allowed', 'Response excpetion is correctly set');



$msg = UR::Service::RPC::Message->create(
                           target_class => 'URT::RPC::Thingy',
                           method_name  => 'some_undefined_function',
                           params       => [],
                           'wantarray' => 0,
                         );
ok($msg, 'Created third RPC message encoding an undefined function call');
ok($msg->send($to_server), 'Sent RPC message from client');

$count = $rpc_server->loop(1);
is($count, 1, 'RPC server ran the event loop and correctly processed 1 event');

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

$count = $rpc_server->loop(1);
is($count, 1, 'RPC server ran the event loop and correctly processed 1 event');

$resp = UR::Service::RPC::Message->recv($to_server,1);
ok($resp, 'Got a response message back from the server');
@return_values = $resp->return_value_list;
is(scalar(@return_values), 1, 'Response had a single return value');
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

$count = $rpc_server->loop(1);
is($count, 1, 'RPC server ran the event loop and correctly processed 1 event');

$resp = UR::Service::RPC::Message->recv($to_server,1);
ok($resp, 'Got a response message back from the server');
my @expected_return_value = qw(a string with);
@return_values = $resp->return_value_list;
is_deeply(\@return_values, \@expected_return_value, 'Response had the correct return value');
is($resp->exception, undef, 'There was no exception');




# END of the main script





package URT::RPC::Thingy;

sub authenticate {
    my($self,$msg) = @_;

    if ($msg->method_name eq 'illegal') {
        $URT::RPC::Thingy::exception++;
        $msg->exception('Not allowed');
        return;
    } else {
        return 1;
    }
}


sub join {
    my($joiner,@args) = @_;

    $URT::RPC::Thingy::join_called++;
    my $string = join($joiner, @args);
    return $string;
}


# A thing that will return different values in scalar and list context
sub match {
    my($string, $regex) = @_;

#    my $pattern = qr($pattern);
    return $string =~ $regex;
}

    



