package Venus::Replace;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Encaseable';
with 'Venus::Role::Explainable';

# OVERLOADS

use overload (
  '""' => 'explain',
  'eq' => sub{"$_[0]" eq "$_[1]"},
  'ne' => sub{"$_[0]" ne "$_[1]"},
  'qr' => sub{qr{@{[quotemeta("$_[0]")]}}},
  '~~' => 'explain',
  fallback => 1,
);

# ATTRIBUTES

attr 'flags';
attr 'regexp';
attr 'string';
attr 'substr';

# BUILDERS

sub build_self {
  my ($self, $data) = @_;

  $self->flags('') if !$self->flags;
  $self->regexp(qr//) if !defined $self->regexp;
  $self->string('') if !defined $self->string;
  $self->substr('') if !defined $self->substr;

  return $self;
}

# METHODS

sub captures {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  my $string = $self->initial;
  my $last_match_start = $self->last_match_start;
  my $last_match_end = $self->last_match_end;

  my $captures = [];

  for (my $i = 1; $i < @$last_match_end; $i++) {
    my $start = $last_match_start->[$i] || 0;
    my $end = $last_match_end->[$i] || 0;

    push @$captures, substr $string, $start, $end - $start;
  }

  return wantarray ? (@$captures) : $captures;
}

sub count {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  return $evaluation->[2];
}

sub evaluate {
  my ($self) = @_;

  my $captures = 0;
  my $flags = $self->flags;
  my @matches = ();
  my $regexp = $self->regexp;
  my $string = $self->string;
  my $substr = $self->substr;
  my $initial = "$string";

  local $@;
  eval join ';', (
    '$captures = (' . '$string =~ s/$regexp/$substr/' . ($flags // '') . ')',
    '@matches = ([@-], [@+], {%-})',
  );

  my $error = $@;

  if ($error) {
    $self->error_on_evaluate({error => $error})->throw;
  }

  return $self->recase(evaluation => [
    $regexp,
    $string,
    $captures,
    @matches,
    $initial,
  ]);
}

sub explain {
  my ($self) = @_;

  return $self->get;
}

sub get {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  return $evaluation->[1];
}

sub initial {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  return $evaluation->[6];
}

sub last_match_end {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  return $evaluation->[4];
}

sub last_match_start {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  return $evaluation->[3];
}

sub matched {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  my $string = $self->initial;
  my $last_match_start = $self->last_match_start;
  my $last_match_end = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end = $last_match_end->[0] || 0;

  return substr $string, $start, $end - $start;
}

sub named_captures {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  return $evaluation->[5];
}

sub prematched {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  my $string = $self->initial;
  my $last_match_start = $self->last_match_start;
  my $last_match_end = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end = $last_match_end->[0] || 0;

  return substr $string, 0, $start;
}

sub postmatched {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  my $string = $self->initial;
  my $last_match_start = $self->last_match_start;
  my $last_match_end = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end = $last_match_end->[0] || 0;

  return substr $string, $end;
}

sub set {
  my ($self, $string) = @_;

  $self->string($string);

  my $evaluation = $self->evaluate;

  return $evaluation->[1];
}

# ERRORS

sub error_on_evaluate {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  $error->name('on.evaluate');
  $error->message($data->{error});
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

1;



=head1 NAME

Venus::Replace - Replace Class

=cut

=head1 ABSTRACT

Replace Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Replace;

  my $replace = Venus::Replace->new(
    string => 'hello world',
    regexp => '(world)',
    substr => 'universe',
  );

  # $replace->captures;

=cut

=head1 DESCRIPTION

This package provides methods for manipulating regexp replacement data.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 flags

  flags(Str)

This attribute is read-write, accepts C<(Str)> values, is optional, and defaults to C<''>.

=cut

=head2 regexp

  regexp(Regexp)

This attribute is read-write, accepts C<(Regexp)> values, is optional, and defaults to C<qr//>.

=cut

=head2 string

  string(Str)

This attribute is read-write, accepts C<(Str)> values, is optional, and defaults to C<''>.

=cut

=head2 substr

  substr(Str)

This attribute is read-write, accepts C<(Str)> values, is optional, and defaults to C<''>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Encaseable>

L<Venus::Role::Explainable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 captures

  captures() (arrayref)

The captures method returns the capture groups from the result object which
contains information about the results of the regular expression operation.
This method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item captures example 1

  # given: synopsis;

  my $captures = $replace->captures;

  # ["world"]

=back

=cut

=head2 count

  count() (number)

The count method returns the number of match occurrences from the result object
which contains information about the results of the regular expression
operation.

I<Since C<0.01>>

=over 4

=item count example 1

  # given: synopsis;

  my $count = $replace->count;

  # 1

=back

=cut

=head2 evaluate

  evaluate() (arrayref)

The evaluate method performs the regular expression operation and returns an
arrayref representation of the results.

I<Since C<0.01>>

=over 4

=item evaluate example 1

  # given: synopsis;

  my $evaluate = $replace->evaluate;

  # [
  #   "(world)",
  #   "hello universe",
  #   1,
  #   [6, 6],
  #   [11, 11],
  #   {},
  #   "hello world",
  # ]

=back

=over 4

=item evaluate example 2

  package main;

  use Venus::Replace;

  my $replace = Venus::Replace->new(
    string => 'hello world',
    regexp => 'world)(',
    substr => 'universe',
  );

  my $evaluate = $replace->evaluate;

  # Exception! (isa Venus::Replace::Error) (see error_on_evaluate)

=back

=over 4

=item B<may raise> L<Venus::Replace::Error> C<on.evaluate>

  package main;

  use Venus::Replace;

  my $replace = Venus::Replace->new(
    string => 'hello world',
    regexp => 'world',
    substr => 'universe',
    flags => 'i',
  );

  $replace->evaluate;

  $replace->flags('q');

  $replace->evaluate;

  # Error! (on.evaluate)

=back

=cut

=head2 explain

  explain() (string)

The explain method returns the subject of the regular expression operation and
is used in stringification operations.

I<Since C<0.01>>

=over 4

=item explain example 1

  # given: synopsis;

  my $explain = $replace->explain;

  # "hello universe"

=back

=cut

=head2 get

  get() (string)

The get method returns the subject of the regular expression operation.

I<Since C<0.01>>

=over 4

=item get example 1

  # given: synopsis;

  my $get = $replace->get;

  # "hello universe"

=back

=cut

=head2 initial

  initial() (string)

The initial method returns the unaltered string from the result object which
contains information about the results of the regular expression operation.

I<Since C<0.01>>

=over 4

=item initial example 1

  # given: synopsis;

  my $initial = $replace->initial;

  # "hello world"

=back

=cut

=head2 last_match_end

  last_match_end() (maybe[within[arrayref, number]])

The last_match_end method returns an array of offset positions into the string
where the capture(s) stopped matching from the result object which contains
information about the results of the regular expression operation.

I<Since C<0.01>>

=over 4

=item last_match_end example 1

  # given: synopsis;

  my $last_match_end = $replace->last_match_end;

  # [11, 11]

=back

=cut

=head2 last_match_start

  last_match_start() (maybe[within[arrayref, number]])

The last_match_start method returns an array of offset positions into the
string where the capture(s) matched from the result object which contains
information about the results of the regular expression operation.

I<Since C<0.01>>

=over 4

=item last_match_start example 1

  # given: synopsis;

  my $last_match_start = $replace->last_match_start;

  # [6, 6]

=back

=cut

=head2 matched

  matched() (maybe[string])

The matched method returns the portion of the string that matched from the
result object which contains information about the results of the regular
expression operation.

I<Since C<0.01>>

=over 4

=item matched example 1

  # given: synopsis;

  my $matched = $replace->matched;

  # "world"

=back

=cut

=head2 named_captures

  named_captures() (hashref)

The named_captures method returns a hash containing the requested named regular
expressions and captured string pairs from the result object which contains
information about the results of the regular expression operation.

I<Since C<0.01>>

=over 4

=item named_captures example 1

  # given: synopsis;

  my $named_captures = $replace->named_captures;

  # {}

=back

=over 4

=item named_captures example 2

  package main;

  use Venus::Replace;

  my $replace = Venus::Replace->new(
    string => 'hello world',
    regexp => '(?<locale>world)',
    substr => 'universe',
  );

  my $named_captures = $replace->named_captures;

  # { locale => ["world"] }

=back

=cut

=head2 new

  new(any @args) (Venus::Replace)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Replace;

  my $new = Venus::Replace->new;

  # bless(..., "Venus::Replace")

=back

=over 4

=item new example 2

  package main;

  use Venus::Replace;

  my $new = Venus::Replace->new(
    string => 'hello world',
    regexp => '(world)',
    substr => 'universe',
  );

  # bless(..., "Venus::Replace")

=back

=cut

=head2 postmatched

  postmatched() (Maybe[string])

The postmatched method returns the portion of the string after the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

I<Since C<0.01>>

=over 4

=item postmatched example 1

  # given: synopsis;

  my $postmatched = $replace->postmatched;

  # ""

=back

=cut

=head2 prematched

  prematched() (Maybe[string])

The prematched method returns the portion of the string before the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

I<Since C<0.01>>

=over 4

=item prematched example 1

  # given: synopsis;

  my $prematched = $replace->prematched;

  # "hello "

=back

=cut

=head2 set

  set(string $data) (string)

The set method sets the subject of the regular expression operation.

I<Since C<0.01>>

=over 4

=item set example 1

  # given: synopsis;

  my $set = $replace->set('hello universe');

  # "hello universe"

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

  my $result = "$replace";

  # "hello universe"

B<example 2>

  # given: synopsis;

  my $result = "$replace, $replace";

  # "hello universe, hello universe"

=back

=over 4

=item operation: C<(.)>

This package overloads the C<.> operator.

B<example 1>

  # given: synopsis;

  my $result = $replace . ', welcome';

  # "hello universe, welcome"

=back

=over 4

=item operation: C<(eq)>

This package overloads the C<eq> operator.

B<example 1>

  # given: synopsis;

  my $result = $replace eq 'hello universe';

  # 1

=back

=over 4

=item operation: C<(ne)>

This package overloads the C<ne> operator.

B<example 1>

  # given: synopsis;

  my $result = $replace ne 'Hello universe';

  # 1

=back

=over 4

=item operation: C<(qr)>

This package overloads the C<qr> operator.

B<example 1>

  # given: synopsis;

  my $result = 'hello universe, welcome' =~ qr/$replace/;

  # 1

=back

=over 4

=item operation: C<(~~)>

This package overloads the C<~~> operator.

B<example 1>

  # given: synopsis;

  my $result = $replace ~~ 'hello universe';

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