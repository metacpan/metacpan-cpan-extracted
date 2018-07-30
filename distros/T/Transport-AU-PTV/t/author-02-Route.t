#!perl -T

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use 5.010;
use strict;
use warnings;
use Test::More;

# Access to module tested in 00-PTV.t
use Transport::AU::PTV;
my $ptv = Transport::AU::PTV->new;

my $routes = $ptv->routes;
ok( !$routes->error, 'Routes object created' );
isa_ok( $routes, 'Transport::AU::PTV::Routes' );

# Get the routes the $ptv->routes call
# Route types are 0 - 4
#
foreach my $route_type (0 .. 4) {
    my $route = $routes->first(sub { $_->type == $route_type });
    ok( !$route->error, 'Route no error' );
    isa_ok( $route, 'Transport::AU::PTV::Route' );

    my ($id, $name) = ($route->id, $route->name);
    ok( $id, 'Route has an ID' );
    ok( $name, 'Route has a name' ) or diag("Route ID $id");

    # Get the route directly
    my $route_direct = $ptv->route({ route_id => $id });
    ok( !$route_direct->error, "Route direct ID $id no error" );
    isa_ok( $route_direct, 'Transport::AU::PTV::Route' );

    is_deeply( $route, $route_direct, 'Route and route direct are identical' );
}


done_testing();
