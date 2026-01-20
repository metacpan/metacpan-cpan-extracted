package Venus::Factory;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Buildable';
with 'Venus::Role::Encaseable';
with 'Venus::Role::Tryable';
with 'Venus::Role::Catchable';
with 'Venus::Role::Throwable';

# ATTRIBUTES

attr 'name';

# METHODS

sub args {
  my ($self, @args) = @_;

  my @value = $self->value;

  @value = @args if @args;

  my @list = $self->list;

  for my $item (reverse @list) {
    my ($name, @args) = ref $item ? @{$item} : $item;
    my $container = $self->retrieve($name);
    unshift @value, $container->resolve(@args) if $container;
  }

  return @value if @value > 1;

  my $arrayref = $self->arrayref;

  if ($arrayref && (!@value || (@value == 1 && ref $value[0] eq 'ARRAY'))) {
    for my $item (reverse @{$arrayref}) {
      my ($name, @args) = ref $item ? @{$item} : $item;
      my $container = $self->retrieve($name);
      unshift @{$value[0]}, $container->resolve(@args) if $container;
    }
  }

  my $hashref = $self->hashref;

  if ($hashref && (!@value || (@value == 1 && ref $value[0] eq 'HASH'))) {
    for my $pair (map +([$_, $$hashref{$_}]), keys %{$hashref}) {
      my ($name, @args) = ref $$pair[1] ? @{$$pair[1]} : $$pair[1];
      my $container = $self->retrieve($name);
      ${$value[0]}{$$pair[0]} = $container->resolve(@args) if $container && !exists ${$value[0]}{$$pair[0]};
    }
  }

  return wantarray ? (@value) : $value[0];
}

sub arrayref {
  my ($self, @data) = @_;

  if (@data) {
    $self->{arrayref} = [@data];

    return $self;
  }
  else {

    return $self->{arrayref};
  }
}

sub assert {
  my ($self, @data) = @_;

  if (@data) {
    $self->{assert} = $data[0];

    return $self;
  }
  else {

    return $self->{assert};
  }
}

sub attach {
  my ($self, $name, $data) = @_;

  my $class = ref $self;

  return $self if !$data || !UNIVERSAL::isa($data, $class);

  my $registry = $self->registry || $self->registry({})->registry;

  my $container = $registry->{$name} = $data;

  $container->registry($registry);

  $container->name($name) if !$container->name;

  $container->cache($self->cache) if $self->cache;

  return $container;
}

sub build {
  my ($self, $name, @args) = @_;

  my $container = $self->retrieve($name);

  return $container->resolve(@args);
}

sub builder {
  my ($self, @data) = @_;

  if (@data) {
    $self->{builder} = $data[0];

    return $self;
  }
  else {

    return $self->{builder};
  }
}

sub cache {
  my ($self, @data) = @_;

  if (@data) {
    $self->recase('cache', $data[0]);

    return $self;
  }
  else {

    return $self->encased('cache');
  }
}

sub cached {
  my ($self, @data) = @_;

  if (@data) {
    $self->{cached} = $data[0] ? true : false;

    return $self;
  }
  else {

    return $self->{cached};
  }
}

sub callback {
  my ($self, @args) = @_;

  return $self->defer('resolve', @args);
}

sub chain {
  my ($self, @data) = @_;

  if (@data) {
    $self->{chain} = [@data];

    return $self;
  }
  else {

    return $self->{chain};
  }
}

sub class {
  my ($self, @data) = @_;

  if (@data) {
    $self->assert($data[0])->package($data[0])->method('new');

    return $self;
  }
  else {

    return ($self->protocol
        && $self->protocol eq 'method'
        && $self->dispatch
        && $self->dispatch eq 'new') ? $self->package : undef;
  }
}

sub clone {
  my ($self) = @_;

  require Venus;

  my $class = ref $self;

  my $container = $class->new;

  my $arrayref = $self->arrayref;

  $container->arrayref(Venus::clone($arrayref)) if defined $arrayref;

  my $assert = $self->assert;

  $container->assert($assert) if defined $assert;

  my $builder = $self->builder;

  $container->builder($builder) if defined $builder;

  my $cached = $self->cached;

  $container->cached($cached) if defined $cached;

  my $chain = $self->chain;

  $container->chain(Venus::clone($chain)) if defined $chain;

  my $constructor = $self->constructor;

  $container->constructor($constructor) if defined $constructor;

  my $dispatch = $self->dispatch;

  $container->dispatch($dispatch) if defined $dispatch;

  my $hashref = $self->hashref;

  $container->hashref(Venus::clone($hashref)) if defined $hashref;

  my @list = $self->list;

  $container->list(map ref $_ ? Venus::clone($_) : $_, @list) if @list;

  my $name = $self->name;

  $container->name($name) if defined $name;

  my $package = $self->package;

  $container->package($package) if defined $package;

  my $protocol = $self->protocol;

  $container->protocol($protocol) if defined $protocol;

  my @value = $self->value;

  $container->value(map ref $_ ? Venus::clone($_) : $_, @value) if @value;

  return $container;
}

