use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

my $mockThis = mock $CLASS => (
  override => [
    _show_failure => sub {},
    _show_result  => sub { !@{ shift->diag } },
  ]
);

const my @FILE_LIST => ( qw( file0 file1 ) );
path( $TEMP_DIR )->child( $_ )->touch foreach @FILE_LIST;

plan( 2 );

ok(  $METHOD_REF->( $TEMP_DIR, \@FILE_LIST ), 'comparison performed' );
ok( !$METHOD_REF->( $TEMP_DIR, {} ),          'invalid arguments, comparison rejected' );
