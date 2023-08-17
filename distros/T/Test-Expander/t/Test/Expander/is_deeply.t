use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Builder::Tester tests => 1;

use Test::Expander;

my $title = 'execution';
test_out( "ok 1 - $title" );
my $got      = bless( { A => 0, B => [ ( 0 .. 1 ) ] }, 'some class' );
my $expected = bless( { A => 0, B => [ ( 0 .. 1 ) ] }, 'some class' );
is_deeply( $got, $expected, $title );
test_test( $title );