sub constructor {
  my ($self, @data) = @_;

  if (@data) {
    $self->{constructor} = $data[0];

    return $self;
  }
  else {

    return $self->{constructor};
  }
}

sub detach {
  my ($self, $name) = @_;

  my $registry = $self->registry || $self->registry({})->registry;

  my $container = delete $registry->{$name};

  return undef if !$container;

  return $container;
}

sub dispatch {
  my ($self, @data) = @_;

  if (@data) {
    $self->{dispatch} = $data[0];

    return $self;
  }
  else {

    return $self->{dispatch};
  }
}

sub dispatch_to_function {
  my ($self, $invocant, $function, @args) = @_;

  no strict 'refs';

  return &{"${invocant}::${function}"}(@args);
}

sub dispatch_to_method {
  my ($self, $invocant, $method, @args) = @_;

  return $invocant->$method(@args);
}

sub dispatch_to_routine {
  my ($self, $invocant, $routine, @args) = @_;

  return (ref $invocant || $invocant)->$routine(@args);
}

sub extend {
  my ($self, $name) = @_;

  require Venus;

  my $container = $self->retrieve($name);

  return $self if !$container;

  my $arrayref = $container->arrayref;

  $self->arrayref(Venus::clone($arrayref)) if defined $arrayref;

  my $assert = $container->assert;

  $self->assert($assert) if defined $assert;

  my $builder = $container->builder;

  $self->builder($builder) if defined $builder;

  my $cached = $container->cached;

  $self->cached($cached) if defined $cached;

  my $chain = $container->chain;

  $self->chain(Venus::clone($chain)) if defined $chain;

  my $constructor = $container->constructor;

  $self->constructor($constructor) if defined $constructor;

  my $dispatch = $container->dispatch;

  $self->dispatch($dispatch) if defined $dispatch;

  my $hashref = $container->hashref;

  $self->hashref(Venus::clone($hashref)) if defined $hashref;

  my @list = $container->list;

  $self->list(map ref $_ ? Venus::clone($_) : $_, @list) if @list;

  my $package = $container->package;

  $self->package($package) if defined $package;

  my $protocol = $container->protocol;

  $self->protocol($protocol) if defined $protocol;

  my @value = $container->value;

  $self->value(map ref $_ ? Venus::clone($_) : $_, @value) if @value;

  return $self;
}

sub function {
  my ($self, @data) = @_;

  if (@data) {
    $self->protocol('function')->dispatch($data[0]);

    return $self;
  }
  else {

    return ($self->protocol && $self->protocol eq 'function') ? $self->dispatch : undef;
  }
}

sub hashref {
  my ($self, @data) = @_;

  if (@data) {
    $self->{hashref} = $data[0];

    return $self;
  }
  else {

    return $self->{hashref};
  }
}

sub list {
  my ($self, @data) = @_;

  if (@data) {
    $self->{list} = [@data];

    return $self;
  }
  else {

    return $self->{list} ? @{$self->{list}} : ();
  }
}

sub method {
  my ($self, @data) = @_;

  if (@data) {
    $self->protocol('method')->dispatch($data[0]);

    return $self;
  }
  else {

    return ($self->protocol && $self->protocol eq 'method') ? $self->dispatch : undef;
  }
}

sub package {
  my ($self, @data) = @_;

  if (@data) {
    $self->{package} = $data[0];

    return $self;
  }
  else {

    return $self->{package};
  }
}

sub protocol {
  my ($self, @data) = @_;

  if (@data) {
    $self->{protocol} = $data[0];

    return $self;
  }
  else {

    return $self->{protocol};
  }
}

sub register {
  my ($self, $name) = @_;

  my $class = ref $self;

  my $registry = $self->registry || $self->registry({})->registry;

  my $container = $registry->{$name} = $class->new(name => $name);

  $container->registry($registry);

  $container->cache($self->cache) if $self->cache;

  return $container;
}

sub registry {
  my ($self, @data) = @_;

  if (@data) {
    $self->recase('registry', $data[0]);

    return $self;
  }
  else {

    return $self->encased('registry');
  }
}

sub reset {
  my ($self, @data) = @_;

  if (@data) {
    my $value = delete $self->{$data[0]};

    return $value;
  }
  else {

    delete $self->{arrayref};
    delete $self->{assert};
    delete $self->{builder};
    delete $self->{cached};
    delete $self->{callback};
    delete $self->{chain};
    delete $self->{constructor};
    delete $self->{dispatch};
    delete $self->{hashref};
    delete $self->{list};
    delete $self->{name};
    delete $self->{package};
    delete $self->{protocol};
    delete $self->{value};

    return $self;
  }
}

