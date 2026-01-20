package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Throw

=cut

$test->for('name');

=tagline

Throw Class

=cut

$test->for('tagline');

=abstract

Throw Class for Perl 5

=cut

$test->for('abstract');

=includes

method: die
method: error
method: new

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new;

  # $throw->error;

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=description

This package provides a mechanism for generating and raising errors (exception
objects).

=cut

$test->for('description');

=inherits

Venus::Error

=cut

$test->for('inherits');

=attribute package

The package attribute is read-write, accepts C<(string)> values, and is
optional.

=signature package

  package(string $package) (string)

=metadata package

{
  since => '4.15',
}

=cut

=example-1 package

  # given: synopsis

  package main;

  my $package = $throw->package("Example");

  # "Example"

=cut

$test->for('example', 1, 'package', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example";

  $result
});

=example-2 package

  # given: synopsis

  # given: example-1 package

  package main;

  $package = $throw->package;

  # "Example"

=cut

$test->for('example', 2, 'package', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example";

  $result
});

=attribute parent

The parent attribute is read-write, accepts C<(string)> values, and is
optional.

=signature parent

  parent(string $parent) (string)

=metadata parent

{
  since => '4.15',
}

=cut

=example-1 parent

  # given: synopsis

  package main;

  my $parent = $throw->parent("Venus::Error");

  # "Venus::Error"

=cut

$test->for('example', 1, 'parent', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Venus::Error";

  $result
});

=example-2 parent

  # given: synopsis

  # given: example-1 parent

  package main;

  $parent = $throw->parent;

  # "Venus::Error"

=cut

$test->for('example', 2, 'parent', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Venus::Error";

  $result
});

=method die

The die method builds an error object from the attributes set on the invocant
and throws it.

=signature die

  die(hashref $data) (Venus::Error)

=metadata die

{
  since => '4.15',
}

=example-1 die

  # given: synopsis;

  my $die = $throw->die;

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Exception!",
  # }, "Main::Error")

=cut

$test->for('example', 1, 'die', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error->result;
  ok $result->isa('Main::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Exception!';
  ok $result->context;

  $result
});

=example-2 die

  # given: synopsis;

  my $die = $throw->die({
    message => 'Something failed!',
    context => 'Test.error',
  });

  # bless({
  #   ...,
  #   "context"  => "Test.error",
  #   "message"  => "Something failed!",
  # }, "Main::Error")

=cut

$test->for('example', 2, 'die', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error->result;
  ok $result->isa('Main::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Something failed!';
  ok $result->context eq 'Test.error';

  $result
});

=example-3 die

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new('Example::Error');

  my $die = $throw->die;

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Exception!",
  # }, "Example::Error")

=cut

$test->for('example', 3, 'die', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error->result;
  ok $result->isa('Example::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Exception!';
  ok $result->context eq '(eval)';

  $result
});

=example-4 die

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error',
    parent => 'Venus::Error',
  );

  my $die = $throw->die({
    message => 'Example error!',
  });

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Example error!",
  # }, "Example::Error")

=cut

$test->for('example', 4, 'die', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error->result;
  ok $result->isa('Example::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Example error!';
  ok $result->context eq '(eval)';

  $result
});

=example-5 die

  package Example::Error;

  use base 'Venus::Error';

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error::Unknown',
    parent => 'Example::Error',
  );

  my $die = $throw->die({
    message => 'Example error (unknown)!',
  });

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Example error (unknown)!",
  # }, "Example::Error::Unknown")

=cut

$test->for('example', 5, 'die', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error->result;
  ok $result->isa('Example::Error::Unknown');
  ok $result->isa('Example::Error');
  ok $result->message eq 'Example error (unknown)!';
  ok $result->context eq '(eval)';

  $result
});

=example-6 die

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error::NoThing',
    parent => 'No::Thing',
  );

  my $die = $throw->die({
    message => 'Example error (no thing)!',
    raise => true,
  });

  # No::Thing does not exist

  # Exception! Venus::Throw::Error (isa Venus::Error)

=cut

