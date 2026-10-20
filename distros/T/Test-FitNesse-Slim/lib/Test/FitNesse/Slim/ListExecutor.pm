package Test::FitNesse::Slim::ListExecutor;

use strict;
use warnings;

use Test::FitNesse::Slim::Statement;
use Test::FitNesse::Slim::StatementExecutor;

sub new {
  my($class,%options) = @_;
  my $executor = Test::FitNesse::Slim::StatementExecutor->new(%options);
  bless { EXECUTOR => $executor } => $class;
}

sub executor { $_[0]->{EXECUTOR} }

sub execute {
  my($self,@statements) = @_;
  $self->execute_with(undef, @statements);
}

sub execute_with {
  my($self,$after_statement,@statements) = @_;
  my $executor = $self->executor;
  my @results;
  for my $statement (@statements) {
    last if $executor->stop_requested;
    my $result = Test::FitNesse::Slim::Statement->execute($executor, @$statement);
    push @results, $result;
    $after_statement->($statement,$result) if $after_statement;
  }
  $executor->reset_stop_requested;
  @results;
}

1;

=head1 NAME

Test::FitNesse::Slim::ListExecutor - Execute a decoded batch of SLiM instructions

=head1 DESCRIPTION

The list executor owns one L<Test::FitNesse::Slim::StatementExecutor> for a protocol
session. It applies instructions in order, stops the current batch when a
FitNesse stop marker is raised, and resets that marker before the next
batch. It is an internal server component rather than a fixture API.

=head1 METHODS

=head2 new

    my $executor = Test::FitNesse::Slim::ListExecutor->new(%options);

Create a session executor. C<statement_timeout> is forwarded to the
statement executor and limits each fixture invocation when defined.

=head2 executor

Return the underlying statement executor. The method is used by the server
and integration tests to inspect session state.

=head2 execute

Execute decoded statement array references in order and return their
result array references. Each instruction is handled independently by
L<Test::FitNesse::Slim::Statement>.

=head2 execute_with

    my @results = $executor->execute_with($after_statement, @statements);

Execute a batch and optionally invoke C<$after_statement> with each
statement and result after execution. The callback is used by pipe output
tunneling; its exceptions propagate to the server.

=cut