sub resolve {
  my ($self, @args) = @_;

  my ($cache, $cached) = ($self->cache, $self->cached);

  return $cache->{$self->name} if $cache && $cached && $self->name;

  require Venus::Space;

  my $package = $self->package;

  return (scalar $self->value) ? (wantarray ? ($self->value) : ($self->value)[0]) : () if !$package;

  Venus::Space->new($package)->tryload;

  my $protocol = $self->protocol;

  my $dispatch = $self->dispatch;

  my @result;

  if ($protocol eq 'function') {
    my $constructor = $self->constructor;

    if ($constructor) {
      @result = $self->$constructor($package, $dispatch, $self->args(@args));
    }
    else {
      @result = $self->dispatch_to_function($package, $dispatch, $self->args(@args));
    }

    my $chain = $self->chain;

    if ($chain) {
      for my $item (@{$chain}) {
        my ($name, @args) = ref $item ? @{$item} : $item;
        @result = $self->dispatch_to_function($package, $name, @result ? @result : @args);
      }
    }
  }

  if ($protocol eq 'method') {
    my $constructor = $self->constructor;

    if ($constructor) {
      @result = (scalar $self->$constructor($package, $dispatch, $self->args(@args)));
    }
    else {
      @result = (scalar $self->dispatch_to_method($package, $dispatch, $self->args(@args)));
    }

    my $chain = $self->chain;

    if ($chain) {
      for my $item (@{$chain}) {
        my ($name, @args) = ref $item ? @{$item} : $item;
        @result = (scalar $result[0]->$name(@args));
      }
    }
  }

  if ($protocol eq 'routine') {
    my $constructor = $self->constructor;

    if ($constructor) {
      @result = (scalar $self->$constructor($package, $dispatch, $self->args(@args)));
    }
    else {
      @result = (scalar $self->dispatch_to_method($package, $dispatch, $self->args(@args)));
    }

    my $chain = $self->chain;

    if ($chain) {
      for my $item (@{$chain}) {
        my ($name, @args) = ref $item ? @{$item} : $item;
        @result = (scalar $result[0]->$name(@args));
      }
    }
  }

  my $builder = $self->builder;

  local $_ = $result[0];

  @result = ($self->$builder(@result)) if $builder;

  if (@result == 1) {
    my $assert = $self->assert;

    if ($assert) {
      require Venus::Assert;

      Venus::Assert->new($assert)->accept($assert)->result($result[0]);
    }

    $cache->{$self->name} = $result[0] if $cache && $cached && $self->name
  }

  return wantarray ? (@result) : $result[0];
}

sub retrieve {
  my ($self, $name) = @_;

  return $self if !$name;

  my $class = ref $self;

  my $registry = $self->registry || $self->registry({})->registry;

  my $container = $registry->{$name};

  return $container;
}

sub routine {
  my ($self, @data) = @_;

  if (@data) {
    $self->protocol('routine')->dispatch($data[0]);

    return $self;
  }
  else {

    return ($self->protocol && $self->protocol eq 'routine') ? $self->dispatch : undef;
  }
}

sub value {
  my ($self, @data) = @_;

  if (@data) {
    $self->{value} = [@data];

    return $self;
  }
  else {

    return $self->{value} ? @{$self->{value}} : ();
  }
}

1;



=head1 NAME

Venus::Factory - Factory Class

=cut

=head1 ABSTRACT

Factory Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Factory;

  my $factory = Venus::Factory->new;

  # $factory->class('Venus::Path');

  # $factory->build;

  # bless(.., "Venus::Path")

=cut

=head1 DESCRIPTION

This package provides an object-oriented factory pattern and mechanism for
building objects using dependency injection.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 name

  name(string $name) (string)

The name attribute is read/write, accepts C<(string)> values, is optional, and
defaults to C<undef>.

I<Since C<4.15>>

=over 4

=item name example 1

  # given: synopsis;

  my $name = $factory->name('log');

  # "log"

=back

=over 4

=item name example 2

  # given: synopsis;

  # given: example-1 name

  $name = $factory->name;

  # "log"

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

L<Venus::Role::Encaseable>

L<Venus::Role::Tryable>

L<Venus::Role::Catchable>

L<Venus::Role::Throwable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 args

  args(any @args) (Any)

The args method accepts arguments and merges them with any L</arrayref>,
L</hashref>, or L</list> registered in the current configuration and returns
the result. Returns a list in list context.

=over 4

=item * If an L</arrayref> exists and the argment is an arrayref, the values are
merged by appending the arguments provided to the end of the registered arrayref.

=item * If a L</hashref> exists and the argment is a hashref, the values are
merged without overriding the keys and values from the registered hashref.

=item * If a L</list> exists and the argment is a list of values, the values are
merged by appending the arguments provided to the end of the registered list.

=back

I<Since C<4.15>>

=over 4

=item args example 1

  # given: synopsis

  package main;

  my @args = $factory->args;

  # ()

