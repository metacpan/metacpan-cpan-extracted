package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Factory

=cut

$test->for('name');

=tagline

Factory Class

=cut

$test->for('tagline');

=abstract

Factory Class for Perl 5

=cut

$test->for('abstract');

=includes

method: args
method: arrayref
method: attach
method: assert
method: builder
method: cache
method: cached
method: callback
method: chain
method: class
method: clone
method: constructor
method: detach
method: dispatch
method: extend
method: function
method: hashref
method: list
method: method
method: new
method: package
method: protocol
method: register
method: registry
method: reset
method: resolve
method: retrieve
method: routine
method: value

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Factory;

  my $factory = Venus::Factory->new;

  # $factory->class('Venus::Path');

  # $factory->build;

  # bless(.., "Venus::Path")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=description

This package provides an object-oriented factory pattern and mechanism for
building objects using dependency injection.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Buildable
Venus::Role::Encaseable
Venus::Role::Tryable
Venus::Role::Catchable
Venus::Role::Throwable

=cut

$test->for('integrates');

=attribute name

The name attribute is read/write, accepts C<(string)> values, is optional, and
defaults to C<undef>.

=signature name

  name(string $name) (string)

=metadata name

{
  since => '4.15',
}

=example-1 name

  # given: synopsis;

  my $name = $factory->name('log');

  # "log"

=cut

$test->for('example', 1, 'name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, 'log';

  $result
});

=example-2 name

  # given: synopsis;

  # given: example-1 name

  $name = $factory->name;

  # "log"

=cut

$test->for('example', 2, 'name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, 'log';

  $result
});

=method args

The args method accepts arguments and merges them with any L</arrayref>,
L</hashref>, or L</list> registered in the current configuration and returns
the result. Returns a list in list context.

+=over 4

+=item * If an L</arrayref> exists and the argment is an arrayref, the values are
merged by appending the arguments provided to the end of the registered arrayref.

+=item * If a L</hashref> exists and the argment is a hashref, the values are
merged without overriding the keys and values from the registered hashref.

+=item * If a L</list> exists and the argment is a list of values, the values are
merged by appending the arguments provided to the end of the registered list.

+=back

=signature args

  args(any @args) (Any)

=metadata args

{
  since => '4.15',
}

=cut

=example-1 args

  # given: synopsis

  package main;

  my @args = $factory->args;

  # ()

=cut

$test->for('example', 1, 'args', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  ok !@result;

  !@result
});

=example-2 args

  # given: synopsis

  package main;

  my $args = $factory->args;

  # undef

=cut

$test->for('example', 2, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-3 args

  # given: synopsis

  package main;

  my $args = $factory->args({path => '/root'});

  # {path => "/root"}

=cut

$test->for('example', 3, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {path => '/root'};

  $result
});

=example-4 args

  # given: synopsis

  package main;

  $factory->value({path => '/boot'});

  my $args = $factory->args({path => '/root'});

  # {path => "/root"}

=cut

$test->for('example', 4, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {path => '/root'};

  $result
});

=example-5 args

  # given: synopsis

  package main;

  $factory->value({path => '/boot'});

  my $args = $factory->args;

  # {path => "/boot"}

=cut

$test->for('example', 5, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {path => '/boot'};

  $result
});

=example-6 args

  # given: synopsis

  package main;

  $factory->value(name => 'example');

  my @args = $factory->args;

  # ('name', 'example')

=cut

$test->for('example', 6, 'args', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['name', 'example'];

  @result
});

=example-7 args

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->list('data.home', 'data.root');

  my @args = $factory->args;

  # ('/home', '/root')

=cut

$test->for('example', 7, 'args', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['/home', '/root'];

  @result
});

=example-8 args

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->list('data.home', 'data.root');

  my @args = $factory->args('/boot');

  # ('/home', '/root', '/boot')

=cut

$test->for('example', 8, 'args', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['/home', '/root', '/boot'];

  @result
});

=example-9 args

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->arrayref('data.home', 'data.root');

  my $args = $factory->args;

  # ['/home', '/root']

=cut

$test->for('example', 9, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['/home', '/root'];

  $result
});

=example-10 args

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->arrayref('data.home', 'data.root');

  my $args = $factory->args(['/boot']);

  # ['/home', '/root', '/boot']

=cut

$test->for('example', 10, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['/home', '/root', '/boot'];

  $result
});

=example-11 args

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->hashref({home => 'data.home', root => 'data.root'});

  my $args = $factory->args;

  # {home => '/home', root => '/root'}

=cut

$test->for('example', 11, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {home => '/home', root => '/root'};

  $result
});

=example-12 args

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->hashref({home => 'data.home', root => 'data.root'});

  my $args = $factory->args({boot => '/boot'});

  # {home => '/home', root => '/root', boot => '/boot'}

