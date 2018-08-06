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

my $deps = $ptv->routes->find({name => 'Upfield'})->stops->find({id => 1069})->departures({max_results => 1});
ok( !$deps->error, 'Departures with max_results object created' );
isa_ok( $deps, 'Transport::AU::PTV::Departures' );

foreach ($deps->as_array) {
    ok( !$_->error, 'Departure no error' );
    isa_ok( $_, 'Transport::AU::PTV::Departure' );

    ok( defined $_->estimated_departure, 'Estimated Departure' );
    isa_ok( $_->estimated_departure, 'DateTime' );
    ok( defined $_->scheduled_departure, 'Scheduled Departure' );
    isa_ok( $_->scheduled_departure, 'DateTime' );
    ok( defined $_->at_platform, 'At Platform' );
    ok( defined $_->direction_id, 'Direction ID' );
    ok( defined $_->at_platform, 'Run ID' );
}


done_testing();
