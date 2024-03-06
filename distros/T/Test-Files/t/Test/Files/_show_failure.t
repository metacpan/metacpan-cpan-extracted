use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

my $mock_test_builder = mock 'Test::Builder' => ( override => [ diag => sub {}, ok => sub {} ] );
my $self              = $CLASS->_init;

plan( 2 );

ok( !$self->$METHOD,              'empty message' );
ok( !$self->$METHOD( 'message' ), 'non-empty message' );
