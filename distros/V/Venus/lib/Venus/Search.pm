package Venus::Search;

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

# BUILDERS

sub build_self {
  my ($self, $data) = @_;

  $self->flags('') if !$self->flags;
  $self->regexp(qr//) if !$self->regexp;
  $self->string('') if !$self->string;

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

sub evaluate {
  my ($self) = @_;

  my $captures = 0;
  my $flags = $self->flags;
  my @matches = ();
  my $regexp = $self->regexp;
  my $string = $self->string;
  my $initial = "$string";

  local $@;
  eval join ';', (
    '$captures = (' . '$string =~ m/$regexp/' . ($flags // '') . ')',
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

sub count {
  my ($self) = @_;

  my $evaluation = $self->encased('evaluation') || $self->evaluate;

  return $evaluation->[2];
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

Venus::Search - Search Class

=cut

=head1 ABSTRACT

Search Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Search;

  my $search = Venus::Search->new(
    string => 'hello world',
    regexp => '(hello)',
  );

  # $search->captures;

=cut

=head1 DESCRIPTION

This package provides methods for manipulating regexp search data.

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

  my $captures = $search->captures;

  # ["hello"]

=back

=cut

=head2 count

  count() (number)

The count method returns the number of matches found in the result object which
contains information about the results of the regular expression operation.

I<Since C<0.01>>

=over 4

=item count example 1

  # given: synopsis;

  my $count = $search->count;

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

  my $evaluate = $search->evaluate;

  # ["(hello)", "hello world", 1, [0, 0], [5, 5], {}, "hello world"]

=back

=over 4

=item evaluate example 2

  package main;

  use Venus::Search;

  my $search = Venus::Search->new(
    string => 'hello world',
    regexp => 'hello:)',
  );

  my $evaluate = $search->evaluate;

  # Exception! (isa Venus::Search::Error) (see error_on_evaluate)

=back

=over 4

=item B<may raise> L<Venus::Search::Error> C<on.evaluate>

  package main;

  use Venus::Search;

  my $search = Venus::Search->new(
    string => 'hello world',
    regexp => 'world',
    flags => 'i',
  );

  $search->evaluate;

  $search->flags('q');

  $search->evaluate;

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

  my $explain = $search->explain;

  # "hello world"

=back

=cut

=head2 get

  get() (string)

The get method returns the subject of the regular expression operation.

I<Since C<0.01>>

=over 4

=item get example 1

  # given: synopsis;

  my $get = $search->get;

  # "hello world"

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

  my $initial = $search->initial;

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

  my $last_match_end = $search->last_match_end;

  # [5, 5]

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

  my $last_match_start = $search->last_match_start;

  # [0, 0]

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

  my $matched = $search->matched;

  # "hello"

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

  my $named_captures = $search->named_captures;

  # {}

=back

=over 4

=item named_captures example 2

  package main;

  use Venus::Search;

  my $search = Venus::Search->new(
    string => 'hello world',
    regexp => '(?<locale>world)',
  );

  my $named_captures = $search->named_captures;

  # { locale => ["world"] }

=back

=cut

=head2 new

  new(any @args) (Venus::Search)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Search;

  my $new = Venus::Search->new;

  # bless(..., "Venus::Search")

=back

=over 4

=item new example 2

  package main;

  use Venus::Search;

  my $new = Venus::Search->new(
    string => 'hello world',
    regexp => '(hello)',
  );

  # bless(..., "Venus::Search")

=back

=cut

=head2 postmatched

  postmatched() (maybe[string])

The postmatched method returns the portion of the string after the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

I<Since C<0.01>>

=over 4

=item postmatched example 1

  # given: synopsis;

  my $postmatched = $search->postmatched;

  # " world"

=back

=cut

=head2 prematched

  prematched() (maybe[string])

The prematched method returns the portion of the string before the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

I<Since C<0.01>>

=over 4

=item prematched example 1

  # given: synopsis;

  my $prematched = $search->prematched;

  # ""

=back

=cut

=head2 set

  set(string $string) (string)

The set method sets the subject of the regular expression operation.

I<Since C<0.01>>

=over 4

=item set example 1

  # given: synopsis;

  my $set = $search->set('hello universe');

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

  my $result = "$search";

  # "hello world"

B<example 2>

  # given: synopsis;

  my $result = "$search, $search";

  # "hello world, hello world"

=back

=over 4

=item operation: C<(.)>

This package overloads the C<.> operator.

B<example 1>

  # given: synopsis;

  my $result = $search . ', welcome';

  # "hello world, welcome"

=back

=over 4

=item operation: C<(eq)>

This package overloads the C<eq> operator.

B<example 1>

  # given: synopsis;

  my $result = $search eq 'hello world';

  # 1

=back

=over 4

=item operation: C<(ne)>

This package overloads the C<ne> operator.

B<example 1>

  # given: synopsis;

  my $result = $search ne 'Hello world';

  # 1

=back

=over 4

=item operation: C<(qr)>

This package overloads the C<qr> operator.

B<example 1>

  # given: synopsis;

  my $result = 'hello world, welcome' =~ qr/$search/;

  # 1

=back

=over 4

=item operation: C<(~~)>

This package overloads the C<~~> operator.

B<example 1>

  # given: synopsis;

  my $result = $search ~~ 'hello world';

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