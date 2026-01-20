package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Validate

=cut

$test->for('name');

=tagline

Validate Class

=cut

$test->for('tagline');

=abstract

Validate Class for Perl 5

=cut

$test->for('abstract');

=includes

method: arrayref
method: boolean
method: check
method: defined
method: each
method: errors
method: exists
method: float
method: hashref
method: is_invalid
method: is_valid
method: issue_args
method: issue_info
method: issue_type
method: length
method: lowercase
method: max_length
method: max_number
method: min_length
method: min_number
method: new
method: number
method: on_invalid
method: on_valid
method: optional
method: present
method: required
method: select
method: string
method: strip
method: sync
method: titlecase
method: trim
method: type
method: uppercase
method: validate
method: value
method: yesno

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  # $validate->string->trim->strip;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');

  $result
});

=description

This package provides a mechanism for performing data validation of simple and
hierarchal data at runtime.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Buildable
Venus::Role::Encaseable

=cut

$test->for('integrates');

=attribute issue

The issue attribute is read/write, accepts C<(arrayref)> values, and is
optional.

=signature issue

  issue(arrayref $issue) (arrayref)

=metadata issue

{
  since => '4.15',
}

=example-1 issue

  # given: synopsis;

  my $issue = $validate->issue([]);

  # []

=cut

$test->for('example', 1, 'issue', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 issue

  # given: synopsis;

  # given: example-1 issue;

  $issue = $validate->issue;

  # []

=cut

$test->for('example', 2, 'issue', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=attribute path

The path attribute is read/write, accepts C<(string)> values, is optional, and
defaults to C<".">.

=signature path

  path(string $path) (string)

=metadata path

{
  since => '4.15',
}

=example-1 path

  # given: synopsis;

  my $path = $validate->path('name');

  # "name"

=cut

$test->for('example', 1, 'path', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "name";

  $result
});

=example-2 path

  # given: synopsis;

  # given: example-1 path;

  $path = $validate->path;

  # "name"

=cut

$test->for('example', 2, 'path', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "name";

  $result
});

=attribute input

The input attribute is read/write, accepts C<(arrayref)> values, and is
optional.

=signature input

  input(arrayref $input) (arrayref)

=metadata input

{
  since => '4.15',
}

=example-1 input

  # given: synopsis;

  my $input = $validate->input([]);

  # []

=cut

$test->for('example', 1, 'input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 input

  # given: synopsis;

  # given: example-1 input;

  $input = $validate->input;

  # []

=cut

$test->for('example', 2, 'input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=method arrayref

The arrayref method is shorthand for calling L</type> with C<"arrayref">. This
method is a validator and uses L</issue_info> to capture validation errors.

=signature arrayref

  arrayref() (Venus::Validate)

=metadata arrayref

{
  since => '4.15',
}

=example-1 arrayref

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([1,2]);

  my $arrayref = $validate->arrayref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 1, 'arrayref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is_deeply $result->value, [1,2];
  is $result->is_valid, true;

  $result
});

=example-2 arrayref

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({1..4});

  my $arrayref = $validate->arrayref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 2, 'arrayref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['arrayref']];
  is_deeply $result->value, {1..4};
  is $result->is_valid, false;

  $result
});

=example-3 arrayref

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([1..4]);

  my $arrayref = $validate->arrayref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 3, 'arrayref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is_deeply $result->value, [1..4];
  is $result->is_valid, true;

  $result
});

=method boolean

The boolean method is shorthand for calling L</type> with C<"boolean">. This
method is a validator and uses L</issue_info> to capture validation errors.

=signature boolean

  boolean() (Venus::Validate)

=metadata boolean

{
  since => '4.15',
}

=example-1 boolean

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(true);

  my $boolean = $validate->boolean;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 1, 'boolean', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, true;
  is $result->is_valid, true;

  $result
});

=example-2 boolean

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(false);

  my $boolean = $validate->boolean;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 2, 'boolean', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, false;
  is $result->is_valid, true;

  $result
});

=example-3 boolean

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $boolean = $validate->boolean;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 3, 'boolean', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['boolean']];
  is $result->value, 1;
  is $result->is_valid, false;

  $result
});

=example-4 boolean

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(0);

  my $boolean = $validate->boolean;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 4, 'boolean', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['boolean']];
  is $result->value, 0;
  is $result->is_valid, false;

  $result
});

=method check

The check method provides a mechanism for performing a custom data validation
check. The first argument enables a data type check via L</type> based on the
type expression provided. The second argument is the name of the check being
performed, which will be used by L</issue_info> if the validation fails. The
remaining arguments are used in the callback provided which performs the custom
data validation.

