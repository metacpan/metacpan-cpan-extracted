use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

my $mock_test_builder = mock 'Test::Builder' => ( override => [ ok => sub { 1 } ] );
my $mock_this         = mock $CLASS          => ( override => [ _show_failure => sub {} ] );
my $self              = $CLASS->_init;

plan( 2 );

ok( !$self->diag( [ 'message' ] )->$METHOD, 'failure' );
ok(  $self->diag( [] )           ->$METHOD, 'success' );
