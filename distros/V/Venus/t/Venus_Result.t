package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Result

=cut

$test->for('name');

=tagline

Result Class

=cut

$test->for('tagline');

=abstract

Result Class for Perl 5

=cut

$test->for('abstract');

=includes

method: attest
method: check
method: invalid
method: is_invalid
method: is_valid
method: new
method: on_invalid
method: on_valid
method: then
method: valid

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Result;

  my $result = Venus::Result->new;

  # $result->is_valid;

  # true

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  ok $result->is_valid;

  $result
});

=description

This package provides a container for representing success and error states in
a more structured and predictable way, and a mechanism for chaining subsequent
operations.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Buildable
Venus::Role::Tryable
Venus::Role::Catchable

=cut

$test->for('integrates');

=attribute issue

The issue attribute is read/write, accepts C<(any)> values, and is optional.

=signature issue

  issue(any $issue) (any)

=metadata issue

{
  since => '4.15',
}

=example-1 issue

  # given: synopsis;

  my $issue = $result->issue("Failed!");

  # "Failed!"

=cut

$test->for('example', 1, 'issue', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "Failed!";

  $result
});

=example-2 issue

  # given: synopsis;

  # given: example-1 issue;

  $issue = $result->issue;

  # "Failed!"

=cut

$test->for('example', 2, 'issue', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "Failed!";

  $result
});

=attribute value

The valid attribute is read/write, accepts C<(any)> values, and is optional.

=signature value

  value(any $value) (any)

=metadata value

{
  since => '4.15',
}

=example-1 value

  # given: synopsis;

  my $value = $result->value("Success!");

  # "Success!"

=cut

$test->for('example', 1, 'value', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "Success!";

  $result
});

=example-2 value

  # given: synopsis;

  # given: example-1 value;

  $value = $result->value;

  # "Success!"

=cut

$test->for('example', 2, 'value', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "Success!";

  $result
});

=method attest

The attest method validates the value of the attribute named, i.e. L</issue> or
L</value>, using the L<Venus::Assert> expression provided and returns the
result.

=signature attest

  attest(string $name, string $expr) (any)

=metadata attest

{
  since => '4.15',
}

=cut

=example-1 attest

  # given: synopsis

  package main;

  my $attest = $result->attest;

  # undef

=cut

$test->for('example', 1, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-2 attest

  # given: synopsis

  package main;

  $result->value("Success!");

  my $attest = $result->attest('value', 'number | string');

  # "Success!"

=cut

$test->for('example', 2, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Success!";

  $result
});

=example-3 attest

  # given: synopsis

  package main;

  my $attest = $result->attest('value', 'number | string');

  # Exception! (isa Venus::Check::Error)

=cut

$test->for('example', 3, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  ok defined $result;
  ok $result->isa('Venus::Check::Error');

  $result
});

=example-4 attest

  # given: synopsis

  package main;

  $result->issue("Failed!");

  my $attest = $result->attest('issue', 'number | string');

  # "Failed!"

=cut

$test->for('example', 4, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Failed!";

  $result
});

=example-5 attest

  # given: synopsis

  package main;

  my $attest = $result->attest('issue', 'number | string');

  # Exception! (isa Venus::Check::Error)

=cut

$test->for('example', 5, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  ok defined $result;
  ok $result->isa('Venus::Check::Error');

  $result
});

=method check

The check method validates the value of the attribute named, i.e. L</issue> or
L</value>, using the L<Venus::Assert> expression provided and returns the
true if the value is valid, and false otherwise.

=signature check

  check(string $name, string $expr) (boolean)

=metadata check

{
  since => '4.15',
}

=cut

=example-1 check

  # given: synopsis

  package main;

  my $check = $result->check;

  # true

=cut

$test->for('example', 1, 'check', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 check

  # given: synopsis

  package main;

  $result->value("Success!");

  my $check = $result->check('value', 'number | string');

  # true

=cut

$test->for('example', 2, 'check', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-3 check

  # given: synopsis

  package main;

  my $check = $result->check('value', 'number | string');

  # false

=cut

$test->for('example', 3, 'check', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  is $result, false;

  !$result
});

=example-4 check

  # given: synopsis

  package main;

  $result->issue("Failed!");

  my $check = $result->check('issue', 'number | string');

  # true

=cut

$test->for('example', 4, 'check', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-5 check

  # given: synopsis

  package main;

  my $check = $result->check('issue', 'number | string');

  # false

=cut

$test->for('example', 5, 'check', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  is $result, false;

  !$result
});

=method invalid

The invalid method returns a L<Venus::Result> object representing an issue and
error state.

=signature invalid

  invalid(any $error) (Venus::Result)

=metadata invalid

{
  since => '4.15',
}

=example-1 invalid

  package main;

  use Venus::Result;

  my $invalid = Venus::Result->invalid("Failed!");

  # bless(..., "Venus::Result")

=cut

$test->for('example', 1, 'invalid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, "Failed!";
  is $result->value, undef;
  ok $result->is_invalid;

  $result
});

=method is_invalid

The is_invalid method returns true if an error exists, and false otherwise.

=signature is_invalid

  is_invalid() (boolean)

=metadata is_invalid

{
  since => '4.15',
}

=example-1 is_invalid

  # given: synopsis;

  my $is_invalid = $result->is_invalid;

  # false

=cut