=signature check

  check(string $type, string $name, string | coderef $callback, any @args) (Venus::Validate)

=metadata check

{
  since => '4.15',
}

=cut

=example-1 check

  # given: synopsis

  package main;

  my $check = $validate->check;

  # bless(..., "Venus::Validate")

  # $check->is_valid;

  # true

=cut

$test->for('example', 1, 'check', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, undef;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=example-2 check

  # given: synopsis

  package main;

  my $check = $validate->check('string');

  # bless(..., "Venus::Validate")

  # $check->is_valid;

  # true

=cut

$test->for('example', 2, 'check', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, undef;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=example-3 check

  # given: synopsis

  package main;

  my $check = $validate->check('string', 'is_email', sub{
    /\w\@\w/
  });

  # bless(..., "Venus::Validate")

  # $check->is_valid;

  # false

  # $check->issue;

  # ['is_email', []]

=cut

$test->for('example', 3, 'check', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['is_email', []];
  is $result->value, 'hello';
  is $result->is_valid, false;

  $result
});

=example-4 check

  # given: synopsis

  package main;

  $validate->value('hello@example.com');

  my $check = $validate->check('string', 'is_email', sub{
    /\w\@\w/
  });

  # bless(..., "Venus::Validate")

  # $check->is_valid;

  # true

  # $check->issue;

  # undef

=cut

$test->for('example', 4, 'check', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, undef;
  is $result->value, 'hello@example.com';
  is $result->is_valid, true;

  $result
});

=method defined

The defined method is shorthand for calling L</type> with C<"defined">. This
method is a validator and uses L</issue_info> to capture validation errors.

=signature defined

  defined() (Venus::Validate)

=metadata defined

{
  since => '4.15',
}

=example-1 defined

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('');

  my $defined = $validate->defined;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 1, 'defined', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, '';
  is $result->is_valid, true;

  $result
});

=example-2 defined

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(undef);

  my $defined = $validate->defined;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 2, 'defined', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['defined']];
  is $result->value, undef;
  is $result->is_valid, false;

  $result
});

=example-3 defined

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new;

  my $defined = $validate->defined;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 3, 'defined', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['defined']];
  is $result->value, undef;
  is $result->is_valid, false;

  $result
});

=method each

The each method uses L</select> to retrieve data and for each item, builds a
L<Venus::Validate> object for the value, settings the object to C<"present">,
C<"required"> or C<"optional"> based on the argument provided, executing the
callback provided for each object, and returns list of objects created.
Defaults to C<"optional"> if no argument is provided. Returns a list in list
context.

=signature each

  each(string $type, string $path) (within[arrayref, Venus::Validate])

=metadata each

{
  since => '4.15',
}

=example-1 each

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(['hello', 'bonjour']);

  my $each = $validate->each;

  # [bless(..., "Venus::Validate"), ...]

=cut

$test->for('example', 1, 'each', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok @{$result} == 2;
  ok $result->[0]->isa('Venus::Validate');
  ok $result->[0]->input;
  ok !$result->[0]->issue;
  is $result->[0]->value, 'hello';
  is $result->[0]->is_valid, true;
  ok $result->[1]->isa('Venus::Validate');
  ok $result->[1]->input;
  ok !$result->[1]->issue;
  is $result->[1]->value, 'bonjour';
  is $result->[1]->is_valid, true;

  $result
});

=example-2 each

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(['hello', 'bonjour']);

  my @each = $validate->each;

  # (bless(..., "Venus::Validate"), ...)

=cut

$test->for('example', 2, 'each', sub {
  my ($tryable) = @_;
  ok my @result = $tryable->result;
  ok @result == 2;
  ok $result[0]->isa('Venus::Validate');
  ok $result[0]->input;
  ok !$result[0]->issue;
  is $result[0]->value, 'hello';
  is $result[0]->is_valid, true;
  ok $result[1]->isa('Venus::Validate');
  ok $result[1]->input;
  ok !$result[1]->issue;
  is $result[1]->value, 'bonjour';
  is $result[1]->is_valid, true;

  @result
});

=example-3 each

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(['hello', 'bonjour']);

  my $each = $validate->each('required');

  # [bless(..., "Venus::Validate"), ...]

=cut

$test->for('example', 3, 'each', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok @{$result} == 2;
  ok $result->[0]->isa('Venus::Validate');
  ok $result->[0]->input;
  ok !$result->[0]->issue;
  is $result->[0]->value, 'hello';
  is $result->[0]->is_valid, true;
  ok $result->[1]->isa('Venus::Validate');
  ok $result->[1]->input;
  ok !$result->[1]->issue;
  is $result->[1]->value, 'bonjour';
  is $result->[1]->is_valid, true;

  $result
});

