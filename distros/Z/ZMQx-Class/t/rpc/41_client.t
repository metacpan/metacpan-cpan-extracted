use strict;
use warnings;
use 5.014;

use Test::Most;
use ZMQx::Class;
use ZMQx::RPC::Client;
use AnyEvent;

my $rpc;

package TestLoop {
    use Moose;

    with 'ZMQx::RPC::Loop' => {
                               commands=>[
                                          'rot13',
                                          'excuse',
                                          'stop',
                                         ]
                              };

    sub rot13 {
        my ($self, @payload ) = @_;
        # TODO - Use NFD to decompose the message into letters and accents, and
        # hence ROT13 letters with diacriticals. :-)
        return map {tr/A-Za-z/N-ZA-Mn-za-m/r} @payload;
    }

    my @animals = qw(dog elephant ferret);
    sub excuse {
        my $scapegoat = $animals[rand @animals];
        die "The $scapegoat ate my homework";
    }

    sub stop {
        Test::More::diag("Server instructed to stop");
        $rpc->_server_is_running(0);
    }
}

my $endpoint = "ipc:///tmp/test-zmqx-class-$$:".int(rand(64)+1).'025';
my $context = ZMQx::Class->context;

diag("running zmq on $endpoint");

pipe my $r, my $w
    or die "Can't pipe: $!";

my $pid = fork;
die "Can't fork: $!"
    unless defined $pid;

unless ($pid) {
    close $r;
    # Run the server in the child;
    my $server = ZMQx::Class->socket($context, 'REP', bind =>$endpoint );
    print $w "Go!\n";
    close $w;

    $rpc = TestLoop->new;

    my $stop = AnyEvent->timer(
                               after=>5,
                               cb=>sub {
                                   diag "killed server and tests after 5 secs";
                                   $rpc->_server_is_running(0);
                               }
                              );

    $rpc->loop($server);
    exit 0;
}

close $w;
is(<$r>, "Go!\n", 'Server socket is ready');

my $client = ZMQx::Class->socket($context, 'REQ', connect =>$endpoint);

my $client0 = ZMQx::RPC::Client->new();
isa_ok($client0, 'ZMQx::RPC::Client');
throws_ok(sub {$client0->rpc_bind()},
          qr/command is a mandatory argument/);
throws_ok(sub {$client0->rpc_bind(command=>'rot13')},
          qr/server is a mandatory argument/);
# TODO - improve the error message?
throws_ok(sub {$client0->rpc_bind(command=>'rot13',server=>'bogus')},
          qr/server is a mandatory argument/,
          'Server must be a reference');

# TODO - right now rpc_bind generates subroutine references that it expects you
# to call as methods. However, they *actually* using the invocant object,
# because they are actually subroutines that are closures over all the
# parameters they need. So they throw the first argument away for internal
# things, but pass it to all the callbacks, in case the callbacks are methods.
# It would be good to offer an option to bind as "subroutines", where all the
# arguments are passed over the wire to the server. But for now, all our use
# cases are methods on objects, so make the tests call "methods". For which we
# need an object on which to invoke them:
my $fake_obj = bless *STDIN{IO}, __PACKAGE__;

my $rot0 = $client0->rpc_bind(command=>'rot13',server=>$client);
isa_ok($rot0, 'CODE');
is_deeply($fake_obj->$rot0(), []);
is_deeply($fake_obj->$rot0('hello', 'world'), ['uryyb', 'jbeyq'],
          'default is to return an array reference');

my $rot1 = $client0->rpc_bind(command=>'rot13',server=>$client,return=>'List');
isa_ok($rot1, 'CODE');
is_deeply([$fake_obj->$rot1()], []);
is_deeply([$fake_obj->$rot1('hello', 'world')], ['uryyb', 'jbeyq'],
          'return a flat list');
# Not that any sane code would do this:
is_deeply($fake_obj->$rot0('hello', 'world'), ['uryyb', 'jbeyq'],
          'no reason that the previous binding should stop working');

my $rot2 = $client0->rpc_bind(command=>'rot13',server=>$client,return=>'Item');
isa_ok($rot2, 'CODE');
is_deeply([$fake_obj->$rot2()], [undef]);
is_deeply([$fake_obj->$rot2('hello', 'world')], ['uryyb'],
          'return one item');

my $rot3 = $client0->rpc_bind(command=>'rot13',server=>$client,return=>sub {
                                  my ($response, $args, $msg, $params) = @_;
                                  isa_ok($response, 'ZMQx::RPC::Message::Response');
                                  isa_ok($msg, 'ZMQx::RPC::Message::Request');
                                  is_deeply($args, [$fake_obj, 'hello', 'world'],
                                     'Got the arguments we expected');
                                  isa_ok($params, 'HASH');
                                  is($params->{command}, 'rot13');
                                  my $got = $response->payload->[0];
                                  return uc $got;
                              });
isa_ok($rot3, 'CODE');
is_deeply([$fake_obj->$rot3('hello', 'world')], ['URYYB'],
          'custom code for post-processing return');

my $called;
my $rot4 = $client0->rpc_bind(command=>'rot13',server=>sub {
                                  is($called, undef, 'not called yet');
                                  ++$called;
                                  return $client;
                              });
is($called, undef, 'server closure not called yet');
isa_ok($rot4, 'CODE');
is_deeply($fake_obj->$rot4(), [], 'getting the server from a runtime call');
is($called, 1, 'server closure called once');

# Technically we can default anything. Not sure if it's a great idea to default
# the command, but hey, let's test it:
my $client1 = ZMQx::RPC::Client->new(command=>'rot13',server=>$client);
isa_ok($client0, 'ZMQx::RPC::Client');
my $rot5 = $client1->rpc_bind();
isa_ok($rot5, 'CODE');
is_deeply($fake_obj->$rot5('hello', 'world'), ['uryyb', 'jbeyq'],
          'default is to return an array reference');

my $excuse0 = $client1->rpc_bind(command => 'excuse');
isa_ok($excuse0, 'CODE');
is(eval { $fake_obj->$excuse0('hello', 'world') }, undef,
   'can override the defaults');
like($@, qr/ate my homework/, 'returned error caught');

my $excuse1 = $client1->rpc_bind(command => 'excuse',
                                 on_error => sub {
                                     my ($err, $response, $args, $msg, $params) = @_;
                                     like($err, qr/ate my homework/, 'returned error passed in');
                                     isa_ok($response, 'ZMQx::RPC::Message::Response');
                                     isa_ok($msg, 'ZMQx::RPC::Message::Request');
                                     is_deeply($args, [$fake_obj, 'hello', 'world'],
                                               'Got the arguments we expected');
                                     isa_ok($params, 'HASH');
                                     is($params->{command}, 'excuse');
                                     return ucfirst $args->[1];
                                 });
isa_ok($excuse1, 'CODE');
is_deeply($fake_obj->$excuse1('hello', 'world'), 'Hello', 'error handler called');

my $rot6 = $client1->rpc_bind(munge_args => sub {
                                  my $self = shift;
                                  isa_ok($self, __PACKAGE__);
                                  return reverse @_;
                              });

isa_ok($rot6, 'CODE');
is_deeply($fake_obj->$rot6('hello', 'world'), ['jbeyq', 'uryyb'],
          'argument pre-processor called');

my $stop = ZMQx::RPC::Client->rpc_bind(
                                       server => $client,
                                       command => 'stop'
                                      );
$stop->();
done_testing();
