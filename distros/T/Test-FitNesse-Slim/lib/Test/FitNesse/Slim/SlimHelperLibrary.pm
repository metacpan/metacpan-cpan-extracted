package Test::FitNesse::Slim::SlimHelperLibrary;

use strict;
use warnings;

sub new {
  my($class,$instances) = @_;
  bless {
    instances => $instances,
    stack     => [],
  } => $class;
}

sub get_fixture {
  my($self) = @_;
  my $fixture = $self->{instances}{scriptTableActor};
  die "NO_INSTANCE scriptTableActor." unless defined $fixture;
  $fixture;
}

sub push_fixture {
  my($self) = @_;
  push @{ $self->{stack} }, $self->get_fixture;
  return;
}

sub pop_fixture {
  my($self) = @_;
  die "EmptyStackException" unless @{ $self->{stack} };
  $self->{instances}{scriptTableActor} = pop @{ $self->{stack} };
  return;
}

1;

=head1 NAME

Test::FitNesse::Slim::SlimHelperLibrary - Maintain FitNesse script-table fixture state

=head1 DESCRIPTION

Each statement executor creates a private helper-library instance. Its
stack saves and restores the current C<scriptTableActor> reference used by
FitNesse script tables. The stack belongs to one SLiM session and preserves
object identity.

=head1 METHODS

=head2 new

    my $library = Test::FitNesse::Slim::SlimHelperLibrary->new(\%instances);

Create a helper bound to the executor's instance hash. The hash is retained
by reference so fixture changes are visible to helper operations.

=head2 get_fixture

Return the current C<scriptTableActor>. If no actor is registered, throw
the FitNesse-compatible C<NO_INSTANCE> error.

=head2 push_fixture

Save the current fixture reference on the helper's LIFO stack. Return no
value.

=head2 pop_fixture

Restore the most recently saved fixture. An empty stack throws
C<EmptyStackException> and leaves the instance hash unchanged.

=cut
