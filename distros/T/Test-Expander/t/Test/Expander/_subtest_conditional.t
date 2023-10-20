use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

my $subtestSkipped;
my $mock = mock 'Test2::API::Context' => ( override => [ skip => sub { ok( $subtestSkipped, 'subtest skipped' ) } ] );

plan( 3 );

subtest 'other subtest choosen' => sub {
  plan( 2 );
  local @ARGV = ( '--subtest_number' => '1/0' );
  Test::Expander::_subtest_selection();
  $subtestSkipped = 1;
  lives_ok { $METHOD_REF->( sub { ok( !$subtestSkipped, 'subtest entered' ) }, 'name' ) } 'executed';
};

subtest 'subtest by number' => sub {
  plan( 2 );
  local @ARGV = ( '--subtest_name' => '[A-Z]' );
  Test::Expander::_subtest_selection();
  $subtestSkipped = 0;
  lives_ok { $METHOD_REF->( sub { ok( !$subtestSkipped, 'original entered' ) }, 'name' ) } 'executed';
};

subtest 'subtest by name with any capital letter e.g. A' => sub {
  plan( 2 );
  $subtestSkipped = 0;
  lives_ok { $METHOD_REF->( sub { ok( !$subtestSkipped, 'original entered' ) }, 'NAME' ) } 'executed';
};
