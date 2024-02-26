use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

use Test::Files::Constants qw( $UNKNOWN );

plan( 2 );

public_sub( 'main::public_sub', 'public subroutine detected' );
_another_private_sub( $UNKNOWN, 'no public subroutine detected' );

sub _another_private_sub { return _private_sub( @_ ) }      ## no critic (RequireArgUnpacking)

sub _private_sub {
  my ( $expected, $title ) = @_;

  return is( $METHOD_REF->(), $expected, $title );
}

sub public_sub { return _private_sub( @_ ) }                ## no critic (RequireArgUnpacking)