=example-4 each

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    greetings => ['hello', 'bonjour'],
  });

  my $each = $validate->each('optional', 'greetings');

  # [bless(..., "Venus::Validate"), ...]

=cut

$test->for('example', 4, 'each', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok @{$result} == 2;
  ok $result->[0]->isa('Venus::Validate');
  ok $result->[0]->input;
  ok !$result->[0]->issue;
  is $result->[0]->value, 'hello';
  is $result->[0]->is_valid, true;
  ok $result->[1]->isa('Venus::Validate');
  ok $result->[1]->input;
  ok !$result->[1]->issue;
  is $result->[1]->value, 'bonjour';
  is $result->[1]->is_valid, true;

  $result
});

=method errors

The errors method gets and sets the arrayref used by the current object and all
subsequent nodes to capture errors/issues encountered. Each element of the
arrayref will be an arrayref consisting of the node's L</path> and the
L</issue>. This method returns a list in list context.

=signature errors

  errors(arrayref $data) (arrayref)

=metadata errors

{
  since => '4.15',
}

=cut

=example-1 errors

  # given: synopsis

  package main;

  my $errors = $validate->errors;

  # []

=cut

$test->for('example', 1, 'errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 errors

  # given: synopsis

  package main;

  my $errors = $validate->errors([]);

  # []

=cut

$test->for('example', 2, 'errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-3 errors

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  $validate->errors([]);

  # []

  my $required = $validate->required('2.name');

  # bless(..., "Venus::Validate")

  my $errors = $validate->errors;

  # [['2.name', ['required', []]]]

=cut

$test->for('example', 3, 'errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['2.name', ['required', []]]];

  $result
});

=example-4 errors

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  $validate->errors([]);

  # []

  my $required = $validate->required('1.name');

  # bless(..., "Venus::Validate")

  $required->min_length(10);

  # bless(..., "Venus::Validate")

  my $errors = $validate->errors;

  # [['1.name', ['min_length', [10]]]]

=cut

$test->for('example', 4, 'errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['1.name', ['min_length', [10]]]];

  $result
});

=example-5 errors

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  $validate->errors([]);

  # []

  my $name_0 = $validate->required('0.name');

  # bless(..., "Venus::Validate")

  $name_0->min_length(10);

  # bless(..., "Venus::Validate")

  my $name_1 = $validate->required('1.name');

  # bless(..., "Venus::Validate")

  $name_1->min_length(10);

  # bless(..., "Venus::Validate")

  my $errors = $validate->errors;

  # [['0.name', ['min_length', [10]]], ['1.name', ['min_length', [10]]]]

=cut

$test->for('example', 5, 'errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['0.name', ['min_length', [10]]], ['1.name', ['min_length', [10]]]];

  $result
});

=method issue_args

The issue_args method returns the arguments provided as part of the issue
context. Returns a list in list context.

=signature issue_args

  issue_args() (arrayref)

=metadata issue_args

{
  since => '4.15',
}

=example-1 issue_args

  # given: synopsis;

  $validate->issue(['max_length', ['255']]);

  my $issue_args = $validate->issue_args;

  # ['255']

=cut

$test->for('example', 1, 'issue_args', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ['255'];

  $result
});

=method issue_info

The issue_info method gets or sets the issue context and returns the
L</issue_type> and L</issue_args>. Returns a list in list context.

=signature issue_info

  issue_info(string $type, any @args) (tuple[string, arrayref])

=metadata issue_info

{
  since => '4.15',
}

=example-1 issue_info

  # given: synopsis;

  my $issue_info = $validate->issue_info;

  # undef

=cut

$test->for('example', 1, 'issue_info', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-2 issue_info

  # given: synopsis;

  my $issue_info = $validate->issue_info('max_length', '255');

  # ['max_length', ['255']]

=cut

$test->for('example', 2, 'issue_info', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ['max_length', ['255']];

  $result
});

=example-3 issue_info

  # given: synopsis;

  # given: example-2 issue_info

  $issue_info = $validate->issue_info;

  # ['max_length', ['255']]

=cut

$test->for('example', 3, 'issue_info', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ['max_length', ['255']];

  $result
});

=example-4 issue_info

  # given: synopsis;

  # given: example-2 issue_info

  my ($type, @args) = $validate->issue_info;

  # ('max_length', '255')

=cut

$test->for('example', 4, 'issue_info', sub {
  my ($tryable) = @_;
  ok my @result = $tryable->result;
  is_deeply [@result], ['max_length', '255'];

  @result
});

=method issue_type