=cut

$test->for('example', 12, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {home => '/home', root => '/root', boot => '/boot'};

  $result
});

=method arrayref

The arrayref method modifies the current configuration and registers an
arrayref where each value is a string or arrayref representing arguments to be
passed to L</build>, each value is resolved and the resulting arrayref merged
with the L</value> upon resolution.

=signature arrayref

  arrayref(arrayref $data) (arrayref)

=metadata arrayref

{
  since => '4.15',
}

=example-1 arrayref

  # given: synopsis;

  my $arrayref = $factory->arrayref;

  # undef

=cut

$test->for('example', 1, 'arrayref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 arrayref

  # given: synopsis;

  my $arrayref = $factory->arrayref('path');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'arrayref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  is_deeply $result->arrayref, ['path'];

  $result
});

=example-3 arrayref

  # given: synopsis;

  $factory->arrayref('path');

  my $arrayref = $factory->arrayref;

  # ['path']

=cut

$test->for('example', 3, 'arrayref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['path'];

  $result
});

=example-4 arrayref

  # given: synopsis;

  my $arrayref = $factory->arrayref(['path', '/var/log'], ['path', '/tmp/log']);

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 4, 'arrayref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  is_deeply $result->arrayref, [['path', '/var/log'], ['path', '/tmp/log']];

  $result
});

=method attach

The attach method adds an existing L<"detached"|/detach> container to the
registry and returns container.

=signature attach

  attach(string $name, Venus::Factory $data) (Venus::Factory)

=metadata attach

{
  since => '4.15',
}

=cut

=example-1 attach

  # given: synopsis

  package main;

  my $attach = $factory->attach;

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 1, 'attach', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  is $result->registry, undef;

  $result
});

=example-2 attach

  # given: synopsis

  package main;

  my $attach = $factory->attach('path', Venus::Factory->new->class('Venus::Path'));

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'attach', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok keys %{$result->registry} == 1;
  ok $result->registry->{path};
  is $result->{assert}, 'Venus::Path';
  is $result->{dispatch}, 'new';
  is $result->{package}, 'Venus::Path';
  is $result->{protocol}, 'method';

  $result
});

=method assert

The assert method modifies the current configuration and registers a type
expression to be used to validate the resulting object upon resolution.

=signature assert

  assert(string $expr) (Venus::Factory)

=metadata assert

{
  since => '4.15',
}

=example-1 assert

  # given: synopsis;

  my $assert = $factory->assert;

  # undef

=cut

$test->for('example', 1, 'assert', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 assert

  # given: synopsis;

  my $assert = $factory->assert('Example');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'assert', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 assert

  # given: synopsis;

  $factory->assert('Example');

  my $assert = $factory->assert;

  # "Example"

=cut

$test->for('example', 3, 'assert', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Example';

  $result
});

=method build


The build method L<"resolves"|/resolve> and returns an object or value based on
the configuration key or service name provided.  Any arguments provided (or
registered L<"values"|/value>) are merged with any registered L</arrayref>,
L</hashref>, or L</list> values.

=signature build

  build(string $name, any @args) (any)

=metadata build

{
  since => '4.15',
}

=example-1 build

  # given: synopsis;

  my $build = $factory->build;

  # undef

=cut

$test->for('example', 1, 'build', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 build

  # given: synopsis;

  $factory->class('Venus::Path');

  my $build = $factory->build;

  # class(..., "Venus::Path")

=cut

$test->for('example', 2, 'build', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  $result->isa('Venus::Path');

  $result
});

=example-3 build

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $build = $factory->build('path');

  # class(..., "Venus::Path")

=cut

$test->for('example', 3, 'build', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  $result->isa('Venus::Path');

  $result
});

=example-4 build

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $build = $factory->build('path', '/tmp');

  # class(..., "Venus::Path")

=cut

$test->for('example', 4, 'build', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  $result->isa('Venus::Path');
  is $result->value, '/tmp';

  $result
});

=method builder

The builder method modifies the current configuration and registers a callback
invoked during resolution which the resolved object is passed through. The
return value of the callback will be returned by L</resolve>.

=signature builder

  builder(coderef $callback) (coderef)

=metadata builder

{
  since => '4.15',
}

=example-1 builder

  # given: synopsis;

  my $builder = $factory->builder;

  # undef

=cut

$test->for('example', 1, 'builder', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 builder

  # given: synopsis;

  my $builder = $factory->builder(sub{});

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'builder', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 builder

  # given: synopsis;

  $factory->builder(sub{});

  my $builder = $factory->builder;

  # sub{}

=cut

$test->for('example', 3, 'builder', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is ref $result, 'CODE';

  $result
});

=method cache

