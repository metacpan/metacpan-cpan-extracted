package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Module

=cut

$test->for('name');

=tagline

Module Builder

=cut

$test->for('tagline');

=abstract

Module Builder for Perl 5

=cut

$test->for('abstract');

=includes

function: after
function: around
function: before
function: catch
function: error
function: false
function: handle
function: hook
function: mixin
function: raise
function: role
function: test
function: true
function: with

=cut

$test->for('includes');

=synopsis

  package MakeError;

  use Venus::Module;

  sub make_error {
    require Venus::Error;
    Venus::Error->new(@_);
  }

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  BEGIN {
    MakeError->import;
  }

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->message, 'Oops';

  $result
});

=description

This package provides a package/module builder which when used causes the
consumer to inherit from L<Venus::Core> which provides lifecycle
L<hooks|Venus::Hook>.

=cut

$test->for('description');

=function after

The after function installs a method modifier that executes after the original
method, allowing you to perform actions after a method call. B<Note:> The
return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is always exported unless a routine of the same
name already exists.

=signature after

  after(string $name, coderef $code) (coderef)

=metadata after

{
  since => '4.15',
}

=example-1 after

  package MakeError;

  use Venus::Module 'after';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  after 'make_error', sub {
    push @{$EVENTS}, 'after';
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=cut

$test->for('example', 1, 'after', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->message, 'Oops';
  {
    no strict 'refs';
    is_deeply ${"MakeError::EVENTS"}, ['orig', 'after'];
  }
  $test->space('MakeError')->scrub;

  $result
});

=function around

The around function installs a method modifier that wraps around the original
method. The callback provided will recieve the original routine as its first
argument. This function is always exported unless a routine of the same name
already exists.

=signature around

  around(string $name, coderef $code) (coderef)

=metadata around

{
  since => '4.15',
}

=example-1 around

  package MakeError;

  use Venus::Module 'around';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  around 'make_error', sub {
    my ($orig, @args) = @_;
    push @{$EVENTS}, 'before';
    my $result = $orig->(@args);
    push @{$EVENTS}, 'after';
    $result
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=cut

$test->for('example', 1, 'around', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->message, 'Oops';
  {
    no strict 'refs';
    is_deeply ${"MakeError::EVENTS"}, ['before', 'orig', 'after'];
  }
  $test->space('MakeError')->scrub;

  $result
});

=function before

The before function installs a method modifier that executes before the
original method, allowing you to perform actions before a method call. B<Note:>
The return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is always exported unless a routine of the same
name already exists.

=signature before

  before(string $name, coderef $code) (coderef)

=metadata before

{
  since => '4.15',
}

=example-1 before

  package MakeError;

  use Venus::Module 'before';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  before 'make_error', sub {
    push @{$EVENTS}, 'before';
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=cut

$test->for('example', 1, 'before', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->message, 'Oops';
  {
    no strict 'refs';
    is_deeply ${"MakeError::EVENTS"}, ['before', 'orig'];
  }
  $test->space('MakeError')->scrub;

  $result
});

=function catch

The catch function executes the code block trapping errors and returning the
caught exception in scalar context, and also returning the result as a second
argument in list context. This function isn't export unless requested.

=signature catch

  catch(coderef $block) (Venus::Error, any)

=metadata catch

{
  since => '4.15',
}

=example-1 catch

  package Example;

  use Venus::Module 'catch';

  sub attempt {
    catch {die};
  }

  package main;

  my $error = Example::attempt;

  $error;

  # "Died at ..."

=cut

$test->for('example', 1, 'catch', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok !ref($result);

  $result
});

=function error

The error function throws a L<Venus::Error> exception object using the
exception object arguments provided. This function isn't export unless
requested.

=signature error

  error(maybe[hashref] $args) (Venus::Error)

=metadata error

{
  since => '4.15',
}

=example-1 error

  package Example;

  use Venus::Module 'error';

  sub attempt {
    error;
  }

  package main;

  my $error = Example::attempt;

  # bless({...}, 'Venus::Error')