The issue_type method returns the issue type (i.e. type of issue) provided as
part of the issue context.

=signature issue_type

  issue_type() (string)

=metadata issue_type

{
  since => '4.15',
}

=example-1 issue_type

  # given: synopsis;

  $validate->issue(['max_length', ['255']]);

  my $issue_type = $validate->issue_type;

  # 'max_length'

=cut

$test->for('example', 1, 'issue_type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, 'max_length';

  $result
});

=method exists

The exists method returns true if a value exists for the current object, and
otherwise returns false.

=signature exists

  exists() (boolean)

=metadata exists

{
  since => '4.15',
}

=cut

=example-1 exists

  # given: synopsis

  package main;

  my $exists = $validate->exists;

  # true

=cut

$test->for('example', 1, 'exists', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 exists

  # given: synopsis

  package main;

  $validate->value(undef);

  my $exists = $validate->exists;

  # true

=cut

$test->for('example', 2, 'exists', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-3 exists

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new;

  my $exists = $validate->exists;

  # false

=cut

$test->for('example', 3, 'exists', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method float

The float method is shorthand for calling L</type> with C<"float">. This method
is a validator and uses L</issue_info> to capture validation errors.

=signature float

  float() (Venus::Validate)

=metadata float

{
  since => '4.15',
}

=example-1 float

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1.23);

  my $float = $validate->float;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 1, 'float', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 1.23;
  is $result->is_valid, true;

  $result
});

=example-2 float

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1_23);

  my $float = $validate->float;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 2, 'float', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['float']];
  is $result->value, 1_23;
  is $result->is_valid, false;

  $result
});

=example-3 float

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new("1.23");

  my $float = $validate->float;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 3, 'float', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 1.23;
  is $result->is_valid, true;

  $result
});

=method hashref

The hashref method is shorthand for calling L</type> with C<"hashref">. This
method is a validator and uses L</issue_info> to capture validation errors.

=signature hashref

  hashref() (Venus::Validate)

=metadata hashref

{
  since => '4.15',
}

=example-1 hashref

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({1,2});

  my $hashref = $validate->hashref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 1, 'hashref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is_deeply $result->value, {1,2};
  is $result->is_valid, true;

  $result
});

=example-2 hashref

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([1..4]);

  my $hashref = $validate->hashref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 2, 'hashref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['hashref']];
  is_deeply $result->value, [1..4];
  is $result->is_valid, false;

  $result
});

=example-3 hashref

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({1..4});

  my $hashref = $validate->hashref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 3, 'hashref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is_deeply $result->value, {1..4};
  is $result->is_valid, true;

  $result
});

=method is_invalid

The is_invalid method returns true if an issue exists, and false otherwise.

=signature is_invalid

  is_invalid() (boolean)

=metadata is_invalid

{
  since => '4.15',
}

=example-1 is_invalid

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->string;

  my $is_invalid = $validate->is_invalid;

  # false

=cut