The cache method gets and sets a store to be used by all derived containers
where objects will be cached upon resolution.

=signature cache

  cache(hashref $cache) (hashref)

=metadata cache

{
  since => '4.15',
}

=example-1 cache

  # given: synopsis;

  my $cache = $factory->cache;

  # undef

=cut

$test->for('example', 1, 'cache', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 cache

  # given: synopsis;

  my $cache = $factory->cache({});

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'cache', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 cache

  # given: synopsis;

  $factory->cache(sub{});

  my $cache = $factory->cache;

  # sub{}

=cut

$test->for('example', 3, 'cache', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is ref $result, 'CODE';

  $result
});

=method cached

The cached method modifies the current configuration and denotes that the
object should be cached upon resolution.

=signature cached

  cached(boolean $bool) (Venus::Factory)

=metadata cached

{
  since => '4.15',
}

=example-1 cached

  # given: synopsis;

  my $cached = $factory->cached;

  # undef

=cut

$test->for('example', 1, 'cached', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 cached

  # given: synopsis;

  my $cached = $factory->cached(true);

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'cached', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 cached

  # given: synopsis;

  $factory->cached(true);

  my $cached = $factory->cached;

  # true

=cut

$test->for('example', 3, 'cached', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method callback

The callback method modifies the current configuration and denotes that a
coderef containing the resolved object should be returned upon resolution.

=signature callback

  callback(any @args) (Venus::Factory)

=metadata callback

{
  since => '4.15',
}

=example-1 callback

  # given: synopsis;

  my $callback = $factory->callback;

  # sub{...}

=cut

$test->for('example', 1, 'callback', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is ref $result, 'CODE';
  is $result->(), undef;

  $result
});

=example-2 callback

  # given: synopsis;

  $factory->class('Venus::Path');

  my $callback = $factory->callback('.');

  # sub{...}

=cut

$test->for('example', 2, 'callback', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is ref $result, 'CODE';
  my $returned = $result->();
  ok $returned->isa('Venus::Path');
  is $returned->value, '.';

  $result
});

=method chain

The chain method method modifies the current configuration and registers a
string or arrayref representing subsequent method calls to be chained upon
resolution.

=signature chain

  chain(string | within[arrayref, string] @chain) (Venus::Factory)

=metadata chain

{
  since => '4.15',
}

=example-1 chain

  # given: synopsis;

  my $chain = $factory->chain;

  # undef

=cut

$test->for('example', 1, 'chain', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 chain

  # given: synopsis;

  my $chain = $factory->chain('step_1');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'chain', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 chain

  # given: synopsis;

  $factory->chain('step_1');

  my $chain = $factory->chain;

  # ["step_1"]

=cut

$test->for('example', 3, 'chain', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['step_1'];

  $result
});

=example-4 chain

  # given: synopsis;

  $factory->chain('step_1', 'step_2');

  my $chain = $factory->chain;

  # ["step_1", "step_2"]

=cut

$test->for('example', 4, 'chain', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['step_1', 'step_2'];

  $result
});

=example-5 chain

  # given: synopsis;

  $factory->chain('step_1', 'step_2', ['step_3', 1..4]);

  my $chain = $factory->chain;

  # ["step_1", "step_2", ["step_3", 1..4]]

=cut

$test->for('example', 5, 'chain', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['step_1', 'step_2', ['step_3', 1..4]];

  $result
});

=method class

The class method is shorthand for calling L</package>, L</assert>, and L</method> with the
argument C<"new">.

=signature class

  class(string $class) (Venus::Factory)

=metadata class

{
  since => '4.15',
}

=example-1 class

  # given: synopsis;

  my $class = $factory->class;

  # undef

=cut

$test->for('example', 1, 'class', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 class

  # given: synopsis;

  my $class = $factory->class('Venus::Path');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'class', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  is $result->{assert}, 'Venus::Path';
  is $result->{dispatch}, 'new';
  is $result->{package}, 'Venus::Path';
  is $result->{protocol}, 'method';

  $result
});

=example-3 class

  # given: synopsis;

  $factory->class('Venus::Path');

  my $class = $factory->class;

  # "Venus::Path"

=cut

$test->for('example', 3, 'class', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Venus::Path';

  $result
});

=method clone

The clone method clones the current configuration and returns a container not
attached to the registry.

=signature clone

  clone() (Venus::Factory)

=metadata clone

{
  since => '4.15',
}

=cut

