#!/usr/bin/perl
use strict; use warnings;
use lib qw/ lib t /;

use Test::More tests => 14;
use MyMechanize;
use Test::WWW::Mechanize::Driver;

# Basic creation using default Mechanize object
my $tester = Test::WWW::Mechanize::Driver->new( no_plan => 1 );
is( $tester->tests, 0, "no tests on creation" );
is( $tester->test_groups, 0, "no groups on creation" );

eval { $tester->run };
ok( $@, "Running tests with none available is fatal" );

$tester = Test::WWW::Mechanize::Driver->new(
  mechanize => MyMechanize->new,
  no_plan => 1,
);
$tester->mechanize->my_mech_load_files( glob("t/webpages/*.yml") );

is( $tester->load( "t/basic-named_oddly.yml" ), 8, "loading 8 tests" );
is( $tester->tests, 8, "test count is correct" );
is( $tester->test_groups, 3, "number of test groups is correct" );
$tester->run;