$test->for('example', 1, 'is_invalid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 is_invalid

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->number;

  my $is_invalid = $validate->is_invalid;

  # true

=cut

$test->for('example', 2, 'is_invalid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method is_valid

The is_valid method returns true if no issue exists, and false otherwise.

=signature is_valid

  is_valid() (boolean)

=metadata is_valid

{
  since => '4.15',
}

=example-1 is_valid

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->string;

  my $is_valid = $validate->is_valid;

  # true

=cut

$test->for('example', 1, 'is_valid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 is_valid

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->number;

  my $is_valid = $validate->is_valid;

  # false

=cut

$test->for('example', 2, 'is_valid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method length

The length method accepts a minimum and maximum and validates that the length
of the data meets the criteria and returns the invocant. This method is a proxy
for the L</min_length> and L</max_length> methods and the errors/issues
encountered will be specific to those operations.

=signature length

  length(number $min, number $max) (Venus::Validate)

=metadata length

{
  since => '4.15',
}

=example-1 length

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('');

  my $length = $validate->length(1, 3);

  # bless(..., "Venus::Validate")

  # $length->issue;

  # ['min_length', [1]]

=cut

$test->for('example', 1, 'length', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['min_length', [1]];
  is $result->value, '';
  is $result->is_valid, false;

  $result
});

=example-2 length

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $length = $validate->length(1, 3);

  # bless(..., "Venus::Validate")

  # $length->issue;

  # ['max_length', [3]]

=cut

$test->for('example', 2, 'length', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['max_length', [3]];
  is $result->value, 'hello';
  is $result->is_valid, false;

  $result
});

=method lowercase

The lowercase method lowercases the value and returns the invocant.

=signature lowercase

  lowercase() (Venus::Validate)

=metadata lowercase

{
  since => '4.15',
}

=example-1 lowercase

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('Hello world');

  my $lowercase = $validate->lowercase;

  # bless(..., "Venus::Validate")

  # $lowercase->value;

  # "hello world"

=cut

$test->for('example', 1, 'lowercase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->value, 'hello world';

  $result
});

=method max_length

The max_length method accepts a maximum and validates that the length of the
data meets the criteria and returns the invocant. This method is a validator
and uses L</issue_info> to capture validation errors.

=signature max_length

  max_length(number $max) (Venus::Validate)

=metadata max_length

{
  since => '4.15',
}

=example-1 max_length

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $max_length = $validate->max_length(5);

  # bless(..., "Venus::Validate")

  # $max_length->issue;

  # undef

=cut

$test->for('example', 1, 'max_length', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=example-2 max_length

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $max_length = $validate->max_length(3);

  # bless(..., "Venus::Validate")

  # $max_length->issue;

  # ['max_length', [3]]

=cut

$test->for('example', 2, 'max_length', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['max_length', [3]];
  is $result->value, 'hello';
  is $result->is_valid, false;

  $result
});

=method max_number

The max_number accepts a maximum and validates that the data is exactly the
number provided or less, and returns the invocant. This method is a validator
and uses L</issue_info> to capture validation errors.

=signature max_number

  max_number(number $max) (Venus::Validate)

=metadata max_number

{
  since => '4.15',
}

=example-1 max_number

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $max_number = $validate->max_number(1);

  # bless(..., "Venus::Validate")

  # $max_number->issue;

  # undef

=cut

$test->for('example', 1, 'max_number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 1;
  is $result->is_valid, true;

  $result
});

=example-2 max_number

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $max_number = $validate->max_number(0);

  # bless(..., "Venus::Validate")

  # $max_number->issue;

  # ['max_number', [0]]

=cut

$test->for('example', 2, 'max_number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['max_number', [0]];
  is $result->value, 1;
  is $result->is_valid, false;

  $result
});

=method min_length

The min_length accepts a minimum and validates that the length of the data
meets the criteria and returns the invocant. This method is a validator and
uses L</issue_info> to capture validation errors.

=signature min_length

  min_length(number $min) (Venus::Validate)

=metadata min_length

{
  since => '4.15',
}

=example-1 min_length

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $min_length = $validate->min_length(1);

  # bless(..., "Venus::Validate")

  # $min_length->issue;

  # undef

=cut

$test->for('example', 1, 'min_length', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=example-2 min_length

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('');

  my $min_length = $validate->min_length(1);

  # bless(..., "Venus::Validate")

  # $min_length->issue;

  # ['min_length', [1]]

=cut

$test->for('example', 2, 'min_length', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['min_length', [1]];
  is $result->value, '';
  is $result->is_valid, false;

  $result
});

=method min_number

The min_number accepts a minimum and validates that the data is exactly the
number provided or greater, and returns the invocant. This method is a
validator and uses L</issue_info> to capture validation errors.

=signature min_number

  min_number(number $min) (Venus::Validate)

=metadata min_number

{
  since => '4.15',
}

=example-1 min_number

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $min_number = $validate->min_number(1);

  # bless(..., "Venus::Validate")

  # $min_number->issue;

  # undef

=cut

$test->for('example', 1, 'min_number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 1;
  is $result->is_valid, true;

  $result
});

=example-2 min_number

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $min_number = $validate->min_number(2);

  # bless(..., "Venus::Validate")

  # $min_number->issue;

  # ['min_number', [2]]

=cut

$test->for('example', 2, 'min_number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['min_number', [2]];
  is $result->value, 1;
  is $result->is_valid, false;

  $result
});

=method new

The new method returns a L<Venus::Validate> object.

=signature new

  new(hashref $data) (Venus::Validate)

=metadata new

{
  since => '4.15',
}

=example-1 new

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new;

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is_deeply $result->input, [];
  ok !$result->issue;
  is $result->value, undef;
  is $result->is_valid, true;

  $result
});

=example-2 new

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(input => 'hello');

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is_deeply $result->input, ['hello'];
  ok !$result->issue;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=example-3 new

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({input => 'hello'});

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is_deeply $result->input, ['hello'];
  ok !$result->issue;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=example-4 new

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 4, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is_deeply $result->input, ['hello'];
  ok !$result->issue;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=method number

The number method is shorthand for calling L</type> with C<"number">. This
method is a validator and uses L</issue_info> to capture validation errors.

=signature number

  number() (Venus::Validate)

=metadata number

{
  since => '4.15',
}