=example-1 clone

  # given: synopsis

  package main;

  my $clone = $factory->clone;

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 1, 'clone', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok !exists $result->{arrayref};
  ok !exists $result->{assert};
  ok !exists $result->{builder};
  ok !exists $result->{cached};
  ok !exists $result->{chain};
  ok !exists $result->{constructor};
  ok !exists $result->{dispatch};
  ok !exists $result->{hashref};
  ok !exists $result->{list};
  ok !exists $result->{name};
  ok !exists $result->{package};
  ok !exists $result->{protocol};
  ok !exists $result->{value};

  require Scalar::Util;
  isnt Scalar::Util::refaddr($result), Scalar::Util::refaddr($result->clone);

  $result
});

=example-2 clone

  # given: synopsis

  package main;

  $factory->class('Venus::Path')->name('path');

  my $clone = $factory->clone;

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'clone', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok !exists $result->{arrayref};
  is $result->{assert}, 'Venus::Path';
  ok !exists $result->{builder};
  ok !exists $result->{cached};
  ok !exists $result->{chain};
  ok !exists $result->{constructor};
  is $result->{dispatch}, 'new';
  ok !exists $result->{hashref};
  ok !exists $result->{list};
  is $result->{name}, 'path';
  is $result->{package}, 'Venus::Path';
  is $result->{protocol}, 'method';
  ok !exists $result->{value};

  require Scalar::Util;
  isnt Scalar::Util::refaddr($result), Scalar::Util::refaddr($result->clone);

  $result
});

=example-3 clone

  # given: synopsis

  package main;

  $factory->class('Venus::Path')->builder(sub{$_->absolute})->name('path');

  my $clone = $factory->clone;

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 3, 'clone', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok !exists $result->{arrayref};
  is $result->{assert}, 'Venus::Path';
  is ref $result->{builder}, 'CODE';
  ok !exists $result->{cached};
  ok !exists $result->{chain};
  ok !exists $result->{constructor};
  is $result->{dispatch}, 'new';
  ok !exists $result->{hashref};
  ok !exists $result->{list};
  is $result->{name}, 'path';
  is $result->{package}, 'Venus::Path';
  is $result->{protocol}, 'method';
  ok !exists $result->{value};

  require Scalar::Util;
  isnt Scalar::Util::refaddr($result), Scalar::Util::refaddr($result->clone);

  $result
});

=method constructor

The constructor method modifies the current configuration and registers a
callback invoked during resolution which is passed the package, if any, and the
resolved dependencies (and/or arguments), if any. The return value of the
callback will be considered the resolved object.

=signature constructor

  constructor(any @data) (defined)

=metadata constructor

{
  since => '4.15',
}

=example-1 constructor

  # given: synopsis;

  my $constructor = $factory->constructor;

  # undef

=cut

$test->for('example', 1, 'constructor', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 constructor

  # given: synopsis;

  my $constructor = $factory->constructor(sub{});

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'constructor', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 constructor

  # given: synopsis;

  $factory->constructor(sub{});

  my $constructor = $factory->constructor;

  # sub{}

=cut

$test->for('example', 3, 'constructor', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is ref $result, 'CODE';

  $result
});

=method detach

The detach method removes an existing container from the registry and returns
container. The detached container will still have access to the registry to
resolve dependencies. To detach from the registry use L</reset>.

=signature detach

  detach(string $name) (maybe[Venus::Factory])

=metadata detach

{
  since => '4.15',
}

=cut

=example-1 detach

  # given: synopsis

  package main;

  my $detach = $factory->detach('path');

  # undef

=cut

$test->for('example', 1, 'detach', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-2 detach

  # given: synopsis

  package main;

  $factory->register('path')->class('Venus::Path');

  my $detach = $factory->detach('path');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'detach', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok keys %{$result->registry} == 0;
  is $result->{assert}, 'Venus::Path';
  is $result->{dispatch}, 'new';
  is $result->{package}, 'Venus::Path';
  is $result->{protocol}, 'method';

  $result
});

=method dispatch

The dispatch method modifies the current configuration and denotes the
subroutine that should be dispatched to upon resolution.

=signature dispatch

  dispatch(string $name) (Venus::Factory)

=metadata dispatch

{
  since => '4.15',
}

=example-1 dispatch

  # given: synopsis;

  my $dispatch = $factory->dispatch;

  # undef

=cut

$test->for('example', 1, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 dispatch

  # given: synopsis;

  my $dispatch = $factory->dispatch('do_something');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 dispatch

  # given: synopsis;

  $factory->dispatch('do_something');

  my $dispatch = $factory->dispatch;

  # "do_something"

=cut

$test->for('example', 3, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'do_something';

  $result
});

=method extend

The extend method copies the details of the configuration specified to the
current configuration.

=signature extend

  extend(string $name) (Venus::Factory)

=metadata extend

{
  since => '4.15',
}

