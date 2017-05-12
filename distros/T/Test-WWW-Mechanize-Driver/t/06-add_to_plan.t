#!/usr/bin/perl
use strict; use warnings;
use lib qw/ t /;

use Test::More;
use MyMechanize;
use Test::WWW::Mechanize::Driver;

my $tester = Test::WWW::Mechanize::Driver->new(
  mechanize => MyMechanize->new,
  add_to_plan => 3,
  load => "t/basic-named_oddly.yml", # 8 tests
);
$tester->mechanize->my_mech_load_files( glob("t/webpages/*.yml") );

plan tests => 11;

is( 1 + 1, 2, "I always wanted to test that" );

is( $tester->tests, 11, "test count is correct" );

$tester->run;

ok( 1, "a silly extra test" );
