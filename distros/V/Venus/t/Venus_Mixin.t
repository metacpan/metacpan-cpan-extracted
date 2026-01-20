package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Mixin

=cut

$test->for('name');

=tagline

Mixin Builder

=cut

$test->for('tagline');

=abstract

Mixin Builder for Perl 5

=cut

$test->for('abstract');

=includes

function: after
function: around
function: attr
function: base
function: before
function: catch
function: error
function: false
function: from
function: handle
function: hook
function: mask
function: mixin
function: raise
function: role
function: test
function: true
function: with

=cut

$test->for('includes');

=synopsis

  package Person;

  use Venus::Class 'attr';

  attr 'fname';
  attr 'lname';

  package Identity;

  use Venus::Mixin 'attr';

  attr 'id';
  attr 'login';
  attr 'password';

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['id', 'login', 'password']
  }

  package Authenticable;

  use Venus::Role;

  sub authenticate {
    return true;
  }

  sub AUDIT {
    my ($self, $from) = @_;
    # ensure the caller has a login and password when consumed
    die "${from} missing the login attribute" if !$from->can('login');
    die "${from} missing the password attribute" if !$from->can('password');
  }

  sub BUILD {
    my ($self, $data) = @_;
    $self->{auth} = undef;
    return $self;
  }

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['authenticate']
  }

  package User;

  use Venus::Class;

  base 'Person';

  mixin 'Identity';

  attr 'email';

  test 'Authenticable';

  sub valid {
    my ($self) = @_;
    return $self->login && $self->password ? true : false;
  }

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('User');
  ok $result->isa('Person');
  ok $result->can('fname');
  ok $result->can('lname');
  ok $result->can('email');
  ok $result->can('login');
  ok $result->can('password');
  ok $result->can('valid');
  ok !$result->valid;
  ok UNIVERSAL::isa($result, 'HASH');
  ok $result->fname eq 'Elliot';
  ok $result->lname eq 'Alderson';
  ok !$result->does('Identity');
  ok $result->does('Authenticable');
  ok exists $result->{auth};
  ok !defined $result->{auth};

  $result
});

=description

This package provides a mixin builder which when used causes the consumer to
inherit from L<Venus::Core::Mixin> which provides mixin building and lifecycle
L<hooks|Venus::Core>. A mixin can do almost everything that a role can do but
differs from a L<"role"|Venus::Role> in that whatever routines are declared
using L<"export"|Venus::Core/EXPORT> will be exported and will overwrite
routines of the same name in the consumer.

=cut

$test->for('description');

=function after

The after function installs a method modifier that executes after the original
method, allowing you to perform actions after a method call. B<Note:> The
return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is only exported when requested.

=signature after

  after(string $name, coderef $code) (coderef)

=metadata after

{
  since => '4.15',
}

=example-1 after

  package Example1;

  use Venus::Mixin 'after', 'attr';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub execute {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return 'original';
  }

  after 'execute', sub {
    my ($self) = @_;
    push @{$self->calls}, 'after';
    return 'ignored';
  };

  sub EXPORT {
    ['execute', 'calls', 'BUILD']
  }

  package Consumer;

  use Venus::Class;

  mixin 'Example1';

  package main;

  my $example = Consumer->new;
  my $result = $example->execute;

  # "original"

=cut

$test->for('example', 1, 'after', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'original';

  $result
});

=function around

The around function installs a method modifier that wraps around the original
method. The callback provided will recieve the original routine as its first
argument. This function is only exported when requested.

=signature around

  around(string $name, coderef $code) (coderef)

=metadata around

{
  since => '4.15',
}

=example-1 around

  package Example2;

  use Venus::Mixin 'around', 'attr';

  sub process {
    my ($self, $value) = @_;
    return $value;
  }

  around 'process', sub {
    my ($orig, $self, $value) = @_;
    return $self->$orig($value) * 2;
  };

  sub EXPORT {
    ['process']
  }

  package Consumer2;

  use Venus::Class;

  mixin 'Example2';

  package main;

  my $result = Consumer2->new->process(5);

  # 10

=cut

$test->for('example', 1, 'around', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 10;

  $result
});

=function attr

The attr function creates attribute accessors for the calling package. This
function is always exported unless a routine of the same name already exists.

=signature attr

  attr(string $name) (string)

=metadata attr

{
  since => '1.00',
}