$test->for('example', 1, 'is_invalid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 is_invalid

  # given: synopsis;

  $result->value("Success!");

  my $is_invalid = $result->is_invalid;

  # false

=cut

$test->for('example', 2, 'is_invalid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-3 is_invalid

  # given: synopsis;

  $result->issue("Failed!");

  my $is_invalid = $result->is_invalid;

  # true

=cut

$test->for('example', 3, 'is_invalid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method is_valid

The is_valid method returns true if no error exists, and false otherwise.

=signature is_valid

  is_valid() (boolean)

=metadata is_valid

{
  since => '4.15',
}

=example-1 is_valid

  # given: synopsis;

  my $is_valid = $result->is_valid;

  # true

=cut

$test->for('example', 1, 'is_valid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 is_valid

  # given: synopsis;

  $result->value("Success!");

  my $is_valid = $result->is_valid;

  # true

=cut

$test->for('example', 2, 'is_valid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-3 is_valid

  # given: synopsis;

  $result->issue("Failed!");

  my $is_valid = $result->is_valid;

  # false

=cut

$test->for('example', 3, 'is_valid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method new

The new method returns a L<Venus::Result> object.

=signature new

  new(hashref $data) (Venus::Result)

=metadata new

{
  since => '4.15',
}

=example-1 new

  package main;

  use Venus::Result;

  my $new = Venus::Result->new;

  # bless(..., "Venus::Result")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  ok $result->is_valid;

  $result
});

=example-2 new

  package main;

  use Venus::Result;

  my $new = Venus::Result->new(value => "Success!");

  # bless(..., "Venus::Result")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->value, "Success!";
  ok $result->is_valid;

  $result
});

=example-3 new

  package main;

  use Venus::Result;

  my $new = Venus::Result->new({value => "Success!"});

  # bless(..., "Venus::Result")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->value, "Success!";
  ok $result->is_valid;

  $result
});

=method on_invalid

The on_invalid method chains an operations by passing the issue value of the
result to the callback provided and returns a L<Venus::Result> object.

=signature on_invalid

  on_invalid(coderef $callback) (Venus::Result)

=metadata on_invalid

{
  since => '4.15',
}

=example-1 on_invalid

  # given: synopsis;

  my $on_invalid = $result->on_invalid;

  # bless(..., "Venus::Result")

=cut

$test->for('example', 1, 'on_invalid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, undef;

  $result
});

=example-2 on_invalid

  # given: synopsis;

  my $on_invalid = $result->on_invalid(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=cut

$test->for('example', 2, 'on_invalid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, undef;

  $result
});

=example-3 on_invalid

  # given: synopsis;

  $result->issue("Failed!");

  my $on_invalid = $result->on_invalid(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=cut

$test->for('example', 3, 'on_invalid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, "New success!";

  $result
});

=example-4 on_invalid

  # given: synopsis;

  $result->issue("Failed!");

  my $on_invalid = $result->on_invalid(sub{
    die "New failure!";
  });

  # bless(..., "Venus::Result")

=cut

$test->for('example', 4, 'on_invalid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  like $result->issue, qr/New failure!/;
  is $result->value, undef;

  $result
});

=method on_valid

The on_valid method chains an operations by passing the success value of the
result to the callback provided and returns a L<Venus::Result> object.

=signature on_valid

  on_valid(coderef $callback) (Venus::Result)

=metadata on_valid

{
  since => '4.15',
}

=example-1 on_valid

  # given: synopsis;

  my $on_valid = $result->on_valid;

  # bless(..., "Venus::Result")

=cut

$test->for('example', 1, 'on_valid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, undef;

  $result
});

=example-2 on_valid

  # given: synopsis;

  my $on_valid = $result->on_valid(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=cut

$test->for('example', 2, 'on_valid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, "New success!";

  $result
});

=example-3 on_valid

  # given: synopsis;

  $result->issue("Failed!");

  my $on_valid = $result->on_valid(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=cut

$test->for('example', 3, 'on_valid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, "Failed!";
  is $result->value, undef;

  $result
});

=example-4 on_valid

  # given: synopsis;

  my $on_valid = $result->on_valid(sub{
    die "New failure!";
  });

  # bless(..., "Venus::Result")

=cut

$test->for('example', 4, 'on_valid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  like $result->issue, qr/New failure!/;
  is $result->value, undef;

  $result
});

=method then

The then method chains an operations by passing the value or issue of the
result to the callback provided and returns a L<Venus::Result> object.

=signature then

  then(string | coderef $callback, any @args) (Venus::Result)

=metadata then

{
  since => '4.15',
}

=cut

=example-1 then

  # given: synopsis;

  my $then = $result->then;

  # bless(..., "Venus::Result")

=cut

$test->for('example', 1, 'then', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, undef;

  $result
});

=example-2 then

  # given: synopsis;

  my $then = $result->then(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=cut

$test->for('example', 2, 'then', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, "New success!";

  $result
});

=example-3 then

  # given: synopsis;

  $result->issue("Failed!");

  my $then = $result->then(sub{
    return "New success!";
  });

  # bless(..., "Venus::Result")

=cut

$test->for('example', 3, 'then', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, "New success!";

  $result
});

=example-4 then

  # given: synopsis;

  my $then = $result->then(sub{
    die "New failure!";
  });

  # bless(..., "Venus::Result")

=cut

$test->for('example', 4, 'then', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  like $result->issue, qr/New failure!/;
  is $result->value, undef;

  $result
});

=method valid

The valid method returns a L<Venus::Result> object representing a value and
success state.

=signature valid

  valid(any $value) (Venus::Result)

=metadata valid

{
  since => '4.15',
}

=example-1 valid

  package main;

  use Venus::Result;

  my $valid = Venus::Result->valid("Success!");

  # bless(..., "Venus::Result")

=cut

$test->for('example', 1, 'valid', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, "Success!";
  ok $result->is_valid;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Result.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
