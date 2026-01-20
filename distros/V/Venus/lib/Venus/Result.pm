package Venus::Result;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Buildable';
with 'Venus::Role::Tryable';
with 'Venus::Role::Catchable';

# ATTRIBUTES

attr 'issue';
attr 'value';

# BUILDERS

sub build_self {
  my ($self, $data) = @_;

  return $self;
}

# METHODS

sub attest {
  my ($self, $from, $accept) = @_;

  $from ||= 'value';

  my $value = $self->$from;

  require Venus::Assert;

  my $assert = Venus::Assert->new;

  $assert->name("Venus::Result#$from");

  $assert->expression($accept || 'any');

  return $assert->result($value);
}

sub check {
  my ($self, $from, $accept) = @_;

  $from ||= 'value';

  my $value = $self->$from;

  require Venus::Assert;

  my $assert = Venus::Assert->new;

  $assert->name("Venus::Result#$from");

  $assert->expression($accept || 'any');

  return $assert->valid($value);
}

sub invalid {
  my ($self, $issue) = @_;

  my $result = $self->class->new(issue => $issue);

  return $result;
}

sub is_invalid {
  my ($self) = @_;

  my $invalid = $self->is_valid ? false : true;

  return $invalid;
}

sub is_valid {
  my ($self) = @_;

  my $valid = $self->issue ? false : true;

  return $valid;
}

sub on_invalid {
  my ($self, $code, @args) = @_;

  return $self if !$code || !$self->issue;

  my ($issue, $value) = $self->catch($code, @args);

  my $result = $self->class->new($issue ? (issue => $issue) : (value => $value));

  return $result;
}

sub on_valid {
  my ($self, $code, @args) = @_;

  return $self if !$code || $self->issue;

  my ($issue, $value) = $self->catch($code, @args);

  my $result = $self->class->new($issue ? (issue => $issue) : (value => $value));

  return $result;
}

sub then {
  my ($self, $code, @args) = @_;

  return $self if !$code;

  my $method = $self->issue ? 'on_invalid' : 'on_valid';

  return $self->$method($code, @args);
}

sub valid {
  my ($self, $value) = @_;

  my $result = $self->class->new(value => $value);

  return $result;
}

1;



=head1 NAME

Venus::Result - Result Class

=cut

=head1 ABSTRACT

Result Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Result;

  my $result = Venus::Result->new;

  # $result->is_valid;

  # true

=cut

=head1 DESCRIPTION

This package provides a container for representing success and error states in
a more structured and predictable way, and a mechanism for chaining subsequent
operations.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 issue

  issue(any $issue) (any)

The issue attribute is read/write, accepts C<(any)> values, and is optional.

I<Since C<4.15>>

=over 4

=item issue example 1

  # given: synopsis;

  my $issue = $result->issue("Failed!");

  # "Failed!"

=back

=over 4

=item issue example 2

  # given: synopsis;

  # given: example-1 issue;

  $issue = $result->issue;

  # "Failed!"

=back

=cut

=head2 value

  value(any $value) (any)

The valid attribute is read/write, accepts C<(any)> values, and is optional.

I<Since C<4.15>>

=over 4

=item value example 1

  # given: synopsis;

  my $value = $result->value("Success!");

  # "Success!"

=back

=over 4

=item value example 2

  # given: synopsis;

  # given: example-1 value;

  $value = $result->value;

  # "Success!"

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

L<Venus::Role::Tryable>

L<Venus::Role::Catchable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 attest

  attest(string $name, string $expr) (any)

The attest method validates the value of the attribute named, i.e. L</issue> or
L</value>, using the L<Venus::Assert> expression provided and returns the
result.

I<Since C<4.15>>

=over 4

=item attest example 1

  # given: synopsis

  package main;

  my $attest = $result->attest;

  # undef

=back

=over 4

=item attest example 2

  # given: synopsis

  package main;

  $result->value("Success!");

  my $attest = $result->attest('value', 'number | string');

  # "Success!"

=back

=over 4

=item attest example 3

  # given: synopsis

  package main;

  my $attest = $result->attest('value', 'number | string');

  # Exception! (isa Venus::Check::Error)

=back

=over 4

=item attest example 4

  # given: synopsis

  package main;

  $result->issue("Failed!");

  my $attest = $result->attest('issue', 'number | string');

  # "Failed!"

=back

=over 4

=item attest example 5

  # given: synopsis

  package main;

  my $attest = $result->attest('issue', 'number | string');

  # Exception! (isa Venus::Check::Error)

=back

=cut

=head2 check

  check(string $name, string $expr) (boolean)

The check method validates the value of the attribute named, i.e. L</issue> or
L</value>, using the L<Venus::Assert> expression provided and returns the
true if the value is valid, and false otherwise.

I<Since C<4.15>>

=over 4

=item check example 1

  # given: synopsis

  package main;

  my $check = $result->check;

  # true

=back

=over 4

=item check example 2

  # given: synopsis

  package main;

  $result->value("Success!");

  my $check = $result->check('value', 'number | string');

  # true

=back

=over 4

=item check example 3

  # given: synopsis

  package main;

  my $check = $result->check('value', 'number | string');

  # false

=back

=over 4

