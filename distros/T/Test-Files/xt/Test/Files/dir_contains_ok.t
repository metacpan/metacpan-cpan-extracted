use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

my $diag;
my $mockThis = mock $CLASS => (
  override => [
    _dir_contains_ok        => sub { [] },
    _show_failure           => sub { $_[ 1 ] },
    _show_result            => sub {},
    _validate_trailing_args => sub { ( $diag, {} ) },
  ]
);

plan( 2 );                                                  ## no critic (ProhibitMagicNumbers)

$diag = undef;
is( $METHOD_REF->( 'dir', [ 'file' ] ), $diag, 'comparison performed' );

$diag = 'ERROR';
is( $METHOD_REF->( 'dir', [ 'file' ] ), $diag, 'invalid arguments, comparison rejected' );
