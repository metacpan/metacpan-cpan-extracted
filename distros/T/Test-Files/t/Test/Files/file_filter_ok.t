use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

my $mock_this = mock $CLASS => ( override => [ _compare_ok => sub {} ] );

plan( 1 );

is( $METHOD_REF->( 'file', 'string', sub {} ), undef, 'comparison performed' );
