package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Data

=cut

$test->for('name');

=tagline

Data Class

=cut

$test->for('tagline');

=abstract

Data Class for Perl 5

=cut

$test->for('abstract');

=includes

method: error
method: errors
method: new
method: renew
method: shorthand
method: valid
method: validate

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Data;

  my $data = Venus::Data->new;

  # bless({}, 'Venus::Data')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result
});

=description

This package provides a value object for encapsulating data validation. It
represents a single immutable validation attempt, ensuring unvalidated data
cannot be observed. Validation runs at most once per instance, with all
observable outcomes flowing from that validation. The big idea is that the
schema (or ruleset) is a contract, and if the validate was success you can be
certain that the data (or value) is valid and conforms with the schema.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=method error

The error method returns the first validation error as an arrayref in the
format C<[path, [error_type, args]]>, or undef if no errors exist. This is a
convenience method for accessing the first error when you don't need the
complete error list. Call C</validate> or C</valid> first to ensure validation
has run.

=signature error

  error() (arrayref)

=metadata error

{
  since => '4.15',
}

=example-1 error

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

=cut

$test->for('example', 1, 'error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok $result->[0] eq 'name';
  ok $result->[1][0] eq 'required';

  $result
});

=example-2 error

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

=cut

$test->for('example', 2, 'error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-3 error

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

=cut

$test->for('example', 3, 'error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok $result->[0] eq 'name';
  ok $result->[1][0] eq 'type';
  ok $result->[1][1][0] eq 'string';

  $result
});

=method errors

The errors method returns an arrayref of all validation errors. Each error is
an arrayref with the format C<[path, [error_type, args]]> where path indicates
which field failed and C<error_type> describes the failure (e.g., 'required',
'type', etc). Returns an empty arrayref if validation succeeded or hasn't run
yet.

=signature errors

  errors() (within[arrayref, arrayref])

=metadata errors

{
  since => '4.15',
}

=example-1 errors

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

=cut

$test->for('example', 1, 'errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 2;
  ok $result->[0][0] eq 'name';
  ok $result->[1][0] eq 'age';

  $result
});

=example-2 errors

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

=cut

$test->for('example', 2, 'errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 0;

  $result
});

=example-3 errors

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

=cut

$test->for('example', 3, 'errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 2;
  ok $result->[0][0] eq 'name';
  ok $result->[1][0] eq 'email';

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Data)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Data;

  my $data = Venus::Data->new;

  # bless({}, 'Venus::Data')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Data');

  $result
});

=method renew

The renew method creates a new instance with updated arguments while preserving
the ruleset from the current instance. This is the best way to "update" the
value while maintaining the ruleset. The new instance will have its validation
state reset and will need to be validated again.

=signature renew

  renew(any @args) (object)

=metadata renew

{
  since => '4.15',
}

=example-1 renew

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

=cut

$test->for('example', 1, 'renew', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok $result->isa('Venus::Data');
  is_deeply $result->validate, {name => 'Updated'};

  $result
});

=example-2 renew

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

=cut

$test->for('example', 2, 'renew', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok $result->isa('Venus::Data');
  is_deeply $result->validate, {name => 'Updated', age => 30};

  $result
});

=method shorthand

The shorthand method accepts an arrayref or hashref of shorthand notation and
sets the ruleset on the instance using L<Venus::Schema/shorthand>. This
provides a concise way to define validation rules. Keys can have suffixes to
indicate presence: C<!> for (explicit) required, C<?> (explicit) for optional,
C<*> for (explicit) present (i.e., must exist but can be null), and no suffix
means (implicit) required. Keys using dot notation (e.g., C<website.url>)
result in arrayref selectors for nested path validation. Returns the invocant
for method chaining.

=signature shorthand

  shorthand(arrayref | hashref $data) (Venus::Data)

=metadata shorthand

{
  since => '4.15',
}

=example-1 shorthand

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

=cut

$test->for('example', 1, 'shorthand', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result
});

=example-2 shorthand

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

=cut

$test->for('example', 2, 'shorthand', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  ok !$result;

  !$result
});

=example-3 shorthand

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

=cut

$test->for('example', 3, 'shorthand', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok $result->{fname} eq 'Elliot';
  ok $result->{lname} eq 'Alderson';
  ok $result->{login} eq 'mrrobot';

  $result
});

=example-4 shorthand

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

=cut

$test->for('example', 4, 'shorthand', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok $result->{user}{name} eq 'Elliot';

  $result
});

=method valid

The valid method returns a boolean indicating whether the data is valid. Triggers
validation on first call if not already validated. Subsequent calls return the
cached validation state without re-validating. This is the primary way to check
if data passed validation.

=signature valid

  valid() (boolean)

=metadata valid

{
  since => '4.15',
}

=example-1 valid

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

=cut

$test->for('example', 1, 'valid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result
});

=example-2 valid

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

=cut

$test->for('example', 2, 'valid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  ok !$result;

  !$result
});

=example-3 valid

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

=cut

$test->for('example', 3, 'valid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result
});

=method validate

The validate method performs validation of the value against the ruleset and
returns the validated (and potentially modified) value on success, or undef on
failure. Validation runs at most once per instance, and subsequent calls return
cached results. The returned value may differ from the original due to
transformations applied during validation (e.g., "trim", "strip", "lowercase",
etc). After validation, check C</valid> to determine success/failure and
C</errors> to get validation errors.

=signature validate

  validate() (any)

=metadata validate

{
  since => '4.15',
}

=example-1 validate

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

=cut

$test->for('example', 1, 'validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok $result->{name} eq 'Example';

  $result
});

=example-2 validate

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

=cut

$test->for('example', 2, 'validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-3 validate

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

=cut

$test->for('example', 3, 'validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok $result->{name} eq 'Example';

  $result
});

=example-4 validate

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

=cut

$test->for('example', 4, 'validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 5;
  ok $result->[0][0] eq 'lname';
  ok $result->[1][0] eq 'skills';
  ok $result->[2][0] eq 'handles';
  ok $result->[3][0] eq 'handles.name';
  ok $result->[4][0] eq 'level';

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Data.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;