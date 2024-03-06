use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

my $mock_this = mock $CLASS => ( override => [ _compare_ok => sub { shift } ] );

plan( 1 );

isa_ok( $METHOD_REF->( 'file', 'string' ), $CLASS );
