use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

my $mockThis = mock $CLASS => (
  override => [
    _dir_contains_ok        => sub {},
    _show_failure           => sub {},
    _show_result            => sub { 1 },
    _validate_trailing_args => sub { shift },
  ],
);

plan( 2 );

ok(  $METHOD_REF->( 'dir', [ 'file' ] ), 'comparison performed' );

$mockThis->override( diag => sub { [ 'ERROR' ] } );
ok( !$METHOD_REF->( 'dir', [ 'file' ] ), 'invalid arguments, comparison rejected' );