=example-1 attr

  package Example;

  use Venus::Mixin;

  attr 'name';

  # "Example"

=cut

$test->for('example', 1, 'attr', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->can('name');
  my $object = bless({}, $result);
  ok !$object->name;
  $object = bless({name => 'example'}, $result);
  ok $object->name eq 'example';

  $result
});

=function before

The before function installs a method modifier that executes before the
original method, allowing you to perform actions before a method call. B<Note:>
The return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is only exported when requested.

=signature before

  before(string $name, coderef $code) (coderef)

=metadata before

{
  since => '4.15',
}

=example-1 before

  package Example3;

  use Venus::Mixin 'attr', 'before';

  attr 'calls';

  sub perform {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return $self;
  }

  before 'perform', sub {
    my ($self) = @_;
    push @{$self->calls}, 'before';
    return $self;
  };

  sub EXPORT {
    ['perform']
  }

  package Consumer3;

  use Venus::Class;

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  mixin 'Example3';

  package main;

  my $example = Consumer3->new;
  $example->perform;
  my $calls = $example->calls;

  # ['before', 'original']

=cut

$test->for('example', 1, 'before', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['before', 'original'];

  $result
});

=function base

The base function registers one or more base classes for the calling package.
This function is always exported unless a routine of the same name already
exists.

=signature base

  base(string $name) (string)

=metadata base

{
  since => '1.00',
}

=example-1 base

  package Entity;

  use Venus::Class;

  sub output {
    return;
  }

  package Example;

  use Venus::Mixin;

  base 'Entity';

  # "Example"

=cut

$test->for('example', 1, 'base', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Entity');
  ok $result->isa('Venus::Core::Class');
  ok $result->isa('Venus::Core');
  ok $result->can('output');

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
  since => '1.02',
}

=example-1 catch

  package Ability;

  use Venus::Mixin 'catch';

  sub attempt_catch {
    catch {die};
  }

  sub EXPORT {
    ['attempt_catch']
  }

  package Example;

  use Venus::Class 'with';

  mixin 'Ability';

  package main;

  my $example = Example->new;

  my $error = $example->attempt_catch;

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
exception object arguments provided. This function isn't export unless requested.

=signature error

  error(maybe[hashref] $args) (Venus::Error)

=metadata error

{
  since => '1.02',
}

=example-1 error

  package Ability;

  use Venus::Mixin 'error';

  sub attempt_error {
    error;
  }

  sub EXPORT {
    ['attempt_error']
  }

  package Example;

  use Venus::Class 'with';

  with 'Ability';

  package main;

  my $example = Example->new;

  my $error = $example->attempt_error;

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
  since => '1.00',
}

=example-1 false

  package Example;

  use Venus::Mixin;

  my $false = false;

  # 0

=cut

$test->for('example', 1, 'false', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=example-2 false

  package Example;

  use Venus::Mixin;

  my $true = !false;

  # 1

=cut

$test->for('example', 2, 'false', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=function from

The from function registers one or more base classes for the calling package
and performs an L<"audit"|Venus::Core/AUDIT>. This function is always exported
unless a routine of the same name already exists.

=signature from

  from(string $name) (string)

=metadata from

{
  since => '1.00',
}

=example-1 from

  package Entity;

  use Venus::Role;

  attr 'startup';
  attr 'shutdown';

  sub EXPORT {
    ['startup', 'shutdown']
  }

  package Record;

  use Venus::Class;

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package Example;

  use Venus::Class;

  with 'Entity';

  from 'Record';

  # "Example"

=cut

$test->for('example', 1, 'from', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Record');
  ok $result->does('Entity');
  ok $result->can('startup');
  ok $result->can('shutdown');

  $result
});

=function handle

The handle function installs a method modifier that wraps a method, providing
low-level control. The callback provided will recieve the original routine as
its first argument (or C<undef> if the source routine doesn't exist). This
function is only exported when requested.

=signature handle

  handle(string $name, coderef $code) (coderef)

=metadata handle

{
  since => '4.15',
}

=example-1 handle

  package Example4;

  use Venus::Mixin 'handle';

  sub compute {
    my ($self, $value) = @_;
    return $value;
  }

  handle 'compute', sub {
    my ($orig, $self, $value) = @_;
    return $orig ? $self->$orig($value * 2) : 0;
  };

  sub EXPORT {
    ['compute']
  }

  package Consumer4;

  use Venus::Class;

  mixin 'Example4';

  package main;

  my $result = Consumer4->new->compute(5);

  # 10

=cut

$test->for('example', 1, 'handle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 10;

  $result
});

=function hook

The hook function installs a method modifier on a lifecycle hook method. The
first argument is the type of modifier desired, e.g., L</before>, L</after>,
L</around>, and the callback provided will recieve the original routine as its
first argument. This function is only exported when requested.

=signature hook

  hook(string $type, string $name, coderef $code) (coderef)

=metadata hook

{
  since => '4.15',
}

=example-1 hook

  package Example5;

  use Venus::Mixin 'attr', 'hook';

  attr 'startup';

  sub BUILD {
    my ($self, $args) = @_;
    $self->startup('original');
  }

  hook 'after', 'build', sub {
    my ($self) = @_;
    $self->startup('modified');
  };

  sub EXPORT {
    ['startup', 'BUILD']
  }

  package Consumer5;

  use Venus::Class;

  mixin 'Example5';

  package main;

  my $result = Consumer5->new->startup;

  # "modified"

=cut

$test->for('example', 1, 'hook', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'modified';

  $result
});