=example-1 number

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(123);

  my $number = $validate->number;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 1, 'number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 123;
  is $result->is_valid, true;

  $result
});

=example-2 number

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1.23);

  my $number = $validate->number;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 2, 'number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['number']];
  is $result->value, 1.23;
  is $result->is_valid, false;

  $result
});

=example-3 number

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1_23);

  my $number = $validate->number;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 3, 'number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 1_23;
  is $result->is_valid, true;

  $result
});

=method on_invalid

The on_invalid method chains an operations by passing the issue value of the
object to the callback provided and returns a L<Venus::Validate> object.

=signature on_invalid

  on_invalid(coderef $callback, any @args) (Venus::Validate)

=metadata on_invalid

{
  since => '4.15',
}

=example-1 on_invalid

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->number;

  my $on_invalid = $validate->on_invalid;

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 1, 'on_invalid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->is_invalid, true;

  $result
});

=example-2 on_invalid

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->number;

  my $on_invalid = $validate->on_invalid(sub{
    $validate->{called} = time;
    return $validate;
  });

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 2, 'on_invalid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->is_invalid, true;
  ok exists $result->{called};

  $result
});

=method on_valid

The on_valid method chains an operations by passing the value of the object to
the callback provided and returns a L<Venus::Validate> object.

=signature on_valid

  on_valid(coderef $callback, any @args) (Venus::Validate)

=metadata on_valid

{
  since => '4.15',
}

=example-1 on_valid

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->string;

  my $on_valid = $validate->on_valid;

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 1, 'on_valid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->is_valid, true;

  $result
});

=example-2 on_valid

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->string;

  my $on_valid = $validate->on_valid(sub{
    $validate->{called} = time;
    return $validate;
  });

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 2, 'on_valid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->is_valid, true;
  ok exists $result->{called};

  $result
});

=method optional

The optional method uses L</select> to retrieve data and returns a
L<Venus::Validate> object with the selected data marked as optional.

=signature optional

  optional(string $path) (Venus::Validate)

=metadata optional

{
  since => '4.15',
}

=example-1 optional

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
  });

  my $optional = $validate->optional('email');

  # bless(..., "Venus::Validate")

  # $optional->is_valid;

  # true

=cut

$test->for('example', 1, 'optional', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, undef;
  is $result->is_valid, true;

  $result
});

=example-2 optional

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
    email => 'johndoe@example.com',
  });

  my $optional = $validate->optional('email');

  # bless(..., "Venus::Validate")

  # $optional->is_valid;

  # true

=cut

$test->for('example', 2, 'optional', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'johndoe@example.com';
  is $result->is_valid, true;

  $result
});

=method present

The present method uses L</select> to retrieve data and returns a
L<Venus::Validate> object with the selected data marked as needing to be
present. This method is a validator and uses L</issue_info> to capture
validation errors.

=signature present

  present(string $path) (Venus::Validate)

=metadata present

{
  since => '4.15',
}

=example-1 present

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
  });

  my $present = $validate->present('email');

  # bless(..., "Venus::Validate")

  # $present->is_valid;

  # false

=cut

$test->for('example', 1, 'present', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['present', []];
  is $result->value, undef;
  is $result->is_valid, false;

  $result
});

=example-2 present

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
    email => 'johndoe@example.com',
  });

  my $present = $validate->present('email');

  # bless(..., "Venus::Validate")

  # $present->is_valid;

  # true

=cut

$test->for('example', 2, 'present', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'johndoe@example.com';
  is $result->is_valid, true;

  $result
});

=method required

The required method uses L</select> to retrieve data and returns a
L<Venus::Validate> object with the selected data marked as required. This
method is a validator and uses L</issue_info> to capture validation errors.

=signature required

  required(string $path) (Venus::Validate)

=metadata required

{
  since => '4.15',
}

=example-1 required

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
  });

  my $required = $validate->required('email');

  # bless(..., "Venus::Validate")

  # $present->is_valid;

  # false

=cut

$test->for('example', 1, 'required', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['required', []];
  is $result->value, undef;
  is $result->is_valid, false;

  $result
});

=example-2 required

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
    email => 'johndoe@example.com',
  });

  my $required = $validate->required('email');

  # bless(..., "Venus::Validate")

  # $present->is_valid;

  # true

=cut

$test->for('example', 2, 'required', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'johndoe@example.com';
  is $result->is_valid, true;

  $result
});

=method select

The select method uses L<Venus::Hash/path> to retrieve data and returns a
L<Venus::Validate> object with the selected data. Returns C<undef> if the data
can't be selected.

=signature select

  select(string $path) (Venus::Validate)

