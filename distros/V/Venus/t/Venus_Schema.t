package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Schema

=cut

$test->for('name');

=tagline

Schema Class

=cut

$test->for('tagline');

=abstract

Schema Class for Perl 5

=cut

$test->for('abstract');

=includes

method: new
method: rule
method: rules
method: ruleset
method: shorthand
method: validate

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  # bless({...}, 'Venus::Schema')

  # $schema->validate;

  # ([], undef)

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Schema');
  my $errors = $result->validate;
  is_deeply $errors, [];

  $result
});

=description

This package provides a mechanism for validating complex data structures using
data validation rules provided as a ruleset.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Encaseable

=cut

$test->for('integrates');

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Schema)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Schema;

  my $new = Venus::Schema->new;

  # bless(..., "Venus::Schema")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Schema');

  $result
});

=method rule

The rule method appends a new rule to the L</ruleset> to be used during
L</validate>, and returns the invocant. A "rule" is a hashref that consists of
an optional C<selector> key whose value will be provided to the
L<Venus::Validate/select> method, a C<presence> key whose value must be one of
the "required", "optional", or "present" L<Venus::Validate> methods, and a
C<executes> key whose value must be an arrayref where each element is a
L<Venus::Validate> validation method name or an arrayref with a method name and
arguments.

=signature rule

  rule(hashref $rule) (Venus::Schema)

=metadata rule

{
  since => '4.15',
}

=cut

=example-1 rule

  # given: synopsis

  package main;

  my $rule = $schema->rule;

  # bless({...}, 'Venus::Schema')

=cut

$test->for('example', 1, 'rule', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Schema');
  my $ruleset = $result->ruleset;
  is_deeply $ruleset, [];

  $result
});

=example-2 rule

  # given: synopsis

  package main;

  my $rule = $schema->rule({
    presence => 'required',
    executes => ['string'],
  });

  # bless({...}, 'Venus::Schema')

=cut

$test->for('example', 2, 'rule', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Schema');
  my $ruleset = $result->ruleset;
  is_deeply $ruleset, [{
    presence => 'required',
    executes => ['string'],
  }];

  $result
});

=example-3 rule

  # given: synopsis

  package main;

  my $rule = $schema->rule({
    selector => 'name',
    presence => 'required',
    executes => ['string'],
  });

  # bless({...}, 'Venus::Schema')

=cut

$test->for('example', 3, 'rule', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Schema');
  my $ruleset = $result->ruleset;
  is_deeply $ruleset, [{
    selector => 'name',
    presence => 'required',
    executes => ['string'],
  }];

  $result
});

=example-4 rule

  # given: synopsis

  package main;

  my $rule = $schema->rule({
    selector => 'name',
    presence => 'required',
    executes => [['type', 'string']],
  });

  # bless({...}, 'Venus::Schema')

=cut

$test->for('example', 4, 'rule', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Schema');
  my $ruleset = $result->ruleset;
  is_deeply $ruleset, [{
    selector => 'name',
    presence => 'required',
    executes => [['type', 'string']],
  }];

  $result
});

=method rules

The rules method appends new rules to the L</ruleset> using the L</rule> method
and returns the invocant.

=signature rules

  rules(hashref @rules) (Venus::Schema)

=metadata rules

{
  since => '4.15',
}

=cut

=example-1 rules

  # given: synopsis

  package main;

  my $rules = $schema->rules;

  # bless(..., "Venus::Schema")

=cut

$test->for('example', 1, 'rules', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Schema');
  my $ruleset = $result->ruleset;
  is_deeply $ruleset, [];

  $result
});

=example-2 rules

  # given: synopsis

  package main;

  my $rules = $schema->rules({
    presence => 'required',
    executes => ['string'],
  });

  # bless(..., "Venus::Schema")

=cut

$test->for('example', 2, 'rules', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Schema');
  my $ruleset = $result->ruleset;
  is_deeply $ruleset, [{
    presence => 'required',
    executes => ['string'],
  }];

  $result
});

=example-3 rules

  # given: synopsis

  package main;

  my $rules = $schema->rules(
    {
      selector => 'first_name',
      presence => 'required',
      executes => ['string'],
    },
    {
      selector => 'last_name',
      presence => 'required',
      executes => ['string'],
    }
  );

  # bless(..., "Venus::Schema")

