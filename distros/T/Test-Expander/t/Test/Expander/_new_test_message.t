## no critic (ProtectPrivateSubs RequireLocalizedPunctuationVars)

use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander::Constants qw( $FMT_NEW_FAILED $FMT_NEW_SUCCEEDED );
use constant TEST_CASES => {
  "'new' succeeded" => { exception => '',    output => $FMT_NEW_SUCCEEDED },
  "'new' failed"    => { exception => 'ABC', output => $FMT_NEW_FAILED },
};
use Test::Builder::Tester tests => scalar( keys( %{ TEST_CASES() } ) );

use Test::Expander;

foreach my $title ( keys( %{ TEST_CASES() } ) ) {
  test_out( "ok 1 - $title" );
  $@ = TEST_CASES->{ $title }->{ exception };
  my $expected = TEST_CASES->{ $title }->{ output } =~ s/%s/.*/gr;
  like( Test::Expander::_new_test_message( 'CLASS' ), qr/$expected/, $title );
  test_test( $title );
}