=metadata select

{
  since => '4.15',
}

=example-1 select

  # given: synopsis;

  my $select = $validate->select;

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 1, 'select', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->path, undef;

  $result
});

=example-2 select

  # given: synopsis;

  my $select = $validate->select('ello');

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 2, 'select', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->path, 'ello';
  is $result->value, undef;

  $result
});

=example-3 select

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  my $select = $validate->select('0.name');

  # bless(..., "Venus::Validate")

  # $select->value;

  # "john"

=cut

$test->for('example', 3, 'select', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa("Venus::Validate");
  is $result->value, 'john';

  $result
});

=example-4 select

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  my $select = $validate->select('1.name');

  # bless(..., "Venus::Validate")

  # $select->value;

  # "jane"

=cut

$test->for('example', 4, 'select', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa("Venus::Validate");
  is $result->value, 'jane';

  $result
});

=example-5 select

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    persons => [
      {
        name => 'john',
      },
      {
        name => 'jane',
      },
    ]
  });

  my $select = $validate->select('persons.0.name');

  # bless(..., "Venus::Validate")

  # $select->value;

  # "john"

=cut

$test->for('example', 5, 'select', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa("Venus::Validate");
  is $result->value, 'john';

  $result
});

=example-6 select

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    persons => [
      {
        name => 'john',
      },
      {
        name => 'jane',
      },
    ]
  });

  my $select = $validate->select('persons.1.name');

  # bless(..., "Venus::Validate")

  # $select->value;

  # "jane"

=cut

$test->for('example', 6, 'select', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa("Venus::Validate");
  is $result->value, 'jane';

  $result
});

=method string

The string method is shorthand for calling L</type> with C<"string">. This
method is a validator and uses L</issue_info> to capture validation errors.

=signature string

  string() (Venus::Validate)

=metadata string

{
  since => '4.15',
}

=example-1 string

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $string = $validate->string;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 1, 'string', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=example-2 string

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('');

  my $string = $validate->string;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 2, 'string', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, '';
  is $result->is_valid, true;

  $result
});

=example-3 string

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('1.23');

  my $string = $validate->string;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 3, 'string', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['string']];
  is $result->value, '1.23';
  is $result->is_valid, false;

  $result
});

=method strip

The strip method removes multiple consecutive whitespace characters from the
value and returns the invocant.

=signature strip

  strip() (Venus::Validate)

=metadata strip

{
  since => '4.15',
}

=example-1 strip

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello    world');

  my $strip = $validate->strip;

  # bless(..., "Venus::Validate")

  # $strip->value;

  # "hello world"

=cut

$test->for('example', 1, 'strip', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->value, 'hello world';

  $result
});

=example-2 strip

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({text => 'hello    world'});

  my $strip = $validate->strip;

  # bless(..., "Venus::Validate")

  # $strip->value;

  # {text => 'hello    world'}

=cut

$test->for('example', 2, 'strip', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is_deeply $result->value, {text => 'hello    world'};

  $result
});

=method sync

The sync method merges the L<Venus::Validate> node provided with the current
object.

=signature sync

  sync(Venus::Validate $node) (Venus::Validate)

=metadata sync

{
  since => '4.15',
}

=example-1 sync

  # given: synopsis;

  my $sync = $validate->sync;

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 1, 'sync', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->value, 'hello';

  $result
});

=example-2 sync

  package main;

  use Venus::Validate;

  my $root = Venus::Validate->new({
    persons => [
      {
        name => 'john',
      },
      {
        name => 'jane',
      },
    ]
  });

  my $node = $root->select('persons.1.name');

  # bless(..., "Venus::Validate")

  $node->value('jack');

  # "jack"

  # $root->select('persons.1.name')->value;

  # "john"

  $root->sync($node);

  # bless(..., "Venus::Validate")

  # $root->select('persons.1.name')->value;

  # "jack"

=cut

$test->for('example', 2, 'sync', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->select('persons.1.name')->value, 'jack';

  $result
});

=example-3 sync

  package main;

  use Venus::Validate;

  my $root = Venus::Validate->new(['john', 'jane']);

  my $node = $root->select(1);

  # bless(..., "Venus::Validate")

  $node->value('jill');

  # "jill"

  # $root->select(1)->value;

  # "jane"

  $root->sync($node);

  # bless(..., "Venus::Validate")

  # $root->select(1)->value;

  # "jill"

=cut

$test->for('example', 3, 'sync', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->select(1)->value, 'jill';

  $result
});

=method titlecase

The titlecase method titlecases the value and returns the invocant.

=signature titlecase

  titlecase() (Venus::Validate)