=cut

$test->for('example', 3, 'rules', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Schema');
  my $ruleset = $result->ruleset;
  is_deeply $ruleset, [
    {
      selector => 'first_name',
      presence => 'required',
      executes => ['string'],
    },
    {
      selector => 'last_name',
      presence => 'required',
      executes => ['string'],
    }
  ];

  $result
});

=method ruleset

The ruleset method gets and sets the L<"rules"|/rule> to be used during
L<"validation"|/validate>.

=signature ruleset

  ruleset(arrayref $ruleset) (arrayref)

=metadata ruleset

{
  since => '4.15',
}

=cut

=example-1 ruleset

  # given: synopsis

  package main;

  my $ruleset = $schema->ruleset;

  # []

=cut

$test->for('example', 1, 'ruleset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 ruleset

  # given: synopsis

  package main;

  my $ruleset = $schema->ruleset([
    {
      selector => 'first_name',
      presence => 'required',
      executes => ['string'],
    },
    {
      selector => 'last_name',
      presence => 'required',
      executes => ['string'],
    }
  ]);

  # [
  #   {
  #     selector => 'first_name',
  #     presence => 'required',
  #     executes => ['string'],
  #   },
  #   {
  #     selector => 'last_name',
  #     presence => 'required',
  #     executes => ['string'],
  #   }
  # ]

=cut

$test->for('example', 2, 'ruleset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [
    {
      selector => 'first_name',
      presence => 'required',
      executes => ['string'],
    },
    {
      selector => 'last_name',
      presence => 'required',
      executes => ['string'],
    }
  ];

  $result
});

=method shorthand

The shorthand method accepts an arrayref or hashref of shorthand notation and
returns a ruleset arrayref. This provides a concise way to define validation
rules. Keys can have suffixes to indicate presence: C<!> for (explicit)
required, C<?> (explicit) for optional, C<*> for (explicit) present (i.e., must
exist but can be null), and no suffix means (implicit) required. Keys using dot
notation (e.g., C<website.url>) result in arrayref selectors for nested path
validation.

=signature shorthand

  shorthand(arrayref | hashref $data) (arrayref)

=metadata shorthand

{
  since => '4.15',
}

=cut

=example-1 shorthand

  # given: synopsis

  package main;

  my $shorthand = $schema->shorthand([
    'fname!' => 'string',
    'lname!' => 'string',
  ]);

  # [
  #   {
  #     selector => 'fname',
  #     presence => 'required',
  #     execute => 'string',
  #   },
  #   {
  #     selector => 'lname',
  #     presence => 'required',
  #     execute => 'string',
  #   },
  # ]

=cut

$test->for('example', 1, 'shorthand', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  ok @{$result} == 2;
  ok $result->[0]{selector} eq 'fname';
  ok $result->[0]{presence} eq 'required';
  ok $result->[0]{execute} eq 'string';
  ok $result->[1]{selector} eq 'lname';
  ok $result->[1]{presence} eq 'required';
  ok $result->[1]{execute} eq 'string';

  $result
});

=example-2 shorthand

  # given: synopsis

  package main;

  my $shorthand = $schema->shorthand([
    'email?' => 'string',
    'age*' => 'number',
  ]);

  # [
  #   {
  #     selector => 'email',
  #     presence => 'optional',
  #     execute => 'string',
  #   },
  #   {
  #     selector => 'age',
  #     presence => 'present',
  #     execute => 'number',
  #   },
  # ]

=cut

$test->for('example', 2, 'shorthand', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  ok @{$result} == 2;
  ok $result->[0]{selector} eq 'email';
  ok $result->[0]{presence} eq 'optional';
  ok $result->[0]{execute} eq 'string';
  ok $result->[1]{selector} eq 'age';
  ok $result->[1]{presence} eq 'present';
  ok $result->[1]{execute} eq 'number';

  $result
});

=example-3 shorthand

  # given: synopsis

  package main;

  my $shorthand = $schema->shorthand([
    'login' => 'string',
    'password' => 'string',
  ]);

  # [
  #   {
  #     selector => 'login',
  #     presence => 'required',
  #     execute => 'string',
  #   },
  #   {
  #     selector => 'password',
  #     presence => 'required',
  #     execute => 'string',
  #   },
  # ]

