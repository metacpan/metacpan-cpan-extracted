package Fitnesse::Slim::Test::CreationLifecycle;

use strict;
use warnings;
use Scalar::Util qw(refaddr);

sub new {
  my ($class, $mode, $id, $value) = @_;
  die "ConstructorFailure: refused construction\n" if $mode eq 'constructor-failure';
  bless { mode => $mode, id => $id, value => $value }, $class;
}

sub set_statement_executor {
  my ($self, $executor) = @_;
  $self->{executor} = $executor;
  my $registered = $executor->instance($self->{id});
  $self->{hook_saw_registration} = $registered
    && refaddr($registered) == refaddr($self);
  die "HookFailure: refused initialization\n"
    if $self->{mode} eq 'hook-failure';
}

sub value { $_[0]{value} }
sub identify { $_[0]{value} }
sub hook_saw_registration { $_[0]{hook_saw_registration} ? 'true' : 'false' }
sub self { $_[0] }
sub same_as { refaddr($_[0]) == refaddr($_[1]) ? 'same' : 'different' }

1;