=back

=over 4

=item args example 2

  # given: synopsis

  package main;

  my $args = $factory->args;

  # undef

=back

=over 4

=item args example 3

  # given: synopsis

  package main;

  my $args = $factory->args({path => '/root'});

  # {path => "/root"}

=back

=over 4

=item args example 4

  # given: synopsis

  package main;

  $factory->value({path => '/boot'});

  my $args = $factory->args({path => '/root'});

  # {path => "/root"}

=back

=over 4

=item args example 5

  # given: synopsis

  package main;

  $factory->value({path => '/boot'});

  my $args = $factory->args;

  # {path => "/boot"}

=back

=over 4

=item args example 6

  # given: synopsis

  package main;

  $factory->value(name => 'example');

  my @args = $factory->args;

  # ('name', 'example')

=back

=over 4

=item args example 7

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->list('data.home', 'data.root');

  my @args = $factory->args;

  # ('/home', '/root')

=back

=over 4

=item args example 8

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->list('data.home', 'data.root');

  my @args = $factory->args('/boot');

  # ('/home', '/root', '/boot')

=back

=over 4

=item args example 9

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->arrayref('data.home', 'data.root');

  my $args = $factory->args;

  # ['/home', '/root']

=back

=over 4

=item args example 10

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->arrayref('data.home', 'data.root');

  my $args = $factory->args(['/boot']);

  # ['/home', '/root', '/boot']

=back

=over 4

=item args example 11

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->hashref({home => 'data.home', root => 'data.root'});

  my $args = $factory->args;

  # {home => '/home', root => '/root'}

=back

=over 4

=item args example 12

  # given: synopsis

  package main;

  $factory->register('data.home')->value('/home');

  $factory->register('data.root')->value('/root');

  $factory->hashref({home => 'data.home', root => 'data.root'});

  my $args = $factory->args({boot => '/boot'});

  # {home => '/home', root => '/root', boot => '/boot'}

=back

=cut

=head2 arrayref

  arrayref(arrayref $data) (arrayref)

The arrayref method modifies the current configuration and registers an
arrayref where each value is a string or arrayref representing arguments to be
passed to L</build>, each value is resolved and the resulting arrayref merged
with the L</value> upon resolution.

I<Since C<4.15>>

=over 4

=item arrayref example 1

  # given: synopsis;

  my $arrayref = $factory->arrayref;

  # undef

=back

=over 4

=item arrayref example 2

  # given: synopsis;

  my $arrayref = $factory->arrayref('path');

  # bless(..., "Venus::Factory")

=back

=over 4

=item arrayref example 3

  # given: synopsis;

  $factory->arrayref('path');

  my $arrayref = $factory->arrayref;

  # ['path']

=back

=over 4

=item arrayref example 4

  # given: synopsis;

  my $arrayref = $factory->arrayref(['path', '/var/log'], ['path', '/tmp/log']);

  # bless(..., "Venus::Factory")

=back

=cut

=head2 assert

  assert(string $expr) (Venus::Factory)

The assert method modifies the current configuration and registers a type
expression to be used to validate the resulting object upon resolution.

I<Since C<4.15>>

=over 4

=item assert example 1

  # given: synopsis;

  my $assert = $factory->assert;

  # undef

=back

=over 4

=item assert example 2

  # given: synopsis;

  my $assert = $factory->assert('Example');

  # bless(..., "Venus::Factory")

=back

=over 4

=item assert example 3

  # given: synopsis;

  $factory->assert('Example');

  my $assert = $factory->assert;

  # "Example"

=back

=cut

=head2 attach

  attach(string $name, Venus::Factory $data) (Venus::Factory)

The attach method adds an existing L<"detached"|/detach> container to the
registry and returns container.

I<Since C<4.15>>

=over 4

=item attach example 1

  # given: synopsis

  package main;

  my $attach = $factory->attach;

  # bless(..., "Venus::Factory")

=back

=over 4

=item attach example 2

  # given: synopsis

  package main;

  my $attach = $factory->attach('path', Venus::Factory->new->class('Venus::Path'));

  # bless(..., "Venus::Factory")

=back

=cut

=head2 builder

  builder(coderef $callback) (coderef)

The builder method modifies the current configuration and registers a callback
invoked during resolution which the resolved object is passed through. The
return value of the callback will be returned by L</resolve>.

I<Since C<4.15>>

=over 4

=item builder example 1

  # given: synopsis;

  my $builder = $factory->builder;

  # undef

=back

=over 4

=item builder example 2

  # given: synopsis;

  my $builder = $factory->builder(sub{});

  # bless(..., "Venus::Factory")

=back

=over 4

=item builder example 3

  # given: synopsis;

  $factory->builder(sub{});

  my $builder = $factory->builder;

  # sub{}

=back

=cut

=head2 cache

  cache(hashref $cache) (hashref)

