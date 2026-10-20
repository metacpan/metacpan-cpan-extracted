package Test::FitNesse::Slim::Statement;

use strict;
use warnings;

our $EXCEPTION_TAG;
*EXCEPTION_TAG = \"__EXCEPTION__:";

sub new {
  my $class = shift;

  my $self = bless {} => $class;
  if (@_) {
    $self->{STATEMENT} = [ @_ ];
  }

  $self;
}

sub execute {
  my($class,$executor,@statement) = @_;
  Test::FitNesse::Slim::Statement->new(@statement)->exec($executor);
}

sub exec {
  my($self,$executor) = @_;

  my($id,$instr,@args) = $self->statement;
  my %arity = (import => [1,1], make => [2,undef], call => [2,undef],
               callAndAssign => [3,undef], assign => [2,2]);
  my $valid = defined($id) && !ref($id) && defined($instr) && !ref($instr)
    && exists($arity{$instr}) && @args >= $arity{$instr}[0]
    && (!defined($arity{$instr}[1]) || @args <= $arity{$instr}[1]);
  return $self->malformed_instruction($id) unless $valid;
  my $meth = "do_" . $instr;
  my $result = eval { $self->$meth($executor, $id, @args) };
  return $result if $@ eq "";

  my $list = join ", ", map qq["$_"], $id, $instr, @args;
  [ $id => $Test::FitNesse::Slim::Statement::EXCEPTION_TAG
             . "message:<<INVALID_STATEMENT: [$list]>>" ];
}

sub statement { @{ $_[0]->{STATEMENT} } }

sub do_import {
  my($self,$executor,$id,$prefix) = @_;
  $prefix =~ s/\s*<a title=.*//;  # FIXME
  $executor->add_import($prefix);

  [ $id => "OK" ];
}

sub do_make {
  my($self,$executor,$id,$instance,$class,@args) = @_;

  [ $id => $executor->create($instance, $class, \@args) ];
}

sub do_call {
  my($self,$executor,$id,$instance,$f,@args) = @_;

  return $self->malformed_instruction($id)
    unless defined $instance && defined $f;

  [ $id => $executor->call($instance, $f, @args) ];
}

sub do_callAndAssign {
  my($self,$executor,$id,$symbol,$instance,$f,@args) = @_;

  return $self->malformed_instruction($id)
    if grep !defined($_), $symbol, $instance, $f;

  [ $id => $executor->call_and_assign($symbol, $instance, $f, @args) ];
}

sub do_assign {
  my($self,$executor,$id,$symbol,$value) = @_;

  return $self->malformed_instruction($id)
    unless @_ == 5 && defined $symbol;

  $executor->set_symbol($symbol, $value);
  [ $id => "OK" ];
}

sub malformed_instruction {
  my($self,$id) = @_;

  my @parts;
  my $size = 0;
  for my $word ($self->statement) {
    my $value = defined($word) && !ref($word) ? $word : "";
    $value = substr($value,0,128) . "..." if length($value) > 128;
    my $part = qq["$value"];
    if ($size + length($part) > 512) {
      push @parts, '...';
      last;
    }
    push @parts,$part;
    $size += length($part) + 2;
  }
  my $statement = join ", ", @parts;
  [ $id => $Test::FitNesse::Slim::Statement::EXCEPTION_TAG
             . "message:<<MALFORMED_INSTRUCTION [$statement]>>" ];
}

1;

=head1 NAME

Test::FitNesse::Slim::Statement - Validate and execute one SLiM instruction

=head1 DESCRIPTION

This internal adapter validates the SLiM instruction name and its
protocol-level minimum argument count, then delegates to the corresponding
method on L<Test::FitNesse::Slim::StatementExecutor>. Fixture signature arity and
conversion are checked by the statement executor. Fixture failures are
returned as structured C<__EXCEPTION__:> result values; malformed
instructions use the protocol's C<MALFORMED_INSTRUCTION> category.

=head1 METHODS

=head2 new

    my $statement = Test::FitNesse::Slim::Statement->new(@instruction_fields);

Store one decoded instruction. The first fields are its identifier and
operation; remaining values are operation arguments.

=head2 execute

    my $result = Test::FitNesse::Slim::Statement->execute($executor, @fields);

Validate and execute one instruction using the supplied statement
executor. Return a two-element array reference containing the instruction
identifier and result.

=head2 exec

Execute the instruction stored by C<new>. Invalid operations or protocol
arity return a malformed-instruction result. Fixture exceptions are
converted to the standard SLiM exception representation.

=head2 statement

Return the stored instruction fields in order.

=head1 INSTRUCTION METHODS

=head2 do_import

Register a fixture package prefix through the statement executor and
return C<OK>, or an exception result if registration fails.

=head2 do_make

Construct and register an actor or library fixture using the executor's
creation and failure-containment rules.

=head2 do_call

Invoke one fixture method and return its result or structured exception.

=head2 do_callAndAssign

Invoke a fixture method, assign its result to a SLiM symbol, and return the
display value.

=head2 do_assign

Assign a decoded value to a symbol and return C<OK>.

=head2 malformed_instruction

Return a C<MALFORMED_INSTRUCTION> result. The diagnostic bounds the
reported instruction text to avoid echoing unbounded protocol input.

=cut
