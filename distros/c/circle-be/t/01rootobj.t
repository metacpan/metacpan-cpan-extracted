use strict;
use warnings;

use Test::More tests => 13;
use IO::Async::Test;

use IO::Async::Loop;

use Circle;
use t::CircleTest qw( get_widget_from get_widgetset_from );

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my ( $circle, $client ) = Circle->new_with_client( loop => $loop );

my $rootobj;
wait_for { $rootobj = $client->rootobj };

isa_ok( $rootobj, "Tangence::ObjectProxy", '$rootobj' );

ok( $rootobj->proxy_isa( "Circle.RootObj" ), '$rootobj proxy isa Circle.RootObj' );
ok( $rootobj->proxy_isa( "Circle.WindowItem" ), '$rootobj proxy isa Circle.WindowItem' );

my $global_widget = get_widget_from $rootobj;

ok( $global_widget->proxy_isa( "Circle.Widget" ), '$global_widget' );

# Don't rely too much on exact UI layout; build a map of class->widget instead
my $widgets = get_widgetset_from $rootobj;

ok( my $scroller = $widgets->{"Circle.Widget.Scroller"}, 'Found a Scroller widget' );
ok( my $entry    = $widgets->{"Circle.Widget.Entry"},    'Found an Entry widget' );

my $watching;
my $displayevents;
$scroller->watch_property(
   property => "displayevents",
   on_updated => sub { $displayevents = $_[0] },
   on_watched => sub { $watching++ },
);

wait_for { $watching };

my $time_before = time;

$entry->call_method(
   method => "enter",
   args => [ "/eval 1" ],
   on_result => sub { },
);

wait_for { $displayevents };

my $time_after = time;

is( scalar @$displayevents, 1, '$displayevents after entering command contains one line' );

my ( $event ) = @$displayevents;

is( $event->[0], "response", '$event name' );
# Can't quite be sure of the timestamp but it'll be bounded
ok( $time_before >= $event->[1] && $event->[1] >= $time_after, '$event time' );
is_deeply( $event->[2], { text => "Result: 1" }, '$event args' );

undef $displayevents;
$rootobj->call_method(
   method => "do_command",
   args => [ "eval 1" ],
   on_result => sub { },
);

wait_for { $displayevents };

( $event ) = @$displayevents;

is( $event->[0], "response", '$event name from do_command' );
# Can't quite be sure of the timestamp but it'll be bounded
ok( $time_before >= $event->[1] && $event->[1] >= $time_after, '$event time from do_command' );
is_deeply( $event->[2], { text => "Result: 1" }, '$event args from do_command' );