=example-1 extend

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $extend = $factory->extend;

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 1, 'extend', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok keys %{$result->registry} == 1;
  ok !$result->{assert};
  ok !$result->{dispatch};
  ok !$result->{package};
  ok !$result->{protocol};
  my $path = $result->registry->{path};
  ok $path->isa('Venus::Factory');
  is $path->{assert}, 'Venus::Path';
  is $path->{dispatch}, 'new';
  is $path->{package}, 'Venus::Path';
  is $path->{protocol}, 'method';

  $result
});

=example-2 extend

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $extend = $factory->register('temp')->extend('path');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'extend', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok keys %{$result->registry} == 2;
  is $result->{assert}, 'Venus::Path';
  is $result->{dispatch}, 'new';
  is $result->{package}, 'Venus::Path';
  is $result->{protocol}, 'method';
  my $path = $result->registry->{'path'};
  ok $path->isa('Venus::Factory');
  is $path->{assert}, 'Venus::Path';
  is $path->{dispatch}, 'new';
  is $path->{package}, 'Venus::Path';
  is $path->{protocol}, 'method';
  my $temp = $result->registry->{'temp'};
  ok $temp->isa('Venus::Factory');
  is $temp->{assert}, 'Venus::Path';
  is $temp->{dispatch}, 'new';
  is $temp->{package}, 'Venus::Path';
  is $temp->{protocol}, 'method';

  $result
});

=method function

The function method modifies the current configuration and denotes that object
resolution should result from a function call using the function name provided.

=signature function

  function(string $name) (Venus::Factory)

=metadata function

{
  since => '4.15',
}

=example-1 function

  # given: synopsis;

  my $function = $factory->function;

  # undef

=cut

$test->for('example', 1, 'function', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 function

  # given: synopsis;

  my $function = $factory->function('do_something');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'function', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 function

  # given: synopsis;

  $factory->function('do_something');

  my $function = $factory->function;

  # "do_something"

=cut

$test->for('example', 3, 'function', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'do_something';

  $result
});

=method hashref

The hashref method modifies the current configuration and registers an hashref
where each value is a string or arrayref representing arguments to be passed to
L</build>, each value is resolved and the resulting hashref is merged with the
L</value> upon resolution.

=signature hashref

  hashref(hashref $data) (hashref)

=metadata hashref

{
  since => '4.15',
}

=example-1 hashref

  # given: synopsis;

  my $hashref = $factory->hashref;

  # undef

=cut

$test->for('example', 1, 'hashref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 hashref

  # given: synopsis;

  my $hashref = $factory->hashref({path => 'path'});

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'hashref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 hashref

  # given: synopsis;

  $factory->hashref({path => 'path'});

  my $hashref = $factory->hashref;

  # {path => "path"}

=cut

$test->for('example', 3, 'hashref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {path => "path"};

  $result
});

=example-4 hashref

  # given: synopsis;

  $factory->hashref({
    tmplog => ['path', '/tmp/log'],
    varlog => ['path', '/var/log'],
  });

  my $hashref = $factory->hashref;

  # {tmplog => ["path", "/tmp/log"], varlog => ["path", "/var/log"]}

=cut

$test->for('example', 4, 'hashref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {tmplog => ['path', '/tmp/log'], varlog => ['path', '/var/log']};

  $result
});

=method list

The list method modifies the current configuration and registers a sequence of
values where each value is a string or arrayref representing arguments to be
passed to L</build>, each value is resolved and the resulting list is merged
with the L</value> upon resolution.

=signature list

  list(string | arrayref @data) (string | arrayref)

=metadata list

{
  since => '4.15',
}

=example-1 list

  # given: synopsis;

  my $list = $factory->list;

  # undef

=cut

$test->for('example', 1, 'list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 list

  # given: synopsis;

  my $list = $factory->list('path');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 list

  # given: synopsis;

  $factory->list('path');

  my @list = $factory->list;

  # ("path")

=cut

$test->for('example', 3, 'list', sub {
  my ($tryable) = @_;
  my ($result) = $tryable->result;
  is $result, 'path';

  $result
});

=example-4 list

  # given: synopsis;

  $factory->list(['path', '/var/log'], ['path', '/tmp/log']);

  my @list = $factory->list;

  # (['path', '/var/log'], ['path', '/tmp/log'])

=cut

$test->for('example', 4, 'list', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [['path', '/var/log'], ['path', '/tmp/log']];

  @result
});

=method method

The method method modifies the current configuration and denotes that object
resolution should result from a method call using the method name provided.

=signature method

  method(string $name) (Venus::Factory)

=metadata method

{
  since => '4.15',
}

=example-1 method

  # given: synopsis;

  my $method = $factory->method;

  # undef

=cut

$test->for('example', 1, 'method', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 method

  # given: synopsis;

  my $method = $factory->method('do_something');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'method', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 method

  # given: synopsis;

  $factory->method('do_something');

  my $method = $factory->method;

  # "do_something"

=cut

$test->for('example', 3, 'method', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'do_something';

  $result
});

