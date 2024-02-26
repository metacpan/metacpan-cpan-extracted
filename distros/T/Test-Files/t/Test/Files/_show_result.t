use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Builder::Tester tests => 2;
use Test::Expander;

my $mock_this = mock $CLASS => ( override => [ _show_failure => sub {} ] );

my $title;

$title = 'success reported';
test_out( "ok 1 - $title" );
$METHOD_REF->( 1, $title );
test_test( title => $title );

$title = 'failure reported';
test_out();
$METHOD_REF->( 0, $title );
test_test( title => $title );