The cache method gets and sets a store to be used by all derived containers
where objects will be cached upon resolution.

I<Since C<4.15>>

=over 4

=item cache example 1

  # given: synopsis;

  my $cache = $factory->cache;

  # undef

=back

=over 4

=item cache example 2

  # given: synopsis;

  my $cache = $factory->cache({});

  # bless(..., "Venus::Factory")

=back

=over 4

=item cache example 3

  # given: synopsis;

  $factory->cache(sub{});

  my $cache = $factory->cache;

  # sub{}

=back

=cut

=head2 cached

  cached(boolean $bool) (Venus::Factory)

The cached method modifies the current configuration and denotes that the
object should be cached upon resolution.

I<Since C<4.15>>

=over 4

=item cached example 1

  # given: synopsis;

  my $cached = $factory->cached;

  # undef

=back

=over 4

=item cached example 2

  # given: synopsis;

  my $cached = $factory->cached(true);

  # bless(..., "Venus::Factory")

=back

=over 4

=item cached example 3

  # given: synopsis;

  $factory->cached(true);

  my $cached = $factory->cached;

  # true

=back

=cut

=head2 callback

  callback(any @args) (Venus::Factory)

The callback method modifies the current configuration and denotes that a
coderef containing the resolved object should be returned upon resolution.

I<Since C<4.15>>

=over 4

=item callback example 1

  # given: synopsis;

  my $callback = $factory->callback;

  # sub{...}

=back

=over 4

=item callback example 2

  # given: synopsis;

  $factory->class('Venus::Path');

  my $callback = $factory->callback('.');

  # sub{...}

=back

=cut

=head2 chain

  chain(string | within[arrayref, string] @chain) (Venus::Factory)

The chain method method modifies the current configuration and registers a
string or arrayref representing subsequent method calls to be chained upon
resolution.

I<Since C<4.15>>

=over 4

=item chain example 1

  # given: synopsis;

  my $chain = $factory->chain;

  # undef

=back

=over 4

=item chain example 2

  # given: synopsis;

  my $chain = $factory->chain('step_1');

  # bless(..., "Venus::Factory")

=back

=over 4

=item chain example 3

  # given: synopsis;

  $factory->chain('step_1');

  my $chain = $factory->chain;

  # ["step_1"]

=back

=over 4

=item chain example 4

  # given: synopsis;

  $factory->chain('step_1', 'step_2');

  my $chain = $factory->chain;

  # ["step_1", "step_2"]

=back

=over 4

=item chain example 5

  # given: synopsis;

  $factory->chain('step_1', 'step_2', ['step_3', 1..4]);

  my $chain = $factory->chain;

  # ["step_1", "step_2", ["step_3", 1..4]]

=back

=cut

=head2 class

  class(string $class) (Venus::Factory)

The class method is shorthand for calling L</package>, L</assert>, and L</method> with the
argument C<"new">.

I<Since C<4.15>>

=over 4

=item class example 1

  # given: synopsis;

  my $class = $factory->class;

  # undef

=back

=over 4

=item class example 2

  # given: synopsis;

  my $class = $factory->class('Venus::Path');

  # bless(..., "Venus::Factory")

=back

=over 4

=item class example 3

  # given: synopsis;

  $factory->class('Venus::Path');

  my $class = $factory->class;

  # "Venus::Path"

=back

=cut

=head2 clone

  clone() (Venus::Factory)

The clone method clones the current configuration and returns a container not
attached to the registry.

I<Since C<4.15>>

=over 4

=item clone example 1

  # given: synopsis

  package main;

  my $clone = $factory->clone;

  # bless(..., "Venus::Factory")

=back

=over 4

=item clone example 2

  # given: synopsis

  package main;

  $factory->class('Venus::Path')->name('path');

  my $clone = $factory->clone;

  # bless(..., "Venus::Factory")

=back

=over 4

=item clone example 3

  # given: synopsis

  package main;

  $factory->class('Venus::Path')->builder(sub{$_->absolute})->name('path');

  my $clone = $factory->clone;

  # bless(..., "Venus::Factory")

=back

=cut

=head2 constructor

  constructor(any @data) (defined)

The constructor method modifies the current configuration and registers a
callback invoked during resolution which is passed the package, if any, and the
resolved dependencies (and/or arguments), if any. The return value of the
callback will be considered the resolved object.

I<Since C<4.15>>

=over 4

=item constructor example 1

  # given: synopsis;

  my $constructor = $factory->constructor;

  # undef

=back

=over 4

=item constructor example 2

  # given: synopsis;

  my $constructor = $factory->constructor(sub{});

  # bless(..., "Venus::Factory")

=back

=over 4

=item constructor example 3

  # given: synopsis;

  $factory->constructor(sub{});

  my $constructor = $factory->constructor;

  # sub{}

=back

=cut

=head2 detach

  detach(string $name) (maybe[Venus::Factory])

