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

my $stops = $ptv->routes->find({name => 'Upfield'})->stops;
ok( !$stops->error, 'Routes object created' );
isa_ok( $stops, 'Transport::AU::PTV::Stops' );

foreach ($stops->as_array) {
    ok( !$_->error, 'Stop no error' );
    isa_ok( $_, 'Transport::AU::PTV::Stop' );

    ok( defined $_->name, 'Stop has a name' );
    ok( defined $_->type, "Stop ".$_->name." has a type" );
    ok( defined $_->id, "Stop ".$_->name." has an id" );
    ok( defined $_->route_id, "Stop ".$_->name." has a route ID" );
}


done_testing();