=function mask

The mask function creates private attribute accessors that can only be accessed
from within the class or its subclasses. This function is exported on-demand
unless a routine of the same name already exists.

=signature mask

  mask(string $name) (string)

=metadata mask

{
  since => '4.15',
}

=example-1 mask

  package Example;

  use Venus::Mixin;

  mask 'cache';

  sub get_cache {
    my ($self) = @_;
    return $self->cache;
  }

  sub set_cache {
    my ($self, $value) = @_;
    $self->cache($value);
  }

  sub EXPORT {
    ['cache', 'get_cache', 'set_cache']
  }

  package Consumer;

  use Venus::Class;

  mixin 'Example';

  package main;

  my $consumer = Consumer->new;

=cut

$test->for('example', 1, 'mask', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result->set_cache('test_value');
  is $result->get_cache, 'test_value', 'mask accessible from mixin methods';

  like do {eval {$result->cache}; $@},
    qr/private variable/, 'mask prevents external access';

  $result
});

=function mixin

The mixin function registers and consumes mixins for the calling package. This
function is always exported unless a routine of the same name already exists.

=signature mixin

  mixin(string $name) (string)

=metadata mixin

{
  since => '1.02',
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

  use Venus::Mixin;

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

  use Venus::Mixin;

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
  since => '1.02',
}

=example-1 raise

  package Ability;

  use Venus::Mixin 'raise';

  sub attempt_raise {
    raise 'Example::Error';
  }

  sub EXPORT {
    ['attempt_raise']
  }

  package Example;

  use Venus::Class 'with';

  with 'Ability';

  package main;

  my $example = Example->new;

  my $error = $example->attempt_raise;

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
  since => '1.00',
}

=example-1 role

  package Ability;

  use Venus::Role;

  sub action {
    return;
  }

  package Example;

  use Venus::Class;

  role 'Ability';

  # "Example"

=cut

$test->for('example', 1, 'role', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->does('Ability');
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

  use Venus::Class;

  role 'Ability';

  # "Example"

=cut

$test->for('example', 2, 'role', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->does('Ability');
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
  since => '1.00',
}

=example-1 test

  package Actual;

  use Venus::Role;

  package Example;

  use Venus::Class;

  test 'Actual';

  # "Example"

=cut

$test->for('example', 1, 'test', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->does('Actual');

  $result
});

=example-2 test

  package Actual;

  use Venus::Role;

  sub AUDIT {
    die "Example is not an 'actual' thing" if $_[1]->isa('Example');
  }

  package Example;

  use Venus::Class;

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
  since => '1.00',
}

=example-1 true

  package Example;

  use Venus::Class;

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

  use Venus::Class;

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
  since => '1.00',
}

=example-1 with

  package Understanding;

  use Venus::Role;

  sub knowledge {
    return;
  }

  package Example;

  use Venus::Class;

  with 'Understanding';

  # "Example"

=cut

$test->for('example', 1, 'with', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->does('Understanding');
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

  use Venus::Class;

  with 'Understanding';

  # "Example"

=cut

$test->for('example', 2, 'with', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->does('Understanding');
  ok $result->can('knowledge');

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Mixin.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