=metadata titlecase

{
  since => '4.15',
}

=example-1 titlecase

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello world');

  my $titlecase = $validate->titlecase;

  # bless(..., "Venus::Validate")

  # $titlecase->value;

  # "Hello World"

=cut

$test->for('example', 1, 'titlecase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->value, 'Hello World';

  $result
});

=method trim

The trim method removes whitespace characters from both ends of the value and
returns the invocant.

=signature trim

  trim() (Venus::Validate)

=metadata trim

{
  since => '4.15',
}

=example-1 trim

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('  hello world  ');

  my $trim = $validate->trim;

  # bless(..., "Venus::Validate")

  # $trim->value;

  # "hello world"

=cut

$test->for('example', 1, 'trim', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->value, 'hello world';

  $result
});

=example-2 trim

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({text => '  hello world  '});

  my $trim = $validate->trim;

  # bless(..., "Venus::Validate")

  # $trim->value;

  # {text => '  hello world  '}

=cut

$test->for('example', 2, 'trim', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is_deeply $result->value, {text => '  hello world  '};

  $result
});

=method type

The type method validates that the value conforms with the L<Venus::Type> type
expression provided, and returns the invocant. This method is a validator and
uses L</issue_info> to capture validation errors.

=signature type

  type(string $type) (Venus::Validate)

=metadata type

{
  since => '4.15',
}

=example-1 type

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $type = $validate->type;

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=cut

$test->for('example', 1, 'type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=example-2 type

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $type = $validate->type('string');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=cut

$test->for('example', 2, 'type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'hello';
  is $result->is_valid, true;

  $result
});

=example-3 type

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $type = $validate->type('number');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # false

=cut

$test->for('example', 3, 'type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['number']];
  is $result->value, 'hello';
  is $result->is_valid, false;

  $result
});

=example-4 type

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('Y');

  my $type = $validate->type('yesno');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=cut

$test->for('example', 4, 'type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'Y';
  is $result->is_valid, true;

  $result
});

=example-5 type

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('A');

  my $type = $validate->type('enum[A, B]');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=cut

$test->for('example', 5, 'type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'A';
  is $result->is_valid, true;

  $result
});

=example-6 type

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([200, [], '']);

  my $type = $validate->type('tuple[number, arrayref, string]');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=cut

$test->for('example', 6, 'type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is_deeply $result->value, [200, [], ''];
  is $result->is_valid, true;

  $result
});

=example-7 type

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(undef);

  my $type = $validate->type('string');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=cut

$test->for('example', 7, 'type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['string']];
  is $result->value, undef;
  is $result->is_valid, false;

  $result
});

=example-8 type

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(undef);

  my $type = $validate->optional->type('string');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=cut

$test->for('example', 8, 'type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, undef;
  is $result->is_valid, true;

  $result
});

=method uppercase

The uppercase method uppercases the value and returns the invocant.

=signature uppercase

  uppercase() (Venus::Validate)

=metadata uppercase

{
  since => '4.15',
}

=example-1 uppercase

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello world');

  my $uppercase = $validate->uppercase;

  # bless(..., "Venus::Validate")

  # $uppercase->value;

  # "HELLO WORLD"

=cut

$test->for('example', 1, 'uppercase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  is $result->value, 'HELLO WORLD';

  $result
});

=method value

The value method returns the value being validated.

=signature value

  value() (any)

=metadata value

{
  since => '4.15',
}

=example-1 value

  # given: synopsis;

  my $value = $validate->value;

  # "hello"

=cut

$test->for('example', 1, 'value', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, 'hello';

  $result
});

=method yesno

The yesno method is shorthand for calling L</type> with C<"yesno">. This method
is a validator and uses L</issue_info> to capture validation errors.

=signature yesno

  yesno() (Venus::Validate)

=metadata yesno

{
  since => '4.15',
}

=example-1 yesno

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('Yes');

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 1, 'yesno', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'Yes';
  is $result->is_valid, true;

  $result
});

=example-2 yesno

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('No');

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 2, 'yesno', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 'No';
  is $result->is_valid, true;

  $result
});

=example-3 yesno

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 3, 'yesno', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 1;
  is $result->is_valid, true;

  $result
});

=example-4 yesno

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(0);

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

$test->for('example', 4, 'yesno', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  ok !$result->issue;
  is $result->value, 0;
  is $result->is_valid, true;

  $result
});

=example-5 yesno

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=cut

$test->for('example', 5, 'yesno', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Validate');
  ok $result->input;
  is_deeply $result->issue, ['type', ['yesno']];
  is $result->value, 'hello';
  is $result->is_valid, false;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Validate.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
