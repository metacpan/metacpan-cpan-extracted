package Venus::Fault;

use 5.018;

use strict;
use warnings;

# OVERLOADS

use overload (
  '""' => 'explain',
  'eq' => sub{$_[0]->{message} eq "$_[1]"},
  'ne' => sub{$_[0]->{message} ne "$_[1]"},
  'qr' => sub{qr/@{[quotemeta($_[0]->{message})]}/},
  '~~' => 'explain',
  fallback => 1,
);

# METHODS

sub new {
  return bless({message => $_[1] || 'Exception!'})->trace;
}

sub explain {
  my ($self) = @_;

  $self->trace(1) if !@{$self->frames};

  my $frames = $self->{frames};

  my $file = $frames->[0][1];
  my $line = $frames->[0][2];
  my $pack = $frames->[0][0];
  my $subr = $frames->[0][3];

  my $message = $self->{message};

  my @stacktrace = ("$message in $file at line $line");

  push @stacktrace, 'Traceback (reverse chronological order):' if @$frames > 1;

  @stacktrace = (join("\n\n", grep defined, @stacktrace), '');

  for (my $i = 1; $i < @$frames; $i++) {
    my $pack = $frames->[$i][0];
    my $file = $frames->[$i][1];
    my $line = $frames->[$i][2];
    my $subr = $frames->[$i][3];

    push @stacktrace, "$subr\n  in $file at line $line";
  }

  return join "\n", @stacktrace, "";
}

sub frames {
  my ($self) = @_;

  return $self->{frames} //= [];
}

sub throw {
  my ($self, @args) = @_;

  $self = $self->new(@args) if !ref $self;

  die $self;
}

sub trace {
  my ($self, $offset, $limit) = @_;

  my $frames = $self->frames;

  @$frames = ();

  for (my $i = $offset // 1; my @caller = caller($i); $i++) {
    push @$frames, [@caller];

    last if defined $limit && $i + 1 == $offset + $limit;
  }

  return $self;
}

1;



=head1 NAME

Venus::Fault - Fault Class

=cut

=head1 ABSTRACT

Fault Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Fault;

  my $fault = Venus::Fault->new;

  # $fault->throw;

=cut

=head1 DESCRIPTION

This package represents a generic system error (exception object).

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 explain

  explain() (string)

The explain method returns the error message and is used in stringification
operations.

I<Since C<1.80>>

=over 4

=item explain example 1

  # given: synopsis;

  my $explain = $fault->explain;

  # "Exception! in ...

=back

=cut

=head2 frames

  frames() (arrayref)

The frames method returns the compiled and stashed stack trace data.

I<Since C<1.80>>

=over 4

=item frames example 1

  # given: synopsis;

  my $frames = $fault->frames;

  # [
  #   ...
  #   [
  #     "main",
  #     "t/Venus_Fault.t",
  #     ...
  #   ],
  # ]

=back

=cut

=head2 new

  new(any @args) (Venus::Fault)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Fault;

  my $new = Venus::Fault->new;

  # bless(..., "Venus::Fault")

=back

=over 4

=item new example 2

  package main;

  use Venus::Fault;

  my $new = Venus::Fault->new('Oops!');

  # bless(..., "Venus::Fault")

=back

=cut

=head2 throw

  throw(string $message) (Venus::Fault)

The throw method throws an error if the invocant is an object, or creates an
error object using the arguments provided and throws the created object.

I<Since C<1.80>>

=over 4

=item throw example 1

  # given: synopsis;

  my $throw = $fault->throw;

  # bless({ ... }, 'Venus::Fault')

=back

=cut

=head2 trace

  trace(number $offset, number $limit) (Venus::Fault)

The trace method compiles a stack trace and returns the object. By default it
skips the first frame.

I<Since C<1.80>>

=over 4

=item trace example 1

  # given: synopsis;

  my $trace = $fault->trace;

  # bless({ ... }, 'Venus::Fault')

=back

=over 4

=item trace example 2

  # given: synopsis;

  my $trace = $fault->trace(0, 1);

  # bless({ ... }, 'Venus::Fault')

=back

=over 4

=item trace example 3

  # given: synopsis;

  my $trace = $fault->trace(0, 2);

  # bless({ ... }, 'Venus::Fault')

=back

=cut

=head1 OPERATORS

This package overloads the following operators:

=cut

=over 4

=item operation: C<("")>

This package overloads the C<""> operator.

B<example 1>

  # given: synopsis;

  my $result = "$fault";

  # "Exception!"

=back

=over 4

=item operation: C<(eq)>

This package overloads the C<eq> operator.

B<example 1>

  # given: synopsis;

  my $result = $fault eq 'Exception!';

  # 1

=back

=over 4

=item operation: C<(ne)>

This package overloads the C<ne> operator.

B<example 1>

  # given: synopsis;

  my $result = $fault ne 'exception!';

  # 1

=back

=over 4

=item operation: C<(qr)>

This package overloads the C<qr> operator.

B<example 1>

  # given: synopsis;

  my $test = 'Exception!' =~ qr/$fault/;

  # 1

=back

=over 4

=item operation: C<(~~)>

This package overloads the C<~~> operator.

B<example 1>

  # given: synopsis;

  my $result = $fault ~~ 'Exception!';

  # 1

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut