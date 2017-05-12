#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 37;
use Test::NoWarnings;

use Test::Exception;

my $CLASS = 'Test::UniqueTestNames::Test';
use_ok( $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# new

can_ok( $CLASS, 'new' );

for(
    # name       line    test_name
    [ undef,     undef, 'without a name or line number' ], 
    [ 'herbert', undef, 'without a line number'         ], 
) {
    my( $name, $line, $test_name ) = @$_;
    dies_ok( sub { $CLASS->new( $name, $line ) }, "...and it dies $test_name" );
}

ok( my $test = $CLASS->new( 'herbert', 123 ), '...and we can create a new test with name and line number' );
isa_ok( $test, $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# accessors

can_ok( $CLASS, 'name'  );
can_ok( $CLASS, 'line_numbers' );
can_ok( $CLASS, 'occurrences' );

is( $test->name, 'herbert', '...and name returns the arg passed into the constructor' );
is_deeply( $test->line_numbers, { 123 => 1 }, '...and line_numbers returns a hashref with the line passed into the constructor' );
is( $test->occurrences, 1, '...and occurrences is 1 to begin' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# lowest_line_number

can_ok( $CLASS, 'lowest_line_number' );
is( $test->lowest_line_number, 123, '...and lowest_line_number returns the line passed into the constructor' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# fails

can_ok( $CLASS, 'fails' );

dies_ok( sub { $CLASS->fails }, '...and fails is an instance method only' );

is( $test->fails, 0, "...and the test doesn't fail, since it has only one line number" );

diag 'Creating a new isa_ok test with multiple lines';
my $test2 = $CLASS->new( 'The object isa Foo', 123 );
$test2->add_line_number( 123 );
is( $test2->fails, 0, "...and tests with names like the output of isa_ok's auto-generated tests don't fail" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_line_number

can_ok( $CLASS, 'add_line_number' );
dies_ok( sub { $CLASS->add_line_number}, '...and add_instance is an instance method only' );

ok( $test->add_line_number( 120 ), 'Adding a line number to a test' );
is_deeply(
    $test->line_numbers,
    {
        120 => 1,
        123 => 1,
    },
    '...and line_numbers returns a hashref with both lines'
);
is( $test->occurrences, 2, '...and occurrences is 2 now that one has been added' );
is( $test->lowest_line_number, 120, '...and lowest_line_number is now 120' );
is( $test->fails, 1, "...and the test fails, since it has two line numbers" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# unnamed tests

can_ok( $CLASS, 'unnamed_ok' );

is( $CLASS->unnamed_ok, 0, '...and unnamed_ok is off by default' );

diag 'Creating a new test with no name';
$test = $CLASS->new( undef, 123 );
is( $test->name, '<no test name>', '...and the name of the test is set to the undef placeholder' );
is( $test->fails, 1, "...and the test fails, since by default unnamed tests aren't ok" );

ok( $test->unnamed_ok( 1 ), 'Setting the unnamed_ok flag to true' );
is( $test->fails, 0, "...and the test doesn't fail, since unnamed tests are now ok" );

is( $test->unnamed_ok( 0 ), 0, 'Setting the unnamed_ok flag to false' );
is( $test->fails, 1, "...and the test fails again, since unnamed tests aren't ok" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# short_name

can_ok( $CLASS, 'short_name' );

$test = $CLASS->new( 'a short name', 123 );
is( $test->short_name,  'a short name', "...and a name shorter than 20 chars doesn't get shortened" );

$test = $CLASS->new( "a really, incredibly, unbelieveably long name (that really isn't that long, to be honest)", 123 );
is( $test->short_name,  'a really, incredibly, unbelieveably long...', "...and a name longer than 20 chars gets shortened and ellipsed" );
