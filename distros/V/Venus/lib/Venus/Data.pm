package Venus::Data;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'base', 'mask';

# INHERITS

base 'Venus::Kind::Utility';

# ATTRIBUTES

mask 'issues';
mask 'ruleset';
mask 'validated';
mask 'value';

# BUILDERS

sub build_self {
  my ($self, $data) = @_;

  my $value = delete $data->{value};

  my $ruleset = delete $data->{ruleset};

  $value = {%{$data}} if !$value && keys %{$data};

  require Venus;

  $self->value(Venus::clone($value));

  $self->ruleset(Venus::clone($ruleset));

  delete $self->{$_} for keys %{$self};

  return $self;
}

# METHODS

sub error {
  my ($self) = @_;

  my $errors = $self->errors;

  return $errors->[0];
}

sub errors {
  my ($self) = @_;

  require Venus;

  my $issues = $self->issues;

  return Venus::clone($issues);
}

sub renew {
  my ($self, @args) = @_;

  my $data = $self->ARGS(@args);

  $data->{ruleset} = $self->ruleset;

  return $self->class->new($data);
}

sub shorthand {
  my ($self, $data) = @_;

  require Venus::Schema;

  my $ruleset = Venus::Schema->shorthand($data);

  $self->ruleset($ruleset);

  return $self;
}

sub valid {
  my ($self) = @_;

  $self->validate if !defined $self->validated;

  return $self->validated;
}

sub validate {
  my ($self) = @_;

  require Venus;

  return $self->validated
    ? Venus::clone($self->value)
    : undef
    if defined $self->validated;

  require Venus::Schema;

  my $schema = Venus::Schema->new->rules(
    $self->ruleset
    ? @{$self->ruleset}
    : ()
  );

  my ($errors, $value) = $schema->validate($self->value);

  if (@{$errors}) {
    $self->validated(false);
    $self->issues($errors);
    $self->value($value);
    return undef;
  }
  else {
    $self->validated(true);
    $self->issues([]);
    $self->value($value);
    return Venus::clone($value);
  }

  return $self;
}

1;


=head1 NAME

Venus::Data - Data Class

=cut

=head1 ABSTRACT

Data Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Data;

  my $data = Venus::Data->new;

  # bless({}, 'Venus::Data')

=cut

=head1 DESCRIPTION

This package provides a value object for encapsulating data validation. It
represents a single immutable validation attempt, ensuring unvalidated data
cannot be observed. Validation runs at most once per instance, with all
observable outcomes flowing from that validation. The big idea is that the
schema (or ruleset) is a contract, and if the validate was success you can be
certain that the data (or value) is valid and conforms with the schema.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 error

  error() (arrayref)

The error method returns the first validation error as an arrayref in the
format C<[path, [error_type, args]]>, or undef if no errors exist. This is a
convenience method for accessing the first error when you don't need the
complete error list. Call C</validate> or C</valid> first to ensure validation
has run.

I<Since C<4.15>>

=over 4

=item error example 1

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => undef,
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
    ],
  );

  $data->validate;

  my $error = $data->error;

  # ['name', ['required', []]]

=back

=over 4

=item error example 2

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => 'Example',
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
    ],
  );

  $data->validate;

  my $error = $data->error;

  # undef

=back

=over 4

=item error example 3

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => 123,
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => [['type', 'string']]
      },
    ],
  );

  $data->validate;

  my $error = $data->error;

  # ['name', ['type', ['string']]]

=back

=cut

=head2 errors

  errors() (within[arrayref, arrayref])

The errors method returns an arrayref of all validation errors. Each error is
an arrayref with the format C<[path, [error_type, args]]> where path indicates
which field failed and C<error_type> describes the failure (e.g., 'required',
'type', etc). Returns an empty arrayref if validation succeeded or hasn't run
yet.

I<Since C<4.15>>

=over 4

=item errors example 1

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => undef,
      age => 'invalid'
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
      {
        selector => 'age',
        presence => 'required',
        executes => ['number']
      },
    ],
  );

  $data->validate;

  my $errors = $data->errors;

  # [
  #   ['name', ['required', []]],
  #   ['age', ['number', []]],
  # ]

=back

=over 4

=item errors example 2

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => 'Example',
      age => 25
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
      {
        selector => 'age',
        presence => 'required',
        executes => ['number']
      },
    ],
  );

  $data->validate;

  my $errors = $data->errors;

  # []

=back

=over 4

=item errors example 3

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => 123,
      email => undef
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => [['type', 'string']]
      },
      {
        selector => 'email',
        presence => 'required',
        executes => ['string']
      },
    ],
  );

  $data->validate;

  my $errors = $data->errors;

  # [
  #   ['name', ['type', ['string']]],
  #   ['email', ['required', []]],
  # ]

=back

=cut

=head2 new

  new(any @args) (Venus::Data)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Data;

  my $data = Venus::Data->new;

  # bless({}, 'Venus::Data')

=back

=cut

=head2 renew

  renew(any @args) (object)

The renew method creates a new instance with updated arguments while preserving
the ruleset from the current instance. This is the best way to "update" the
value while maintaining the ruleset. The new instance will have its validation
state reset and will need to be validated again.

I<Since C<4.15>>

=over 4