The detach method removes an existing container from the registry and returns
container. The detached container will still have access to the registry to
resolve dependencies. To detach from the registry use L</reset>.

I<Since C<4.15>>

=over 4

=item detach example 1

  # given: synopsis

  package main;

  my $detach = $factory->detach('path');

  # undef

=back

=over 4

=item detach example 2

  # given: synopsis

  package main;

  $factory->register('path')->class('Venus::Path');

  my $detach = $factory->detach('path');

  # bless(..., "Venus::Factory")

=back

=cut

=head2 dispatch

  dispatch(string $name) (Venus::Factory)

The dispatch method modifies the current configuration and denotes the
subroutine that should be dispatched to upon resolution.

I<Since C<4.15>>

=over 4

=item dispatch example 1

  # given: synopsis;

  my $dispatch = $factory->dispatch;

  # undef

=back

=over 4

=item dispatch example 2

  # given: synopsis;

  my $dispatch = $factory->dispatch('do_something');

  # bless(..., "Venus::Factory")

=back

=over 4

=item dispatch example 3

  # given: synopsis;

  $factory->dispatch('do_something');

  my $dispatch = $factory->dispatch;

  # "do_something"

=back

=cut

=head2 extend

  extend(string $name) (Venus::Factory)

The extend method copies the details of the configuration specified to the
current configuration.

I<Since C<4.15>>

=over 4

=item extend example 1

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $extend = $factory->extend;

  # bless(..., "Venus::Factory")

=back

=over 4

=item extend example 2

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $extend = $factory->register('temp')->extend('path');

  # bless(..., "Venus::Factory")

=back

=cut

=head2 function

  function(string $name) (Venus::Factory)

The function method modifies the current configuration and denotes that object
resolution should result from a function call using the function name provided.

I<Since C<4.15>>

=over 4

=item function example 1

  # given: synopsis;

  my $function = $factory->function;

  # undef

=back

=over 4

=item function example 2

  # given: synopsis;

  my $function = $factory->function('do_something');

  # bless(..., "Venus::Factory")

=back

=over 4

=item function example 3

  # given: synopsis;

  $factory->function('do_something');

  my $function = $factory->function;

  # "do_something"

=back

=cut

=head2 hashref

  hashref(hashref $data) (hashref)

The hashref method modifies the current configuration and registers an hashref
where each value is a string or arrayref representing arguments to be passed to
L</build>, each value is resolved and the resulting hashref is merged with the
L</value> upon resolution.

I<Since C<4.15>>

=over 4

=item hashref example 1

  # given: synopsis;

  my $hashref = $factory->hashref;

  # undef

=back

=over 4

=item hashref example 2

  # given: synopsis;

  my $hashref = $factory->hashref({path => 'path'});

  # bless(..., "Venus::Factory")

=back

=over 4

=item hashref example 3

  # given: synopsis;

  $factory->hashref({path => 'path'});

  my $hashref = $factory->hashref;

  # {path => "path"}

=back

=over 4

=item hashref example 4

  # given: synopsis;

  $factory->hashref({
    tmplog => ['path', '/tmp/log'],
    varlog => ['path', '/var/log'],
  });

  my $hashref = $factory->hashref;

  # {tmplog => ["path", "/tmp/log"], varlog => ["path", "/var/log"]}

=back

=cut

=head2 list

  list(string | arrayref @data) (string | arrayref)

The list method modifies the current configuration and registers a sequence of
values where each value is a string or arrayref representing arguments to be
passed to L</build>, each value is resolved and the resulting list is merged
with the L</value> upon resolution.

I<Since C<4.15>>

=over 4

=item list example 1

  # given: synopsis;

  my $list = $factory->list;

  # undef

=back

=over 4

=item list example 2

  # given: synopsis;

  my $list = $factory->list('path');

  # bless(..., "Venus::Factory")

=back

=over 4

=item list example 3

  # given: synopsis;

  $factory->list('path');

  my @list = $factory->list;

  # ("path")

=back

=over 4

=item list example 4

  # given: synopsis;

  $factory->list(['path', '/var/log'], ['path', '/tmp/log']);

  my @list = $factory->list;

  # (['path', '/var/log'], ['path', '/tmp/log'])

=back

=cut

=head2 method

  method(string $name) (Venus::Factory)

The method method modifies the current configuration and denotes that object
resolution should result from a method call using the method name provided.

I<Since C<4.15>>

=over 4

=item method example 1

  # given: synopsis;

  my $method = $factory->method;

  # undef

=back

=over 4

=item method example 2

  # given: synopsis;

  my $method = $factory->method('do_something');

  # bless(..., "Venus::Factory")

=back

=over 4

=item method example 3

  # given: synopsis;

  $factory->method('do_something');

  my $method = $factory->method;

  # "do_something"

=back

=cut

=head2 new

  new(hashref $data) (Venus::Factory)

