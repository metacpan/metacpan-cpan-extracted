use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Builder::Tester tests => 2;

use Test::Expander;
use Test::Expander::Constants qw( $MSG_UNEXPECTED_EXCEPTION );

my $title = 'execution succeeds';
test_out( "ok 1 - $title" );
lives_ok( sub {}, $title );
test_test( $title );

$title = 'execution fails';
test_out( "ok 1 - $title" );
my $error     = 'DIE TEST';
my $mock_this = mock $CLASS => (
  override => [
    diag => sub { is( $_[ 0 ], $MSG_UNEXPECTED_EXCEPTION . $error . "\n", $title ) },
    ok   => sub ($;$@) { 1 },
  ],
);
lives_ok { die( $error . "\n" ) } $title;
test_test( $title );
