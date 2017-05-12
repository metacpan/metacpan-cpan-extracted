#!/usr/bin/perl
#
# Test after_response feature:
#   * perform extra tests in after_response
#
use strict; use warnings;
use lib qw/ t /;

use MyMechanize;
use Test::WWW::Mechanize::Driver;
use Test::More;

my $page_count = 0;
my $tester = Test::WWW::Mechanize::Driver->new(
  mechanize => MyMechanize->new,
  after_response => sub {
    my ($mech, $opt) = @_;
    $page_count++;
    isa_ok( $mech, 'MyMechanize',   "first arg is Mechanize object" );
    is( ref($opt), 'HASH',          "second arg is options hash" );
    ok( $$opt{my_custom_parameter}, "contains custom keys" );
    is( $$opt{tags}, 'foo',         "contains custom keys from HASH document" );
  },
  after_response_tests => 4,
  add_to_plan => 1,
);
$tester->mechanize->my_mech_load_files( glob("t/webpages/*.yml") );
$tester->run;

my $pages_expected = $tester->test_groups;
is( $page_count, $pages_expected,  'after_response called for each page' );