=cut

$test->for('example', 1, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Exception!';

  $result
});

=function false

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value. This
function is always exported unless a routine of the same name already exists.

=signature false

  false() (boolean)

=metadata false

{
  since => '4.15',
}

=example-1 false

  package Example;

  use Venus::Module;

  my $false = false;

  # 0

=cut

$test->for('example', 1, 'false', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=function handle

The handle function installs a method modifier that wraps a method, providing
low-level control. The callback provided will recieve the original routine as
its first argument (or C<undef> if the source routine doesn't exist). This
function is always exported unless a routine of the same name already exists.

=signature handle

  handle(string $name, coderef $code) (coderef)

=metadata handle

{
  since => '4.15',
}

=example-1 handle

  package MakeError;

  use Venus::Module 'handle';

  our $EVENTS = [];

  handle 'make_error', sub {
    my ($orig, @args) = @_;
    push @{$EVENTS}, 'before';
    my $result = $orig->(@args) if $orig;
    push @{$EVENTS}, 'after';
    $result
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=cut

$test->for('example', 1, 'handle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;
  {
    no strict 'refs';
    is_deeply ${"MakeError::EVENTS"}, ['before', 'after'];
  }
  $test->space('MakeError')->scrub;

  !$result
});

=example-2 handle

  package MakeError;

  use Venus::Module 'handle';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  handle 'make_error', sub {
    my ($orig, @args) = @_;
    push @{$EVENTS}, 'before';
    my $result = $orig->(@args) if $orig;
    push @{$EVENTS}, 'after';
    $result
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=cut

$test->for('example', 2, 'handle', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->message, 'Oops';
  {
    no strict 'refs';
    is_deeply ${"MakeError::EVENTS"}, ['before', 'orig', 'after'];
  }
  $test->space('MakeError')->scrub;

  $result
});

=function hook

The hook function installs a method modifier on a lifecycle hook method. The
first argument is the type of modifier desired, e.g., L</before>, L</after>,
L</around>, and the callback provided will recieve the original routine as its
first argument. This function is always exported unless a routine of the same
name already exists.

=signature hook

  hook(string $type, string $name, coderef $code) (coderef)

=metadata hook

{
  since => '4.15',
}

=example-1 hook

  package MakeError;

  use Venus::Module 'hook';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  hook 'around', 'use', sub {
    push @{$EVENTS}, 'use';
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=cut

$test->for('example', 1, 'hook', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->message, 'Oops';
  {
    no strict 'refs';
    is_deeply ${"MakeError::EVENTS"}, ['use', 'orig'];
  }
  $test->space('MakeError')->scrub;

  $result
});

=function mixin

The mixin function registers and consumes mixins for the calling package. This
function is always exported unless a routine of the same name already exists.

=signature mixin

  mixin(string $name) (string)

=metadata mixin

{
  since => '4.15',
}

=example-1 mixin

  package YesNo;

  use Venus::Mixin;

  sub no {
    return 0;
  }

  sub yes {
    return 1;
  }

  sub EXPORT {
    ['no', 'yes']
  }

  package Answer;

  use Venus::Module;

  mixin 'YesNo';

  # "Answer"

=cut

$test->for('example', 1, 'mixin', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Answer');
  ok $result->can('yes');
  ok $result->can('no');
  ok $result->yes == 1;
  ok $result->no == 0;

  $result
});

=example-2 mixin

  package YesNo;

  use Venus::Mixin;

  sub no {
    return 0;
  }

  sub yes {
    return 1;
  }

  sub EXPORT {
    ['no', 'yes']
  }

  package Answer;

  use Venus::Module;

  mixin 'YesNo';

  sub no {
    return [0];
  }

  sub yes {
    return [1];
  }

  my $package = "Answer";

  # "Answer"

=cut

$test->for('example', 2, 'mixin', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->can('yes');
  ok $result->can('no');
  ok $result->yes == 1;
  ok $result->no == 0;

  $result
});

