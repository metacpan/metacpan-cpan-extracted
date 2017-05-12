use strict;
use warnings;

use Test::More tests => 10;
use IO::Async::Test;

use IO::Async::Loop;
use IO::Async::Listener;

use Circle;
use t::CircleTest qw( send_command get_session get_widgetset_from );

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my ( $circle, $client ) = Circle->new_with_client( loop => $loop );

my $rootobj;
wait_for { $rootobj = $client->rootobj };

my $session = get_session $rootobj;

send_command $rootobj, "networks add -type raw Test";

my $rawnet;
$session->get_property(
   property => "tabs",
   on_value => sub {
      $rawnet = $_[0]->[1],
      defined $rawnet or die "Expected a tab [1] didn't get one";
   },
);
wait_for { defined $rawnet };

ok( $rawnet->proxy_isa( "Circle.Net.Raw" ), '$rawnet proxy isa Circle.Net.Raw' );

my $connected_args;
$rawnet->subscribe_event(
   event => "connected",
   on_fire => sub { $connected_args = [ @_ ] },
);

my $widgets = get_widgetset_from $rawnet;

my $serverstream;
my $listener = IO::Async::Listener->new(
   on_stream => sub {
      ( undef, $serverstream ) = @_;
   },
);

$loop->add( $listener );

$listener->listen(
   addr => {
      family   => "inet",
      socktype => "stream",
      ip       => "127.0.0.1",
      port     => 0,
   },

   on_listen_error  => sub { die "Test failed early - listen $_[-1]\n" },
);

my $port = $listener->read_handle->sockport;

send_command $rawnet, "connect localhost $port";

wait_for { defined $serverstream };

ok( 1, '$rawnet connected to listener' );

wait_for { $connected_args };

ok( 1, '$rawnet fires connected event' );
is( $connected_args->[0], "localhost", 'connected event host' );
is( $connected_args->[1], $port, 'connected event port' );

my @lines_from_client;
$serverstream->configure(
   on_read => sub {
      my ( $self, $buffref, $eof ) = @_;
      push @lines_from_client, $1 while $$buffref =~ s/(.*?)\r?\n//;
      return 0;
   }
);
$loop->add( $serverstream );

$widgets->{"Circle.Widget.Entry"}->call_method(
   method => "enter",
   args   => [ "Hello, server!" ],
   on_result => sub { },
);

wait_for { @lines_from_client };

is( shift @lines_from_client, "Hello, server!", 'client can send to server' );

my $watching;
my @displayevents;
$widgets->{"Circle.Widget.Scroller"}->watch_property(
   property => "displayevents",
   on_set => sub {},
   on_push => sub {
      push @displayevents, @_;
   },
   on_shift => sub {},
   on_watched => sub { $watching++ },
);

wait_for { $watching };

my $time_before = time;

$serverstream->write( "Hello, client!\r\n" );

wait_for { @displayevents };

my $time_after = time;

my $event = shift @displayevents;

is( $event->[0], "text", '$event name for server reply' );
# Can't quite be sure of the timestamp but it'll be bounded
ok( $time_before >= $event->[1] && $event->[1] >= $time_after, '$event time for server reply' );
is_deeply( $event->[2], { text => "Hello, client!" }, '$event args for server reply' );

# Test that the whole lot doesn't fall in a heap and die just because a frontend disappears

$client->close;
undef $client;

# Acknowledge the close of connection
$loop->loop_once( 1 );

# Cheating
my @events;
$circle->{rootobj}->get_prop_networks->{Test}->get_widget_scroller->watch_property( displayevents => 
   on_set   => sub { shift; @events = @_ },
   on_push  => sub { shift; push @events, @_ },
   on_shift => sub { shift; splice @events, 0, shift },
);

$serverstream->write( "Another line\r\n" );

wait_for { @events };
ok( 1, "Server didn't die after new event for closed client" );