$test->for('example', 6, 'die', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error->result;
  ok $result->isa('Venus::Throw::Error');
  ok $result->isa('Venus::Error');

  $result
});

=example-7 die

  # given: synopsis;

  my $die = $throw->die({
    name => 'on.test.error',
    context => 'Test.error',
    message => 'Something failed!',
  });

  # bless({
  #   ...,
  #   "context"  => "Test.error",
  #   "message"  => "Something failed!",
  #   "name"  => "on_test_error",
  # }, "Main::Error")

=cut

$test->for('example', 7, 'die', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error->result;
  ok $result->isa('Main::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Something failed!';
  ok $result->context eq 'Test.error';
  ok $result->name eq 'on.test.error';

  $result
});

=method error

The error method builds an error object from the attributes set on the invocant
and returns or optionally automatically throws it.

=signature error

  error(hashref $data) (Venus::Error)

=metadata error

{
  since => '0.01',
}

=example-1 error

  # given: synopsis;

  my $error = $throw->error;

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Exception!",
  # }, "Main::Error")

=cut

$test->for('example', 1, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Main::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Exception!';
  ok $result->context;

  $result
});

=example-2 error

  # given: synopsis;

  my $error = $throw->error({
    message => 'Something failed!',
    context => 'Test.error',
  });

  # bless({
  #   ...,
  #   "context"  => "Test.error",
  #   "message"  => "Something failed!",
  # }, "Main::Error")

=cut

$test->for('example', 2, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Main::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Something failed!';
  ok $result->context eq 'Test.error';

  $result
});

=example-3 error

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new('Example::Error');

  my $error = $throw->error;

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Exception!",
  # }, "Example::Error")

=cut

$test->for('example', 3, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Exception!';
  ok $result->context eq '(eval)';

  $result
});

=example-4 error

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error',
    parent => 'Venus::Error',
  );

  my $error = $throw->error({
    message => 'Example error!',
  });

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Example error!",
  # }, "Example::Error")

=cut

$test->for('example', 4, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Example error!';
  ok $result->context eq '(eval)';

  $result
});

=example-5 error

  package Example::Error;

  use base 'Venus::Error';

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error::Unknown',
    parent => 'Example::Error',
  );

  my $error = $throw->error({
    message => 'Example error (unknown)!',
  });

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Example error (unknown)!",
  # }, "Example::Error::Unknown")

=cut

$test->for('example', 5, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example::Error::Unknown');
  ok $result->isa('Example::Error');
  ok $result->message eq 'Example error (unknown)!';
  ok $result->context eq '(eval)';

  $result
});

=example-6 error

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error::NoThing',
    parent => 'No::Thing',
  );

  my $error = $throw->error({
    message => 'Example error (no thing)!',
    raise => true,
  });

  # No::Thing does not exist

  # Exception! Venus::Throw::Error (isa Venus::Error)

=cut

$test->for('example', 6, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok $error->isa('Venus::Throw::Error');
  ok $error->isa('Venus::Error');

  $result
});

=example-7 error

  # given: synopsis;

  my $error = $throw->error({
    name => 'on.test.error',
    context => 'Test.error',
    message => 'Something failed!',
  });

  # bless({
  #   ...,
  #   "context"  => "Test.error",
  #   "message"  => "Something failed!",
  #   "name"  => "on_test_error",
  # }, "Main::Error")

=cut

$test->for('example', 7, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Main::Error');
  ok $result->isa('Venus::Error');
  ok $result->message eq 'Something failed!';
  ok $result->context eq 'Test.error';
  ok $result->name eq 'on.test.error';

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Throw)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Throw;

  my $new = Venus::Throw->new;

  # bless(..., "Venus::Throw")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Throw');

  $result
});

=example-2 new

  package main;

  use Venus::Throw;

  my $new = Venus::Throw->new(package => 'Example::Error', parent => 'Venus::Error');

  # bless(..., "Venus::Throw")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Throw');
  is $result->package, 'Example::Error';
  is $result->parent, 'Venus::Error';

  $result
});


=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Throw.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;