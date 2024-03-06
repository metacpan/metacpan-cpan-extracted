use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

my $mock_this = mock $CLASS => (
  override => [
    _show_failure => sub {},
    _show_result  => sub { !@{ shift->diag } },
  ]
);

const my $EXPECTED_FILE => path( $TEMP_DIR )->child( 'expected_file' );
const my $GOT_FILE      => path( $TEMP_DIR )->child( 'got_file' );

plan( 4 );

ok( !$METHOD_REF->( $GOT_FILE, $EXPECTED_FILE, [] ),  'invalid optional arguments' );

ok( !$METHOD_REF->( $GOT_FILE, $EXPECTED_FILE ),      'file info cannot be gathered' );

$EXPECTED_FILE->spew( 'expected_content' );
$GOT_FILE     ->spew( 'got_content' );
ok( !$METHOD_REF->( $GOT_FILE, $EXPECTED_FILE ),      'expected file passed, differences detected' );

ok( !$METHOD_REF->( $GOT_FILE, \'expected_content' ), 'expected content passed, differences detected' );
