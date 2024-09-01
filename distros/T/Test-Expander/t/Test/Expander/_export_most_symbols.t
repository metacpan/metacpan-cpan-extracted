use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander   -tempfile => {};
use Scalar::Readonly qw( readonly_off );

my $mockThis = mock $CLASS => ( override => [ _export_symbols => sub {} ] );

plan( 2 );

readonly_off( $Test::Expander::TEST_FILE );

subtest 'test file exists' => sub {
  plan( 2 );

  lives_ok { $METHOD_REF->( $TEMP_FILE ) }    'executed';
  is( $Test::Expander::TEST_FILE, $TEMP_FILE, q('$TEMP_FILE' set) );
};

subtest 'test file does not exist' => sub {
  plan( 2 );

  path( $TEMP_FILE )->remove;
  $Test::Expander::TEST_FILE = '';

  lives_ok { $METHOD_REF->( $TEMP_FILE ) } 'executed';
  is( $Test::Expander::TEST_FILE, '',      q('$TEMP_FILE' not set) );
};