=function raise

The raise function generates and throws a named exception object derived from
L<Venus::Error>, or provided base class, using the exception object arguments
provided. This function isn't export unless requested.

=signature raise

  raise(string $class | tuple[string, string] $class, maybe[hashref] $args) (Venus::Error)

=metadata raise

{
  since => '4.15',
}

=example-1 raise

  package Example;

  use Venus::Module 'raise';

  sub attempt {
    raise 'Example::Error';
  }

  package main;

  my $error = Example::attempt;

  # bless({...}, 'Example::Error')

=cut

$test->for('example', 1, 'raise', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('Example::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Exception!';

  $result
});

=function role

The role function registers and consumes roles for the calling package. This
function is always exported unless a routine of the same name already exists.

=signature role

  role(string $name) (string)

=metadata role

{
  since => '4.15',
}

=example-1 role

  package Ability;

  use Venus::Role;

  sub action {
    return;
  }

  package Example;

  use Venus::Module;

  role 'Ability';

  # "Example"

=cut

$test->for('example', 1, 'role', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->DOES('Ability');
  ok !$result->can('action');

  $result
});

=example-2 role

  package Ability;

  use Venus::Role;

  sub action {
    return;
  }

  sub EXPORT {
    return ['action'];
  }

  package Example;

  use Venus::Module;

  role 'Ability';

  # "Example"

=cut

$test->for('example', 2, 'role', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->DOES('Ability');
  ok $result->can('action');

  $result
});

=function test

The test function registers and consumes roles for the calling package and
performs an L<"audit"|Venus::Core/AUDIT>, effectively allowing a role to act as
an interface. This function is always exported unless a routine of the same
name already exists.

=signature test

  test(string $name) (string)

=metadata test

{
  since => '4.15',
}

=example-1 test

  package Actual;

  use Venus::Role;

  package Example;

  use Venus::Module;

  test 'Actual';

  # "Example"

=cut

$test->for('example', 1, 'test', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok !$error;
  ok $result->DOES('Actual');

  $result
});

=example-2 test

  package Actual;

  use Venus::Role;

  sub AUDIT {
    die "Example is not an 'actual' thing" if $_[1]->isa('Example');
  }

  package Example;

  use Venus::Module;

  test 'Actual';

  # "Example"

=cut

$test->for('example', 2, 'test', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok $error =~ qr/Example is not an 'actual' thing/;

  $result
});

=function true

The true function returns a truthy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<1> value. This
function is always exported unless a routine of the same name already exists.

=signature true

  true() (boolean)

=metadata true

{
  since => '4.15',
}

=example-1 true

  package Example;

  use Venus::Module;

  my $true = true;

  # 1

=cut

$test->for('example', 1, 'true', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 true

  package Example;

  use Venus::Module;

  my $false = !true;

  # 0

=cut

$test->for('example', 2, 'true', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=function with

The with function registers and consumes roles for the calling package. This
function is an alias of the L</test> function and will perform an
L<"audit"|Venus::Core/AUDIT> if present. This function is always exported
unless a routine of the same name already exists.

=signature with

  with(string $name) (string)

=metadata with

{
  since => '4.15',
}

=example-1 with

  package Understanding;

  use Venus::Role;

  sub knowledge {
    return;
  }

  package Example;

  use Venus::Module;

  with 'Understanding';

  # "Example"

=cut

$test->for('example', 1, 'with', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->DOES('Understanding');
  ok !$result->can('knowledge');

  $result
});

=example-2 with

  package Understanding;

  use Venus::Role;

  sub knowledge {
    return;
  }

  sub EXPORT {
    return ['knowledge'];
  }

  package Example;

  use Venus::Module;

  with 'Understanding';

  # "Example"

=cut

$test->for('example', 2, 'with', sub {
  my ($tryable) = @_;
  no warnings 'redefine';
  ok my $result = $tryable->result;
  ok $result->DOES('Understanding');
  ok $result->can('knowledge');

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Module.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
