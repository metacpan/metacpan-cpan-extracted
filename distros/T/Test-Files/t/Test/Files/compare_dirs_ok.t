use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

plan( 2 );

subtest success => sub {
  plan( 2 );

  my $mock_this = mock $CLASS => (
    override => [
      _compare_dirs           => sub { pass( 'compared' ) },
      _validate_trailing_args => sub { shift },
    ]
  );

  lives_ok { $METHOD_REF->( 'first_dir', 'second_dir' ) } 'executed';
};

subtest failure => sub {
  plan( 2 );

  my $mock_this = mock $CLASS => (
    override => [
      _show_failure           => sub { pass( 'error detected' ) },
      _validate_trailing_args => sub { shift->diag( [ 'ERROR' ] ) },
    ]
  );

  lives_ok { $METHOD_REF->( 'first_dir', 'second_dir' ) } 'executed';
};