=method new

The new method returns a L<Venus::Factory> object.

=signature new

  new(hashref $data) (Venus::Factory)

=metadata new

{
  since => '4.15',
}

=example-1 new

  package main;

  use Venus::Factory;

  my $factory = Venus::Factory->new;

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=method package

The package method modifies the current configuration and denotes that object
resolution should be derived from the package name provided.

=signature package

  package(string $name) (Venus::Factory)

=metadata package

{
  since => '4.15',
}

=example-1 package

  # given: synopsis;

  my $package = $factory->package;

  # undef

=cut

$test->for('example', 1, 'package', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 package

  # given: synopsis;

  my $package = $factory->package('Example');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'package', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 package

  # given: synopsis;

  $factory->package('Example');

  my $package = $factory->package;

  # "Example"

=cut

$test->for('example', 3, 'package', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Example';

  $result
});

=method protocol

The protocol method modifies the current configuration and denotes the
subroutine dispatch protocol that should be used upon resolution.

=signature protocol

  protocol(string $name) (Venus::Factory)

=metadata protocol

{
  since => '4.15',
}

=example-1 protocol

  # given: synopsis;

  my $protocol = $factory->protocol;

  # undef

=cut

$test->for('example', 1, 'protocol', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 protocol

  # given: synopsis;

  my $protocol = $factory->protocol('method');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'protocol', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 protocol

  # given: synopsis;

  $factory->protocol('method');

  my $protocol = $factory->protocol;

  # "method"

=cut

$test->for('example', 3, 'protocol', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'method';

  $result
});

=method register

The register method registers and returns a new container (dependency
resolver).

=signature register

  register(string $name) (Venus::Factory)

=metadata register

{
  since => '4.15',
}

=example-1 register

  # given: synopsis;

  my $register = $factory->register('path');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 1, 'register', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok keys %{$result->registry} == 1;
  ok !$result->{assert};
  ok !$result->{dispatch};
  ok !$result->{package};
  ok !$result->{protocol};
  my $path = $result->registry->{path};
  ok $path->isa('Venus::Factory');
  ok !$path->{assert};
  ok !$path->{dispatch};
  ok !$path->{package};
  ok !$path->{protocol};

  $result
});

=method registry

The registry method returns a hashref representing all registered containers.

=signature registry

  registry(hashref $store) (hashref)

=metadata registry

{
  since => '4.15',
}

=example-1 registry

  # given: synopsis;

  my $registry = $factory->registry;

  # undef

=cut

$test->for('example', 1, 'registry', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 registry

  # given: synopsis;

  my $registry = $factory->registry({});

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'registry', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 registry

  # given: synopsis;

  $factory->registry({});

  my $registry = $factory->registry;

  # {}

=cut

$test->for('example', 3, 'registry', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=method reset

The reset method resets a property of the current configuration based on the
name provided. If no name is provided this method will reset all properties. If
a property name is provided this method returned the value of the reset
property. If no property name is provided this method returns the invocant.

=signature reset

  reset(string $name) (any)

=metadata reset

{
  since => '4.15',
}

=cut

=example-1 reset

  # given: synopsis

  package main;

  my $reset = $factory->reset;

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 1, 'reset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok !exists $result->{arrayref};
  ok !exists $result->{assert};
  ok !exists $result->{builder};
  ok !exists $result->{cached};
  ok !exists $result->{chain};
  ok !exists $result->{constructor};
  ok !exists $result->{dispatch};
  ok !exists $result->{hashref};
  ok !exists $result->{list};
  ok !exists $result->{name};
  ok !exists $result->{package};
  ok !exists $result->{protocol};
  ok !exists $result->{value};

  $result
});

=example-2 reset

  # given: synopsis

  package main;

  $factory->class('Venus::Path')->name('path');

  my $reset = $factory->reset;

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'reset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok !exists $result->{arrayref};
  ok !exists $result->{assert};
  ok !exists $result->{builder};
  ok !exists $result->{cached};
  ok !exists $result->{chain};
  ok !exists $result->{constructor};
  ok !exists $result->{dispatch};
  ok !exists $result->{hashref};
  ok !exists $result->{list};
  ok !exists $result->{name};
  ok !exists $result->{package};
  ok !exists $result->{protocol};
  ok !exists $result->{value};

  $result
});

=example-3 reset

  # given: synopsis

  package main;

  $factory->class('Venus::Path')->name('path');

  my $reset = $factory->reset('assert');

  # "Venus::Path"

=cut

$test->for('example', 3, 'reset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Venus::Path';

  $result
});

