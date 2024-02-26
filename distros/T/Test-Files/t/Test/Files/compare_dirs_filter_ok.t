use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

my $diag;
my $mock_this = mock $CLASS => (
  override => [
    _compare_dirs     => sub {},
    _show_failure     => sub { $_[ 1 ] },
    _validate_options => sub { $diag },
  ]
);

plan( 2 );

$diag = undef;
is( $METHOD_REF->( 'first_dir', 'second_dir', sub {} ), $diag, 'success' );

$diag = 'ERROR';
is( $METHOD_REF->( 'first_dir', 'second_dir', sub {} ), $diag, 'failure' );