=item renew example 1

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => 'Example',
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
    ],
  );

  my $renewed = $data->renew(value => {name => 'Updated'});

  # bless({...}, 'Venus::Data')

=back

=over 4

=item renew example 2

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => 'Example',
      age => 25
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
      {
        selector => 'age',
        presence => 'required',
        executes => ['number']
      },
    ],
  );

  $data->validate;

  my $renewed = $data->renew({value => {name => 'Updated', age => 30}});

  # bless({}, 'Venus::Data')

=back

=cut

=head2 shorthand

  shorthand(arrayref | hashref $data) (Venus::Data)

The shorthand method accepts an arrayref or hashref of shorthand notation and
sets the ruleset on the instance using L<Venus::Schema/shorthand>. This
provides a concise way to define validation rules. Keys can have suffixes to
indicate presence: C<!> for (explicit) required, C<?> (explicit) for optional,
C<*> for (explicit) present (i.e., must exist but can be null), and no suffix
means (implicit) required. Keys using dot notation (e.g., C<website.url>)
result in arrayref selectors for nested path validation. Returns the invocant
for method chaining.

I<Since C<4.15>>

=over 4

=item shorthand example 1

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      fname => 'Elliot',
      lname => 'Alderson',
    },
  );

  $data->shorthand([
    'fname!' => 'string',
    'lname!' => 'string',
  ]);

  my $valid = $data->valid;

  # 1

=back

=over 4

=item shorthand example 2

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      fname => 'Elliot',
    },
  );

  $data->shorthand([
    'fname!' => 'string',
    'lname!' => 'string',
  ]);

  my $valid = $data->valid;

  # 0

=back

=over 4

=item shorthand example 3

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      fname => 'Elliot',
      lname => 'Alderson',
      login => 'mrrobot',
    },
  );

  $data->shorthand([
    'fname!' => 'string',
    'lname!' => 'string',
    'email?' => 'string',
    'login' => 'string',
  ]);

  my $validated = $data->validate;

  # {fname => 'Elliot', lname => 'Alderson', login => 'mrrobot'}

=back

=over 4

=item shorthand example 4

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      user => {
        name => 'Elliot',
      },
    },
  );

  $data->shorthand([
    'user.name' => 'string',
  ]);

  my $validated = $data->validate;

  # {user => {name => 'Elliot'}}

=back

=cut

=head2 valid

  valid() (boolean)

The valid method returns a boolean indicating whether the data is valid. Triggers
validation on first call if not already validated. Subsequent calls return the
cached validation state without re-validating. This is the primary way to check
if data passed validation.

I<Since C<4.15>>

=over 4

=item valid example 1

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => 'Example',
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
    ],
  );

  my $valid = $data->valid;

  # 1

=back

=over 4

=item valid example 2

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => undef,
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
    ],
  );

  my $valid = $data->valid;

  # 0

=back

=over 4

=item valid example 3

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => 'Example',
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
    ],
  );

  my $check_1 = $data->valid;

  # true

  my $check_2 = $data->valid;

  # true (cached)

=back

=cut

=head2 validate

  validate() (any)

The validate method performs validation of the value against the ruleset and
returns the validated (and potentially modified) value on success, or undef on
failure. Validation runs at most once per instance, and subsequent calls return
cached results. The returned value may differ from the original due to
transformations applied during validation (e.g., "trim", "strip", "lowercase",
etc). After validation, check C</valid> to determine success/failure and
C</errors> to get validation errors.

I<Since C<4.15>>

=over 4

=item validate example 1

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => '  Example  ',
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string', 'trim']
      },
    ],
  );

  my $validated = $data->validate;

  # {name => 'Example'}

=back

=over 4

=item validate example 2

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => undef,
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
    ],
  );

  my $validated = $data->validate;

  # undef

=back

=over 4

=item validate example 3

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      name => 'Example',
    },
    ruleset => [
      {
        selector => 'name',
        presence => 'required',
        executes => ['string']
      },
    ],
  );

  my $validated_1 = $data->validate;

  # {name => 'Example'}

  my $validated_2 = $data->validate;

  # {name => 'Example'} (cached)

=back

=over 4

=item validate example 4

  package main;

  use Venus::Data;

  my $data = Venus::Data->new(
    value => {
      fname => 'Elliot',
    },
    ruleset => [
      {
        selector => 'fname',
        presence => 'required',
        executes => ['string', 'trim', 'strip'],
      },
      {
        selector => 'lname',
        presence => 'required',
        executes => ['string', 'trim', 'strip'],
      },
      {
        selector => 'skills',
        presence => 'present',
      },
      {
        selector => 'handles',
        presence => 'required',
        executes => [['type', 'arrayref']],
      },
      {
        selector => ['handles', 'name'],
        presence => 'required',
        executes => ['string', 'trim', 'strip'],
      },
      {
        selector => ['level'],
        presence => 'required',
        executes => ['number', 'trim', 'strip'],
      },
    ],
  );

  my $validated = $data->validate;

  # undef

  my $errors = $data->errors;

  # [
  #   ['lname', ['required', []]],
  #   ['skills', ['present', []]],
  #   ['handles', ['required', []]],
  #   ['handles.name', ['required', []]],
  #   ['level', ['required', []]],
  # ]

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