=cut

$test->for('example', 3, 'shorthand', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  ok @{$result} == 2;
  ok $result->[0]{selector} eq 'login';
  ok $result->[0]{presence} eq 'required';
  ok $result->[0]{execute} eq 'string';
  ok $result->[1]{selector} eq 'password';
  ok $result->[1]{presence} eq 'required';
  ok $result->[1]{execute} eq 'string';

  $result
});

=example-4 shorthand

  # given: synopsis

  package main;

  my $shorthand = $schema->shorthand([
    'website.url' => 'string',
    'profile.bio.text' => 'string',
  ]);

  # [
  #   {
  #     selector => ['website', 'url'],
  #     presence => 'required',
  #     execute => 'string',
  #   },
  #   {
  #     selector => ['profile', 'bio', 'text'],
  #     presence => 'required',
  #     execute => 'string',
  #   },
  # ]

=cut

$test->for('example', 4, 'shorthand', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  ok @{$result} == 2;
  is_deeply $result->[0]{selector}, ['website', 'url'];
  ok $result->[0]{presence} eq 'required';
  ok $result->[0]{execute} eq 'string';
  is_deeply $result->[1]{selector}, ['profile', 'bio', 'text'];
  ok $result->[1]{presence} eq 'required';
  ok $result->[1]{execute} eq 'string';

  $result
});

=example-5 shorthand

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  my $ruleset = $schema->shorthand([
    'fname!' => 'string',
    'lname!' => 'string',
    'email?' => 'string',
    'login' => 'string',
  ]);

  $schema->rules(@{$ruleset});

  my $input = {
    fname => 'Elliot',
    lname => 'Alderson',
    login => 'mrrobot',
  };

  my $errors = $schema->validate($input);

  # []

=cut

$test->for('example', 5, 'shorthand', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=method validate

The validate method validates the data provided using the L</ruleset> and
returns an arrayref containing the errors encountered, if any. Returns the
errors arrayref, and the data validated in list context.

=signature validate

  validate(any $data) (arrayref)

=metadata validate

{
  since => '4.15',
}

=cut

=example-1 validate

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  my $errors = $schema->validate;

  # []

=cut

$test->for('example', 1, 'validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  is_deeply $result, [];

  $result
});

=example-2 validate

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  $schema->rule({
    selector => 'handles',
    presence => 'required',
    executes => [['type', 'arrayref']],
  });

  my $errors = $schema->validate;

  # [['handles', ['required', []]]]

=cut

$test->for('example', 2, 'validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  is_deeply $result, [['handles', ['required', []]]];

  $result
});

=example-3 validate

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  my $input = {
    fname => 'Elliot',
    lname => 'Alderson',
    handles => [
      {name => 'mrrobot'},
      {name => 'fsociety'},
    ],
    level => 5,
    skills => undef,
    role => 'Engineer',
  };

  $schema->rule({
    selector => 'fname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  $schema->rule({
    selector => 'lname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  $schema->rule({
    selector => 'skills',
    presence => 'present',
  });

  $schema->rule({
    selector => 'handles',
    presence => 'required',
    executes => [['type', 'arrayref']],
  });

  $schema->rule({
    selector => ['handles', 'name'],
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  my $errors = $schema->validate($input);

  # []

=cut

$test->for('example', 3, 'validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  is_deeply $result, [];

  $result
});

=example-4 validate

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  my $input = {
    fname => 'Elliot',
    lname => 'Alderson',
    handles => [
      {name => 'mrrobot'},
      {name => 'fsociety'},
    ],
    level => 5,
    skills => undef,
    role => 'Engineer',
  };

  $schema->rule({
    selector => 'fname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  $schema->rule({
    selector => 'lname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  $schema->rule({
    selector => 'skills',
    presence => 'required',
  });

  $schema->rule({
    selector => 'handles',
    presence => 'required',
    executes => [['type', 'arrayref']],
  });

  $schema->rule({
    selector => ['handles', 'name'],
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  my $errors = $schema->validate($input);

  # [['skills', ['required', []]]]

=cut

$test->for('example', 4, 'validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  is_deeply $result, [['skills', ['required', []]]];

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Schema.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
