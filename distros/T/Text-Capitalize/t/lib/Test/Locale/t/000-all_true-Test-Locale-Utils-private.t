# Test file created outside of h2xs framework.
# Run this like so: `perl Test-Locale-Utils.t'
#   doom@kzsu.stanford.edu     2009/03/13 20:11:32

use warnings;
use strict;
$|=1;
my $DEBUG = 1;             # TODO set to 0 before ship
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 7 }; # TODO change to 'tests => last_test_to_print';

use FindBin qw( $Bin ); # ~/End/Cave/CapitalizeTitle/Wall/Text/Capitalize/t/lib/Test/Locale/t/
use lib ("$Bin/../../..");

# TODO I'm "use"ing this twice...
BEGIN {
  use_ok( 'Test::Locale::Utils' );
}

ok(1, "Traditional: If we made it this far, we're ok.");

use Test::Locale::Utils qw(:all);

{
  my $test_name = "Testing all_true";
  my $test_case = "Array of true items.";
  my @array = (1,
               '1',
               'hey there',
               defined(' '),
               'hard times',
               );

  my $flag = all_true( \@array );

  is( $flag, 1, "$test_name: $test_case");
}

{
  my $test_name = "Testing all_true";
  my $test_case = "Array of items, one *not* true";
  my (@array, $flag);
  @array =    ( 1,
               '1',
               0,
               'hard times',
               );

  $flag = all_true( \@array );

  is( $flag, 0, "$test_name: $test_case: zero");


  @array =    ( 1,
               '1',
               '',
               'hard times',
               );

  $flag = all_true( \@array );

  is( $flag, 0, "$test_name: $test_case: empty string");

  @array =    ( 1,
               '1',
               '0',
               'hard times',
               );

  $flag = all_true( \@array );

  is( $flag, 0, "$test_name: $test_case: quoted zero");


  @array =    ( 1,
               '1',
               undef,
               'hard times',
               );

  $flag = all_true( \@array );

  is( $flag, 0, "$test_name: $test_case: undef");

}
