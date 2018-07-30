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

ok( $routes->count > 0, 'Route count > 0' );
my @routes = $routes->as_array;
ok( @routes, 'Routes as_array count > 0' );

# Is each route the correct object
foreach (@routes) {
    ok( !$_->error, "No error for Route object" );
    isa_ok( $_, 'Transport::AU::PTV::Route' );
}

done_testing();