=example-4 reset

  # given: synopsis

  package main;

  $factory->name('path');

  $factory->class('Venus::Path');

  # my $reset = $factory->reset('package');

  # "Venus::Path"

=cut

$test->for('example', 4, 'reset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok !exists $result->{arrayref};
  ok !exists $result->{builder};
  ok !exists $result->{cached};
  ok !exists $result->{chain};
  ok !exists $result->{constructor};
  ok !exists $result->{hashref};
  ok !exists $result->{list};
  ok !exists $result->{value};
  ok exists $result->{assert};
  ok $result->reset('assert');
  ok !exists $result->{assert};
  ok exists $result->{dispatch};
  ok $result->reset('dispatch');
  ok !exists $result->{dispatch};
  ok exists $result->{name};
  ok $result->reset('name');
  ok !exists $result->{name};
  ok exists $result->{package};
  ok $result->reset('package');
  ok !exists $result->{package};
  ok exists $result->{protocol};
  ok $result->reset('protocol');
  ok !exists $result->{protocol};

  $result
});

=method resolve

The resolve method resolves the current configuration and returns the
constructed object based on the configuration. Any arguments provided (or
registered L<"values"|/value>) are merged with any registered L</arrayref>,
L</hashref>, or L</list> values.

=signature resolve

  resolve(any @args) (any)

=metadata resolve

{
  since => '4.15',
}

=example-1 resolve

  # given: synopsis;

  $factory->class('Venus::Path');

  my $resolve = $factory->resolve;

  # bless(..., "Venus::Path")

=cut

$test->for('example', 1, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Path');

  $result
});

=example-2 resolve

  # given: synopsis;

  $factory->class('Venus::Path');

  my $resolve = $factory->resolve('.');

  # bless(..., "Venus::Path")

=cut

$test->for('example', 2, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Path');
  is $result->value, '.';

  $result
});

=example-3 resolve

  # given: synopsis;

  my $resolve = $factory->register('path')->class('Venus::Path')->resolve('.');

  # bless(..., "Venus::Path")

=cut

$test->for('example', 3, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Path');
  is $result->value, '.';

  $result
});

=example-4 resolve

  # given: synopsis;

  $factory->class('Venus::Log');

  my $resolve = $factory->resolve;

  # bless(..., "Venus::Log")

=cut

$test->for('example', 4, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Log');

  $result
});

=example-5 resolve

  # given: synopsis;

  $factory->register('log')->class('Venus::Log');

  my $resolve = $factory->resolve;

  # undef

=cut

$test->for('example', 5, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-6 resolve

  # given: synopsis;

  my $resolve = $factory->register('date')->class('Venus::Date')->value(570672000)->resolve;

  # bless(..., "Venus::Date")

=cut

$test->for('example', 6, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Date');
  is $result->mdy, '02-01-1988';

  $result
});

=example-7 resolve

  # given: synopsis;

  my $resolve = $factory->register('date')
    ->class('Venus::Date')->value({year => 1988, month => 2, day => 1})->resolve;

  # bless(..., "Venus::Date")

=cut

$test->for('example', 7, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Date');
  is $result->mdy, '02-01-1988';

  $result
});

=example-8 resolve

  # given: synopsis;

  my $resolve = $factory->register('date')
    ->class('Venus::Date')->value(year => 1988, month => 2, day => 1)->resolve;

  # bless(..., "Venus::Date")

=cut

$test->for('example', 8, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Date');
  is $result->mdy, '02-01-1988';

  $result
});

=example-9 resolve

  # given: synopsis;

  my $resolve = $factory->register('date')
    ->class('Venus::Date')->builder(sub{$_->mdy})->value(570672000)
    ->assert('string')
    ->resolve;

  # "02-01-1988"

=cut

$test->for('example', 9, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, '02-01-1988';

  $result
});

=example-10 resolve

  # given: synopsis;

  my $resolve = $factory->register('greeting')
    ->class('Venus::String')->builder(sub{$_->titlecase})
    ->assert('string')
    ->resolve('hello world');

  # "Hello World"

=cut

$test->for('example', 10, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello World';

  $result
});

=example-11 resolve

  # given: synopsis;

  $factory->register('string')->class('Venus::String')->assert('string');

  my $string = $factory->retrieve('string');

  $string->builder(sub{
    my ($factory, $object) = @_;
    return $object->titlecase;
  });

  my $resolve = $string->resolve('hello world');

  # "Hello World"

=cut

$test->for('example', 11, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello World';

  $result
});

=example-12 resolve

  # given: synopsis;

  my $resolve = $factory->register('md5')->package('Digest::MD5')->function('md5_hex')->resolve;

  # "d41d8cd98f00b204e9800998ecf8427e"

=cut

$test->for('example', 12, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'd41d8cd98f00b204e9800998ecf8427e';

  $result
});

