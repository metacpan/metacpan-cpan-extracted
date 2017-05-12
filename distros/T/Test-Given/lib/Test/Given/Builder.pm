package Test::Given::Builder;
use strict;
use warnings;

use parent 'Test::Builder::Module';

my $CLASS = __PACKAGE__;

our @EXPORT = qw(ok diag plan);

# suppress message from ok
sub ok {
  my ($passed, $name) = @_;
  my $tb = $CLASS->builder;
  my $no_diag = !!$tb->no_diag();
  $tb->no_diag(1);
  local $ENV{HARNESS_ACTIVE} = '';
  $tb->ok($passed, $name);
  $tb->no_diag($no_diag);
  return $passed;
}

sub diag { $CLASS->builder->diag(@_) }
sub plan { $CLASS->builder->plan(@_) }
