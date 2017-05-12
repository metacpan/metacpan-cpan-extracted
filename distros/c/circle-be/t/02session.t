use strict;
use warnings;

use Test::More tests => 5;
use Test::Identity;
use IO::Async::Test;

use IO::Async::Loop;

use Circle;
use t::CircleTest qw( get_session send_command );

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my ( $circle, $client ) = Circle->new_with_client( loop => $loop );

my $rootobj;
wait_for { $rootobj = $client->rootobj };

my $session = get_session $rootobj;

ok( $session->proxy_isa( "Circle.Session.Tabbed" ), '$session proxy isa Circle.Session.Tabbed' );

my $tabs;
$session->watch_property(
   property => "tabs",
   want_initial => 1,
   on_updated => sub { $tabs = $_[0] },
);

wait_for { $tabs };

is( scalar @$tabs, 1, '$tabs contains 1 item' );
identical( $tabs->[0], $rootobj, '$tabs->[0] is RootObj' );

undef $tabs;

send_command $rootobj, "networks add -type raw Test";

wait_for { $tabs };

is( scalar @$tabs, 2, '$tabs contains 2 items after /networks add' );

my $rawnet = $tabs->[1];
ok( $rawnet->proxy_isa( "Circle.Net.Raw" ), '$tabs->[1] proxy isa Circle.Net.Raw' );