=example-13 resolve

  # given: synopsis;

  my $resolve = $factory->register('md5')->package('Digest::MD5')->function('md5_hex')->resolve('hello');

  # "5d41402abc4b2a76b9719d911017c592"

=cut

$test->for('example', 13, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, '5d41402abc4b2a76b9719d911017c592';

  $result
});

=example-14 resolve

  # given: synopsis;

  $factory->cache({});

  my $secret = $factory->register('secret')->cached(true)->package('Digest::MD5')->function('md5_hex');

  # $secret->resolve(rand);

  # "fa95053a9a204800ced194ffa3fc84bc"

  # $secret->resolve(rand);

  # "fa95053a9a204800ced194ffa3fc84bc"

=cut

$test->for('example', 14, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  my $value = $result->resolve(rand);
  is $result->resolve(rand), $value;
  is $result->resolve(rand), $value;
  is $result->resolve(rand), $value;

  $result
});

=example-15 resolve

  # given: synopsis;

  my $error = $factory->register('error')->class('Venus::Error');

  $error->constructor(sub{
    my ($factory, $package, $method, @args) = @_;
    return $package->$method(@args)->do('name', 'on.factory.build');
  });

  $error->resolve;

  # bless(..., "Venus::Error")

=cut

$test->for('example', 15, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->name, 'on.factory.build';

  $result
});

=example-16 resolve

  # given: synopsis;

  my $resolve = $factory->register('data.home')->value('/root')->resolve;

  # "/root"

=cut

$test->for('example', 16, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, '/root';

  $result
});

=example-17 resolve

  # given: synopsis;

  my $resolve = $factory
    ->register('data.home')->value('/root')
    ->register('path.home')->class('Venus::Path')->list('data.home')
    ->resolve;

  # bless(..., "Venus::Path")

=cut

$test->for('example', 17, 'resolve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Path');
  is $result->value, '/root';

  $result
});

=method retrieve

The retrieve method returns a registered container (dependency resolver) using
the name provided. If no argument is provided the invocant is returned.

=signature retrieve

  retrieve(string $name) (Venus::Factory)

=metadata retrieve

{
  since => '4.15',
}

=example-1 retrieve

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $retrieve = $factory->retrieve;

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 1, 'retrieve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  ok !$result->{assert};
  ok !$result->{dispatch};
  ok !$result->{package};
  ok !$result->{protocol};

  $result
});

=example-2 retrieve

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $retrieve = $factory->retrieve('path');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'retrieve', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  is $result->{assert}, 'Venus::Path';
  is $result->{dispatch}, 'new';
  is $result->{package}, 'Venus::Path';
  is $result->{protocol}, 'method';

  $result
});

=method routine

The routine method modifies the current configuration and denotes that object
resolution should result from a routine call (or package call) using the
subroutine name provided.

=signature routine

  routine(string $name) (Venus::Factory)

=metadata routine

{
  since => '4.15',
}

=example-1 routine

  # given: synopsis;

  my $routine = $factory->routine;

  # undef

=cut

$test->for('example', 1, 'routine', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 routine

  # given: synopsis;

  my $routine = $factory->routine('do_something');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'routine', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 routine

  # given: synopsis;

  $factory->routine('do_something');

  my $routine = $factory->routine;

  # "do_something"

=cut

$test->for('example', 3, 'routine', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'do_something';

  $result
});

=method value

The value method method modifies the current configuration and registers
value(s) to be provided to the L</method>, L</function>, or L</routine> upon
resolution.

=signature value

  value(any @data) (any)

=metadata value

{
  since => '4.15',
}

=example-1 value

  # given: synopsis;

  my $value = $factory->value;

  # undef

=cut

$test->for('example', 1, 'value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 value

  # given: synopsis;

  my $value = $factory->value('hello world');

  # bless(..., "Venus::Factory")

=cut

$test->for('example', 2, 'value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');

  $result
});

=example-3 value

  # given: synopsis;

  $factory->value('hello world');

  my @value = $factory->value;

  # ("hello world")

=cut

$test->for('example', 3, 'value', sub {
  my ($tryable) = @_;
  my ($result) = $tryable->result;
  is $result, 'hello world';

  $result
});

=example-4 value

  # given: synopsis;

  $factory->value({value => 'hello world'});

  my @value = $factory->value;

  # ({value => 'hello world'})

=cut

$test->for('example', 4, 'value', sub {
  my ($tryable) = @_;
  my ($result) = $tryable->result;
  is_deeply $result, {value => 'hello world'};

  $result
});

=example-5 value

  # given: synopsis;

  $factory->value(1..4);

  my @value = $factory->value;

  # (1..4)

=cut

$test->for('example', 5, 'value', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [1..4];

  @result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Factory.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
