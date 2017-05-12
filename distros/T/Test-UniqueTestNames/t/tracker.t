#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 19;
use Test::NoWarnings;

use Test::Exception;
use Test::UniqueTestNames::Test;

my $CLASS = 'Test::UniqueTestNames::Tracker';
use_ok( $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all_tests

can_ok( $CLASS, 'all_tests' );
is_deeply( $CLASS->all_tests, [], '...and there are no tests yet' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# failing_tests

can_ok( $CLASS, 'failing_tests' );
is_deeply( $CLASS->failing_tests, [], '...and there are no tests yet, so none are failing' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_test

can_ok( $CLASS, 'add_test' );

dies_ok( sub { $CLASS->add_test( 'phil' )  }, '...and add_test must have a line number' );
ok( $CLASS->add_test( 'phil', 692 ), '...and we can add a test with a name and a line number' );

my $test = Test::UniqueTestNames::Test->new( 'phil', 692 );

is_deeply(
    $CLASS->all_tests,
    [ $test ],
    '...and there is one test in the list'
);
is_deeply( $CLASS->failing_tests, [], "...but it isn't failing" );

ok( $CLASS->add_test( 'phil', 693 ), 'Adding a second test with the same name' );

$test->add_line_number( 693 );

is_deeply(
    $CLASS->all_tests,
    [ $test ],
    '...and there is one test in the list, with two lines'
);
is_deeply(
    $CLASS->failing_tests,
    [ $test ],
    "...and now it's failing"
);

diag( 'Adding another failing test with a lower line number' );
$CLASS->add_test( 'dick', 200 );
$CLASS->add_test( 'dick', 700 );

my $test2 = Test::UniqueTestNames::Test->new( 'dick', 200 );
$test2->add_line_number( 700 );

is_deeply(
    $CLASS->failing_tests,
    [ $test2, $test ],
    "...and now there are two failing tests, sorted by lowest first line number"
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# unnamed tests

can_ok( $CLASS, 'unnamed_ok' );

diag( 'Adding a test with no name' );
$CLASS->add_test( undef, 9000 );

my $test3 = Test::UniqueTestNames::Test->new( undef, 9000 );

is_deeply(
    $CLASS->failing_tests,
    [ $test2, $test, $test3 ],
    "...and now there are three failing tests, since unnamed tests are failures by default"
);

ok( $CLASS->unnamed_ok( 1 ), "...and we decide that unnamed tests aren't failures any more" );

is_deeply(
    $CLASS->failing_tests,
    [ $test2, $test ],
    "...and now there are two failing tests again, since unnamed tests aren't failures",
);