The new method returns a L<Venus::Factory> object.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Factory;

  my $factory = Venus::Factory->new;

  # bless(..., "Venus::Factory")

=back

=cut

=head2 package

  package(string $name) (Venus::Factory)

The package method modifies the current configuration and denotes that object
resolution should be derived from the package name provided.

I<Since C<4.15>>

=over 4

=item package example 1

  # given: synopsis;

  my $package = $factory->package;

  # undef

=back

=over 4

=item package example 2

  # given: synopsis;

  my $package = $factory->package('Example');

  # bless(..., "Venus::Factory")

=back

=over 4

=item package example 3

  # given: synopsis;

  $factory->package('Example');

  my $package = $factory->package;

  # "Example"

=back

=cut

=head2 protocol

  protocol(string $name) (Venus::Factory)

The protocol method modifies the current configuration and denotes the
subroutine dispatch protocol that should be used upon resolution.

I<Since C<4.15>>

=over 4

=item protocol example 1

  # given: synopsis;

  my $protocol = $factory->protocol;

  # undef

=back

=over 4

=item protocol example 2

  # given: synopsis;

  my $protocol = $factory->protocol('method');

  # bless(..., "Venus::Factory")

=back

=over 4

=item protocol example 3

  # given: synopsis;

  $factory->protocol('method');

  my $protocol = $factory->protocol;

  # "method"

=back

=cut

=head2 register

  register(string $name) (Venus::Factory)

The register method registers and returns a new container (dependency
resolver).

I<Since C<4.15>>

=over 4

=item register example 1

  # given: synopsis;

  my $register = $factory->register('path');

  # bless(..., "Venus::Factory")

=back

=cut

=head2 registry

  registry(hashref $store) (hashref)

The registry method returns a hashref representing all registered containers.

I<Since C<4.15>>

=over 4

=item registry example 1

  # given: synopsis;

  my $registry = $factory->registry;

  # undef

=back

=over 4

=item registry example 2

  # given: synopsis;

  my $registry = $factory->registry({});

  # bless(..., "Venus::Factory")

=back

=over 4

=item registry example 3

  # given: synopsis;

  $factory->registry({});

  my $registry = $factory->registry;

  # {}

=back

=cut

=head2 reset

  reset(string $name) (any)

The reset method resets a property of the current configuration based on the
name provided. If no name is provided this method will reset all properties. If
a property name is provided this method returned the value of the reset
property. If no property name is provided this method returns the invocant.

I<Since C<4.15>>

=over 4

=item reset example 1

  # given: synopsis

  package main;

  my $reset = $factory->reset;

  # bless(..., "Venus::Factory")

=back

=over 4

=item reset example 2

  # given: synopsis

  package main;

  $factory->class('Venus::Path')->name('path');

  my $reset = $factory->reset;

  # bless(..., "Venus::Factory")

=back

=over 4

=item reset example 3

  # given: synopsis

  package main;

  $factory->class('Venus::Path')->name('path');

  my $reset = $factory->reset('assert');

  # "Venus::Path"

=back

=over 4

=item reset example 4

  # given: synopsis

  package main;

  $factory->name('path');

  $factory->class('Venus::Path');

  # my $reset = $factory->reset('package');

  # "Venus::Path"

=back

=cut

=head2 resolve

  resolve(any @args) (any)

The resolve method resolves the current configuration and returns the
constructed object based on the configuration. Any arguments provided (or
registered L<"values"|/value>) are merged with any registered L</arrayref>,
L</hashref>, or L</list> values.

I<Since C<4.15>>

=over 4

=item resolve example 1

  # given: synopsis;

  $factory->class('Venus::Path');

  my $resolve = $factory->resolve;

  # bless(..., "Venus::Path")

=back

=over 4

=item resolve example 2

  # given: synopsis;

  $factory->class('Venus::Path');

  my $resolve = $factory->resolve('.');

  # bless(..., "Venus::Path")

=back

=over 4

=item resolve example 3

  # given: synopsis;

  my $resolve = $factory->register('path')->class('Venus::Path')->resolve('.');

  # bless(..., "Venus::Path")

=back

=over 4

=item resolve example 4

  # given: synopsis;

  $factory->class('Venus::Log');

  my $resolve = $factory->resolve;

  # bless(..., "Venus::Log")

=back

=over 4

=item resolve example 5

  # given: synopsis;

  $factory->register('log')->class('Venus::Log');

  my $resolve = $factory->resolve;

  # undef

=back

=over 4

=item resolve example 6

  # given: synopsis;

  my $resolve = $factory->register('date')->class('Venus::Date')->value(570672000)->resolve;

  # bless(..., "Venus::Date")

=back

=over 4

=item resolve example 7

  # given: synopsis;

  my $resolve = $factory->register('date')
    ->class('Venus::Date')->value({year => 1988, month => 2, day => 1})->resolve;

  # bless(..., "Venus::Date")

=back