=item check example 4

  # given: synopsis

  package main;

  $result->issue("Failed!");

  my $check = $result->check('issue', 'number | string');

  # true

=back

=over 4

=item check example 5

  # given: synopsis

  package main;

  my $check = $result->check('issue', 'number | string');

  # false

=back

=cut

=head2 invalid

  invalid(any $error) (Venus::Result)

The invalid method returns a L<Venus::Result> object representing an issue and
error state.

I<Since C<4.15>>

=over 4

=item invalid example 1

  package main;

  use Venus::Result;

  my $invalid = Venus::Result->invalid("Failed!");

  # bless(..., "Venus::Result")

=back

=cut

=head2 is_invalid

  is_invalid() (boolean)

The is_invalid method returns true if an error exists, and false otherwise.

I<Since C<4.15>>

=over 4

=item is_invalid example 1

  # given: synopsis;

  my $is_invalid = $result->is_invalid;

  # false

=back

=over 4

=item is_invalid example 2

  # given: synopsis;

  $result->value("Success!");

  my $is_invalid = $result->is_invalid;

  # false

=back

=over 4

=item is_invalid example 3

  # given: synopsis;

  $result->issue("Failed!");

  my $is_invalid = $result->is_invalid;

  # true

=back

=cut

=head2 is_valid

  is_valid() (boolean)

The is_valid method returns true if no error exists, and false otherwise.

I<Since C<4.15>>

=over 4

=item is_valid example 1

  # given: synopsis;

  my $is_valid = $result->is_valid;

  # true

=back

=over 4

=item is_valid example 2

  # given: synopsis;

  $result->value("Success!");

  my $is_valid = $result->is_valid;

  # true

=back

=over 4

=item is_valid example 3

  # given: synopsis;

  $result->issue("Failed!");

  my $is_valid = $result->is_valid;

  # false

=back

=cut

=head2 new

  new(hashref $data) (Venus::Result)

The new method returns a L<Venus::Result> object.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Result;

  my $new = Venus::Result->new;

  # bless(..., "Venus::Result")

=back

=over 4

=item new example 2

  package main;

  use Venus::Result;

  my $new = Venus::Result->new(value => "Success!");

  # bless(..., "Venus::Result")

=back

=over 4

=item new example 3

  package main;

  use Venus::Result;

  my $new = Venus::Result->new({value => "Success!"});

  # bless(..., "Venus::Result")

=back

=cut

=head2 on_invalid

  on_invalid(coderef $callback) (Venus::Result)

The on_invalid method chains an operations by passing the issue value of the
result to the callback provided and returns a L<Venus::Result> object.

I<Since C<4.15>>

=over 4

=item on_invalid example 1

  # given: synopsis;

  my $on_invalid = $result->on_invalid;

  # bless(..., "Venus::Result")

=back

=over 4

=item on_invalid example 2

  # given: synopsis;

  my $on_invalid = $result->on_invalid(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=back

=over 4

=item on_invalid example 3

  # given: synopsis;

  $result->issue("Failed!");

  my $on_invalid = $result->on_invalid(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=back

=over 4

=item on_invalid example 4

  # given: synopsis;

  $result->issue("Failed!");

  my $on_invalid = $result->on_invalid(sub{
    die "New failure!";
  });

  # bless(..., "Venus::Result")

=back

=cut

=head2 on_valid

  on_valid(coderef $callback) (Venus::Result)

The on_valid method chains an operations by passing the success value of the
result to the callback provided and returns a L<Venus::Result> object.

I<Since C<4.15>>

=over 4

=item on_valid example 1

  # given: synopsis;

  my $on_valid = $result->on_valid;

  # bless(..., "Venus::Result")

=back

=over 4

=item on_valid example 2

  # given: synopsis;

  my $on_valid = $result->on_valid(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=back

=over 4

=item on_valid example 3

  # given: synopsis;

  $result->issue("Failed!");

  my $on_valid = $result->on_valid(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=back

=over 4

=item on_valid example 4

  # given: synopsis;

  my $on_valid = $result->on_valid(sub{
    die "New failure!";
  });

  # bless(..., "Venus::Result")

=back

=cut

=head2 then

  then(string | coderef $callback, any @args) (Venus::Result)

The then method chains an operations by passing the value or issue of the
result to the callback provided and returns a L<Venus::Result> object.

I<Since C<4.15>>

=over 4

=item then example 1

  # given: synopsis;

  my $then = $result->then;

  # bless(..., "Venus::Result")

=back

=over 4

=item then example 2

  # given: synopsis;

  my $then = $result->then(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=back

=over 4

=item then example 3

  # given: synopsis;

  $result->issue("Failed!");

  my $then = $result->then(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=back

=over 4

=item then example 4

  # given: synopsis;

  my $then = $result->then(sub{
    die "New failure!";
  });

  # bless(..., "Venus::Result")

=back

=cut

=head2 valid

  valid(any $value) (Venus::Result)

The valid method returns a L<Venus::Result> object representing a value and
success state.

I<Since C<4.15>>

=over 4

=item valid example 1

  package main;

  use Venus::Result;

  my $valid = Venus::Result->valid("Success!");

  # bless(..., "Venus::Result")

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut