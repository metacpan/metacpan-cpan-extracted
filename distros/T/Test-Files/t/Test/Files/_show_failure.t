use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Builder::Tester tests => 1;
use Test::Expander;

const my $MESSAGE => 'message';
const my $SEP     => $^O eq 'MSWin32' ? '\\' : '/';
const my $TITLE   => 'failure reported';

test_out( "not ok 1 - $TITLE" );
test_err(
  "#   Failed test '$TITLE'",
  '#   at ' . path( $TEST_FILE )->relative( cwd() ) =~ s{ [/\\] }{$SEP}grx . ' line ' . line_num( +5 ) . '.',
  "# $MESSAGE"
);
$METHOD_REF->( $TITLE, $MESSAGE );
test_test( title => $TITLE );