=over 4

=item resolve example 8

  # given: synopsis;

  my $resolve = $factory->register('date')
    ->class('Venus::Date')->value(year => 1988, month => 2, day => 1)->resolve;

  # bless(..., "Venus::Date")

=back

=over 4

=item resolve example 9

  # given: synopsis;

  my $resolve = $factory->register('date')
    ->class('Venus::Date')->builder(sub{$_->mdy})->value(570672000)
    ->assert('string')
    ->resolve;

  # "02-01-1988"

=back

=over 4

=item resolve example 10

  # given: synopsis;

  my $resolve = $factory->register('greeting')
    ->class('Venus::String')->builder(sub{$_->titlecase})
    ->assert('string')
    ->resolve('hello world');

  # "Hello World"

=back

=over 4

=item resolve example 11

  # given: synopsis;

  $factory->register('string')->class('Venus::String')->assert('string');

  my $string = $factory->retrieve('string');

  $string->builder(sub{
    my ($factory, $object) = @_;
    return $object->titlecase;
  });

  my $resolve = $string->resolve('hello world');

  # "Hello World"

=back

=over 4

=item resolve example 12

  # given: synopsis;

  my $resolve = $factory->register('md5')->package('Digest::MD5')->function('md5_hex')->resolve;

  # "d41d8cd98f00b204e9800998ecf8427e"

=back

=over 4

=item resolve example 13

  # given: synopsis;

  my $resolve = $factory->register('md5')->package('Digest::MD5')->function('md5_hex')->resolve('hello');

  # "5d41402abc4b2a76b9719d911017c592"

=back

=over 4

=item resolve example 14

  # given: synopsis;

  $factory->cache({});

  my $secret = $factory->register('secret')->cached(true)->package('Digest::MD5')->function('md5_hex');

  # $secret->resolve(rand);

  # "fa95053a9a204800ced194ffa3fc84bc"

  # $secret->resolve(rand);

  # "fa95053a9a204800ced194ffa3fc84bc"

=back

=over 4

=item resolve example 15

  # given: synopsis;

  my $error = $factory->register('error')->class('Venus::Error');

  $error->constructor(sub{
    my ($factory, $package, $method, @args) = @_;
    return $package->$method(@args)->do('name', 'on.factory.build');
  });

  $error->resolve;

  # bless(..., "Venus::Error")

=back

=over 4

=item resolve example 16

  # given: synopsis;

  my $resolve = $factory->register('data.home')->value('/root')->resolve;

  # "/root"

=back

=over 4

=item resolve example 17

  # given: synopsis;

  my $resolve = $factory
    ->register('data.home')->value('/root')
    ->register('path.home')->class('Venus::Path')->list('data.home')
    ->resolve;

  # bless(..., "Venus::Path")

=back

=cut

=head2 retrieve

  retrieve(string $name) (Venus::Factory)

The retrieve method returns a registered container (dependency resolver) using
the name provided. If no argument is provided the invocant is returned.

I<Since C<4.15>>

=over 4

=item retrieve example 1

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $retrieve = $factory->retrieve;

  # bless(..., "Venus::Factory")

=back

=over 4

=item retrieve example 2

  # given: synopsis;

  $factory->register('path')->class('Venus::Path');

  my $retrieve = $factory->retrieve('path');

  # bless(..., "Venus::Factory")

=back

=cut

=head2 routine

  routine(string $name) (Venus::Factory)

The routine method modifies the current configuration and denotes that object
resolution should result from a routine call (or package call) using the
subroutine name provided.

I<Since C<4.15>>

=over 4

=item routine example 1

  # given: synopsis;

  my $routine = $factory->routine;

  # undef

=back

=over 4

=item routine example 2

  # given: synopsis;

  my $routine = $factory->routine('do_something');

  # bless(..., "Venus::Factory")

=back

=over 4

=item routine example 3

  # given: synopsis;

  $factory->routine('do_something');

  my $routine = $factory->routine;

  # "do_something"

=back

=cut

=head2 value

  value(any @data) (any)

The value method method modifies the current configuration and registers
value(s) to be provided to the L</method>, L</function>, or L</routine> upon
resolution.

I<Since C<4.15>>

=over 4

=item value example 1

  # given: synopsis;

  my $value = $factory->value;

  # undef

=back

=over 4

=item value example 2

  # given: synopsis;

  my $value = $factory->value('hello world');

  # bless(..., "Venus::Factory")

=back

=over 4

=item value example 3

  # given: synopsis;

  $factory->value('hello world');

  my @value = $factory->value;

  # ("hello world")

=back

=over 4

=item value example 4

  # given: synopsis;

  $factory->value({value => 'hello world'});

  my @value = $factory->value;

  # ({value => 'hello world'})

=back

=over 4

=item value example 5

  # given: synopsis;

  $factory->value(1..4);

  my @value = $factory->value;

  # (1..4)

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