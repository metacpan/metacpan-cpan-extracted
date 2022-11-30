package Venus::Assert;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

use Venus::Match;
use Venus::Type;

base 'Venus::Kind::Utility';

with 'Venus::Role::Buildable';

use overload (
  '&{}' => sub{$_[0]->validator},
  fallback => 1,
);

# ATTRIBUTES

attr 'message';
attr 'name';

# BUILDERS

sub build_arg {
  my ($self, $name) = @_;

  return {
    name => $name,
  };
}

sub build_self {
  my ($self, $data) = @_;

  my $name = 'Unknown';
  my $message = 'Type assertion (%s) failed: received (%s)';

  $self->name($name) if !$self->name;
  $self->message($message) if !$self->message;
  $self->conditions;

  return $self;
}

# METHODS

sub any {
  my ($self) = @_;

  $self->constraints->when(sub{true})->then(sub{true});

  return $self;
}

sub accept {
  my ($self, $name, @args) = @_;

  if (!$name) {
    return $self;
  }
  if ($self->can($name)) {
    return $self->$name(@args);
  }
  else {
    return $self->identity($name, @args);
  }
}

sub array {
  my ($self, @code) = @_;

  $self->constraint('array', @code ? @code : sub{true});

  return $self;
}

sub assertion {
  my ($self) = @_;

  my $assert = $self->SUPER::assertion;

  $assert->clear->string;

  return $assert;
}

sub boolean {
  my ($self, @code) = @_;

  $self->constraint('boolean', @code ? @code : sub{true});

  return $self;
}

sub check {
  my ($self, $data) = @_;

  my $value = Venus::Type->new(value => $data);

  my @args = (value => $value, on_none => sub{false});

  return $self->constraints->renew(@args)->result;
}

sub clear {
  my ($self) = @_;

  $self->constraints->clear;
  $self->coercions->clear;

  return $self;
}

sub code {
  my ($self, @code) = @_;

  $self->constraint('code', @code ? @code : sub{true});

  return $self;
}

sub coerce {
  my ($self, $data) = @_;

  my $value = Venus::Type->new(value => $data);

  my @args = (value => $value, on_none => sub{$data});

  return $self->coercions->renew(@args)->result;
}

sub coercion {
  my ($self, $type, $code) = @_;

  $self->coercions->when('coded', $type)->then($code);

  return $self;
}

sub coercions {
  my ($self) = @_;

  my $match = Venus::Match->new;

  return $self->{coercions} ||= $match if ref $self;

  return $match;
}

sub conditions {
  my ($self) = @_;

  return $self;
}

sub constraint {
  my ($self, $type, $code) = @_;

  $self->constraints->when('coded', $type)->then($code);

  return $self;
}

sub constraints {
  my ($self) = @_;

  my $match = Venus::Match->new;

  return $self->{constraints} ||= $match if ref $self;

  return $match;
}

sub consumes {
  my ($self, $role) = @_;

  my $where = $self->constraint('object', sub{true})->constraints->where;

  $where->when(sub{$_->value->DOES($role)})->then(sub{true});

  return $self;
}

sub defined {
  my ($self, @code) = @_;

  $self->constraints->when(sub{CORE::defined($_->value)})
    ->then(@code ? @code : sub{true});

  return $self;
}

sub enum {
  my ($self, @data) = @_;

  for my $item (@data) {
    $self->constraints->when(sub{$_->value eq $item})->then(sub{true});
  }

  return $self;
}

sub float {
  my ($self, @code) = @_;

  $self->constraint('float', @code ? @code : sub{true});

  return $self;
}

sub format {
  my ($self, $name, @code) = @_;

  if (!$name) {
    return $self;
  }
  if (lc($name) eq 'array') {
    return $self->coercion('array', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'boolean') {
    return $self->coercion('boolean', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'code') {
    return $self->coercion('code', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'float') {
    return $self->coercion('float', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'hash') {
    return $self->coercion('hash', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'number') {
    return $self->coercion('number', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'object') {
    return $self->coercion('object', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'regexp') {
    return $self->coercion('regexp', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'scalar') {
    return $self->coercion('scalar', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'string') {
    return $self->coercion('string', @code ? (@code) : sub{$_->value});
  }
  elsif (lc($name) eq 'undef') {
    return $self->coercion('undef', @code ? (@code) : sub{$_->value});
  }
  else {
    return $self->coercion('object', sub {
      UNIVERSAL::isa($_->value, $name)
        ? (@code ? $code[0]->($_->value) : $_->value)
        : $_->value;
    });
  }
}

sub hash {
  my ($self, @code) = @_;

  $self->constraint('hash', @code ? @code : sub{true});

  return $self;
}

sub identity {
  my ($self, $name) = @_;

  $self->constraint('object', sub {$_->value->isa($name) ? true : false});

  return $self;
}

sub maybe {
  my ($self, $match, @args) = @_;

  $self->$match(@args) if $match;
  $self->undef;

  return $self;
}

sub number {
  my ($self, @code) = @_;

  $self->constraint('number', @code ? @code : sub{true});

  return $self;
}

sub object {
  my ($self, @code) = @_;

  $self->constraint('object', @code ? @code : sub{true});

  return $self;
}

sub package {
  my ($self) = @_;

  my $where = $self->constraint('string', sub{true})->constraints->where;

  $where->when(sub{$_->value =~ /^[A-Z](?:(?:\w|::)*[a-zA-Z0-9])?$/})->then(sub{
    require Venus::Space;

    Venus::Space->new($_->value)->loaded
  });

  return $self;
}

sub reference {
  my ($self, @code) = @_;

  $self->constraints
    ->when(sub{CORE::defined($_->value) && ref($_->value)})
    ->then(@code ? @code : sub{true});

  return $self;
}

sub regexp {
  my ($self, @code) = @_;

  $self->constraint('regexp', @code ? @code : sub{true});

  return $self;
}

sub routines {
  my ($self, @data) = @_;

  $self->object->constraints->then(sub{
    my $value = $_->value;
    (@data == grep $value->can($_), @data) ? true : false
  });

  return $self;
}

sub scalar {
  my ($self, @code) = @_;

  $self->constraint('scalar', @code ? @code : sub{true});

  return $self;
}

sub string {
  my ($self, @code) = @_;

  $self->constraint('string', @code ? @code : sub{true});

  return $self;
}

sub tuple {
  my ($self, @data) = @_;

  $self->array->constraints->then(sub{
    my $check = 0;
    my $value = $_->value;
    return false if @data != @$value;
    for (my $i = 0; $i < @data; $i++) {
      my ($match, @args) = (ref $data[$i]) ? (@{$data[$i]}) : ($data[$i]);
      $check++ if $self->new->$match(@args)->check($value->[$i]);
    }
    (@data == $check) ? true : false
  });

  return $self;
}

sub undef {
  my ($self, @code) = @_;

  $self->constraint('undef', @code ? @code : sub{true});

  return $self;
}

sub validate {
  my ($self, $data) = @_;

  my $valid = $self->check($data);

  return $data if $valid;

  require Scalar::Util;

  my $received = defined $data
    ? (
    ref $data
    ? "$data"
    : (Scalar::Util::looks_like_number($data) ? $data : "'$data'"))
    : "undef";

  my $throw;
  $throw = $self->throw;
  $throw->name('on.validate');
  $throw->message(sprintf($self->message, $self->name, $received));
  $throw->stash(identity => lc(Venus::Type->new(value => $data)->identify));
  $throw->stash(variable => $data);
  $throw->error;

  return $throw;
}

sub validator {
  my ($self) = @_;
  return sub {
    $self->validate(@_)
  }
}

sub value {
  my ($self, @code) = @_;

  $self->constraints
    ->when(sub{CORE::defined($_->value) && !ref($_->value)})
    ->then(@code ? @code : sub{true});

  return $self;
}

sub within {
  my ($self, $type) = @_;

  if (!$type) {
    return $self;
  }

  my $where = $self->new;

  if (lc($type) eq 'hash') {
    $self->defined(sub{
      my $value = $_->value;
      UNIVERSAL::isa($value, 'HASH')
        && CORE::values(%$value) == grep $where->check($_), CORE::values(%$value)
    });
  }
  elsif (lc($type) eq 'array') {
    $self->defined(sub{
      my $value = $_->value;
      UNIVERSAL::isa($value, 'ARRAY')
        && @$value == grep $where->check($_), @$value
    });
  }
  else {
    my $throw;
    $throw = $self->throw;
    $throw->name('on.within');
    $throw->message(qq(Invalid type ("$type") provided to the "within" method));
    $throw->stash(argument => $type);
    $throw->error;
  }

  return $where;
}

1;



=head1 NAME

Venus::Assert - Assert Class

=cut

=head1 ABSTRACT

Assert Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Assert;

  my $assert = Venus::Assert->new('Example');

  # $assert->format(float => sub {sprintf('%.2f', $_->value)});

  # $assert->accept(float => sub {$_->value > 1});

  # $assert->check;

=cut

=head1 DESCRIPTION

This package provides a mechanism for asserting type constraints and coercions
on data.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 message

  message(Str)

This attribute is read-write, accepts C<(Str)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-write, accepts C<(Str)> values, and is optional.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 accept

  accept(Str $name, CodeRef $callback) (Object)

The accept method registers a constraint based on the built-in type or package
name provided. Optionally, you can provide a callback to further
constrain/validate the provided value, returning truthy or falsy. The built-in
types are I<"array">, I<"boolean">, I<"code">, I<"float">, I<"hash">,
I<"number">, I<"object">, I<"regexp">, I<"scalar">, I<"string">, or I<"undef">.
Any name given that is not a built-in type is assumed to be an I<"object"> of
the name provided.

I<Since C<1.40>>

=over 4

=item accept example 1

  # given: synopsis

  package main;

  $assert = $assert->accept('float');

  # bless(..., "Venus::Assert")

  # ...

  # $assert->check;

  # 0

  # $assert->check(1.01);

  # 1

=back

=over 4

=item accept example 2

  # given: synopsis

  package main;

  $assert = $assert->accept('number');

  # bless(..., "Venus::Assert")

  # ...

  # $assert->check(1.01);

  # 0

  # $assert->check(1_01);

  # 1

=back

=over 4

=item accept example 3

  # given: synopsis

  package Example1;

  sub new {
    bless {};
  }

  package Example2;

  sub new {
    bless {};
  }

  package main;

  $assert = $assert->accept('object');

  # bless(..., "Venus::Assert")

  # ...

  # $assert->check;

  # 0

  # $assert->check(qr//);

  # 0

  # $assert->check(Example1->new);

  # 1

  # $assert->check(Example2->new);

  # 1

=back

=over 4

=item accept example 4

  # given: synopsis

  package Example1;

  sub new {
    bless {};
  }

  package Example2;

  sub new {
    bless {};
  }

  package main;

  $assert = $assert->accept('Example1');

  # bless(..., "Venus::Assert")

  # ...

  # $assert->check;

  # 0

  # $assert->check(qr//);

  # 0

  # $assert->check(Example1->new);

  # 1

  # $assert->check(Example2->new);

  # 0

=back

=cut

=head2 any

  any() (Assert)

The any method configures the object to accept any value and returns the
invocant.

I<Since C<1.40>>

=over 4

=item any example 1

  # given: synopsis

  package main;

  $assert = $assert->any;

  # $assert->check;

  # true

=back

=cut

=head2 array

  array(CodeRef $check) (Assert)

The array method configures the object to accept array references and returns
the invocant.

I<Since C<1.40>>

=over 4

=item array example 1

  # given: synopsis

  package main;

  $assert = $assert->array;

  # $assert->check([]);

  # true

=back

=cut

=head2 boolean

  boolean(CodeRef $check) (Assert)

The boolean method configures the object to accept boolean values and returns
the invocant.

I<Since C<1.40>>

=over 4

=item boolean example 1

  # given: synopsis

  package main;

  $assert = $assert->boolean;

  # $assert->check(false);

  # true

=back

=cut

=head2 check

  check(Any $data) (Bool)

The check method returns true or false if the data provided passes the
registered constraints.

I<Since C<1.23>>

=over 4

=item check example 1

  # given: synopsis

  package main;

  $assert->constraint(float => sub { $_->value > 1 });

  my $check = $assert->check;

  # 0

=back

=over 4

=item check example 2

  # given: synopsis

  package main;

  $assert->constraint(float => sub { $_->value > 1 });

  my $check = $assert->check('0.01');

  # 0

=back

=over 4

=item check example 3

  # given: synopsis

  package main;

  $assert->constraint(float => sub { $_->value > 1 });

  my $check = $assert->check('1.01');

  # 1

=back

=over 4

=item check example 4

  # given: synopsis

  package main;

  $assert->constraint(float => sub { $_->value > 1 });

  my $check = $assert->check(time);

  # 0

=back

=cut

=head2 clear

  clear() (Assert)

The clear method resets all match conditions for both constraints and coercions
and returns the invocant.

I<Since C<1.40>>

=over 4

=item clear example 1

  # given: synopsis

  package main;

  $assert = $assert->clear;

  # bless(..., "Venus::Assert")

=back

=cut

=head2 code

  code(CodeRef $check) (Assert)

The code method configures the object to accept code references and returns
the invocant.

I<Since C<1.40>>

=over 4

=item code example 1

  # given: synopsis

  package main;

  $assert = $assert->code;

  # $assert->check(sub{});

  # true

=back

=cut

=head2 coerce

  coerce(Any $data) (Any)

The coerce method returns the coerced data if the data provided matches any of
the registered coercions.

I<Since C<1.23>>

=over 4

=item coerce example 1

  # given: synopsis

  package main;

  $assert->coercion(float => sub { sprintf('%.2f', $_->value) });

  my $coerce = $assert->coerce;

  # undef

=back

=over 4

=item coerce example 2

  # given: synopsis

  package main;

  $assert->coercion(float => sub { sprintf('%.2f', $_->value) });

  my $coerce = $assert->coerce('1.01');

  # "1.01"

=back

=over 4

=item coerce example 3

  # given: synopsis

  package main;

  $assert->coercion(float => sub { sprintf('%.2f', $_->value) });

  my $coerce = $assert->coerce('1.00001');

  # "1.00"

=back

=over 4

=item coerce example 4

  # given: synopsis

  package main;

  $assert->coercion(float => sub { sprintf('%.2f', $_->value) });

  my $coerce = $assert->coerce('hello world');

  # "hello world"

=back

=cut

=head2 coercion

  coercion(Str $type, CodeRef $code) (Object)

The coercion method registers a coercion based on the type provided.

I<Since C<1.23>>

=over 4

=item coercion example 1

  # given: synopsis

  package main;

  $assert = $assert->coercion(float => sub { sprintf('%.2f', $_->value) });

  # bless(..., "Venus::Assert")

=back

=cut

=head2 coercions

  coercions() (Match)

The coercions method returns the registered coercions as a L<Venus::Match> object.

I<Since C<1.23>>

=over 4

=item coercions example 1

  # given: synopsis

  package main;

  my $coercions = $assert->coercions;

  # bless(..., "Venus::Match")

=back

=cut

=head2 conditions

  conditions() (Assert)

The conditions method is an object construction hook that allows subclasses to
configure the object on construction setting up constraints and coercions and
returning the invocant.

I<Since C<1.40>>

=over 4

=item conditions example 1

  # given: synopsis

  package main;

  $assert = $assert->conditions;

=back

=over 4

=item conditions example 2

  package Example::Type::PositveNumber;

  use base 'Venus::Assert';

  sub conditions {
    my ($self) = @_;

    $self->number(sub {
      $_->value >= 0
    });

    return $self;
  }

  package main;

  my $assert = Example::Type::PositveNumber->new;

  # $assert->check(0);

  # true

  # $assert->check(1);

  # true

  # $assert->check(-1);

  # false

=back

=cut

=head2 constraint

  constraint(Str $type, CodeRef $code) (Object)

The constraint method registers a constraint based on the type provided.

I<Since C<1.23>>

=over 4

=item constraint example 1

  # given: synopsis

  package main;

  $assert = $assert->constraint(float => sub { $_->value > 1 });

  # bless(..., "Venus::Assert")

=back

=cut

=head2 constraints

  constraints() (Match)

The constraints method returns the registered constraints as a L<Venus::Match>
object.

I<Since C<1.23>>

=over 4

=item constraints example 1

  # given: synopsis

  package main;

  my $constraints = $assert->constraints;

  # bless(..., "Venus::Match")

=back

=cut

=head2 defined

  defined(CodeRef $check) (Assert)

The defined method configures the object to accept any value that's not
undefined and returns the invocant.

I<Since C<1.40>>

=over 4

=item defined example 1

  # given: synopsis

  package main;

  $assert = $assert->defined;

  # $assert->check(0);

  # true

=back

=cut

=head2 enum

  enum(Any @data) (Assert)

The enum method configures the object to accept any one of the provide options,
and returns the invocant.

I<Since C<1.40>>

=over 4

=item enum example 1

  # given: synopsis

  package main;

  $assert = $assert->enum('s', 'm', 'l', 'xl');

  # $assert->check('s');

  # true

  # $assert->check('xs');

  # false

=back

=cut

=head2 float

  float(CodeRef $check) (Assert)

The float method configures the object to accept floating-point values and
returns the invocant.

I<Since C<1.40>>

=over 4

=item float example 1

  # given: synopsis

  package main;

  $assert = $assert->float;

  # $assert->check(1.23);

  # true

=back

=cut

=head2 format

  format(Str $name, CodeRef $callback) (Object)

The format method registers a coercion based on the built-in type or package
name and callback provided. The built-in types are I<"array">, I<"boolean">,
I<"code">, I<"float">, I<"hash">, I<"number">, I<"object">, I<"regexp">,
I<"scalar">, I<"string">, or I<"undef">.  Any name given that is not a built-in
type is assumed to be an I<"object"> of the name provided.

I<Since C<1.40>>

=over 4

=item format example 1

  # given: synopsis

  package main;

  $assert = $assert->format('float', sub{int $_->value});

  # bless(..., "Venus::Assert")

  # ...

  # $assert->coerce;

  # undef

  # $assert->coerce(1.01);

  # 1

=back

=over 4

=item format example 2

  # given: synopsis

  package main;

  $assert = $assert->format('number', sub{ sprintf('%.2f', $_->value) });

  # bless(..., "Venus::Assert")

  # ...

  # $assert->coerce(1.01);

  # 1.01

  # $assert->coerce(1_01);

  # 101.00

=back

=over 4

=item format example 3

  # given: synopsis

  package Example1;

  sub new {
    bless {};
  }

  package Example2;

  sub new {
    bless {};
  }

  package main;

  $assert = $assert->format('object', sub{ ref $_->value });

  # bless(..., "Venus::Assert")

  # ...

  # $assert->coerce(qr//);

  # qr//

  # $assert->coerce(Example1->new);

  # "Example1"

  # $assert->coerce(Example2->new);

  # "Example2"

=back

=over 4

=item format example 4

  # given: synopsis

  package Example1;

  sub new {
    bless {};
  }

  package Example2;

  sub new {
    bless {};
  }

  package main;

  $assert = $assert->format('Example1', sub{ ref $_->value });

  # bless(..., "Venus::Assert")

  # ...

  # $assert->coerce(qr//);

  # qr//

  # $assert->coerce(Example1->new);

  # "Example1"

  # $assert->coerce(Example2->new);

  # bless({}, "Example2")

=back

=cut

=head2 hash

  hash(CodeRef $check) (Assert)

The hash method configures the object to accept hash references and returns
the invocant.

I<Since C<1.40>>

=over 4

=item hash example 1

  # given: synopsis

  package main;

  $assert = $assert->hash;

  # $assert->check({});

  # true

=back

=cut

=head2 identity

  identity(Str $name) (Assert)

The identity method configures the object to accept objects of the type
specified as the argument, and returns the invocant.

I<Since C<1.40>>

=over 4

=item identity example 1

  # given: synopsis

  package main;

  $assert = $assert->identity('Venus::Assert');

  # $assert->check(Venus::Assert->new);

  # true

=back

=cut

=head2 maybe

  maybe(Str $type, Any @args) (Assert)

The maybe method configures the object to accept the type provided as an
argument, or undef, and returns the invocant.

I<Since C<1.40>>

=over 4

=item maybe example 1

  # given: synopsis

  package main;

  $assert = $assert->maybe('code');

  # $assert->check(sub{});

  # true

  # $assert->check(undef);

  # true

=back

=cut

=head2 number

  number(CodeRef $check) (Assert)

The number method configures the object to accept numberic values and returns
the invocant.

I<Since C<1.40>>

=over 4

=item number example 1

  # given: synopsis

  package main;

  $assert = $assert->number;

  # $assert->check(0);

  # true

=back

=cut

=head2 object

  object(CodeRef $check) (Assert)

The object method configures the object to accept objects and returns the
invocant.

I<Since C<1.40>>

=over 4

=item object example 1

  # given: synopsis

  package main;

  $assert = $assert->object;

  # $assert->check(bless{});

  # true

=back

=cut

=head2 package

  package() (Assert)

The package method configures the object to accept package names (which are
loaded) and returns the invocant.

I<Since C<1.40>>

=over 4

=item package example 1

  # given: synopsis

  package main;

  $assert = $assert->package;

  # $assert->check('Venus');

  # true

=back

=cut

=head2 reference

  reference(CodeRef $check) (Assert)

The reference method configures the object to accept references and returns the
invocant.

I<Since C<1.40>>

=over 4

=item reference example 1

  # given: synopsis

  package main;

  $assert = $assert->reference;

  # $assert->check(sub{});

  # true

=back

=cut

=head2 regexp

  regexp(CodeRef $check) (Assert)

The regexp method configures the object to accept regular expression objects
and returns the invocant.

I<Since C<1.40>>

=over 4

=item regexp example 1

  # given: synopsis

  package main;

  $assert = $assert->regexp;

  # $assert->check(qr//);

  # true

=back

=cut

=head2 routines

  routines(Str @names) (Assert)

The routines method configures the object to accept an object having all of the
routines provided, and returns the invocant.

I<Since C<1.40>>

=over 4

=item routines example 1

  # given: synopsis

  package main;

  $assert = $assert->routines('new', 'print', 'say');

  # $assert->check(Venus::Assert->new);

  # true

=back

=cut

=head2 scalar

  scalar(CodeRef $check) (Assert)

The scalar method configures the object to accept scalar references and returns
the invocant.

I<Since C<1.40>>

=over 4

=item scalar example 1

  # given: synopsis

  package main;

  $assert = $assert->scalar;

  # $assert->check(\1);

  # true

=back

=cut

=head2 string

  string(CodeRef $check) (Assert)

The string method configures the object to accept string values and returns the
invocant.

I<Since C<1.40>>

=over 4

=item string example 1

  # given: synopsis

  package main;

  $assert = $assert->string;

  # $assert->check('');

  # true

=back

=cut

=head2 tuple

  tuple(Str | ArrayRef[Str] @types) (Assert)

The tuple method configures the object to accept array references which conform
to a tuple specification, and returns the invocant.

I<Since C<1.40>>

=over 4

=item tuple example 1

  # given: synopsis

  package main;

  $assert = $assert->tuple('number', ['maybe', 'array'], 'code');

  # $assert->check([200, [], sub{}]);

  # true

=back

=cut

=head2 undef

  undef(CodeRef $check) (Assert)

The undef method configures the object to accept undefined values and returns
the invocant.

I<Since C<1.40>>

=over 4

=item undef example 1

  # given: synopsis

  package main;

  $assert = $assert->undef;

  # $assert->check(undef);

  # true

=back

=cut

=head2 validate

  validate(Any $data) (Any)

The validate method returns the data provided if the data provided passes the
registered constraints, or throws an exception.

I<Since C<1.23>>

=over 4

=item validate example 1

  # given: synopsis

  package main;

  $assert->constraint(float => sub { $_->value > 1 });

  my $result = $assert->validate;

  # Exception! (isa Venus::Assert::Error)

=back

=over 4

=item validate example 2

  # given: synopsis

  package main;

  $assert->constraint(float => sub { $_->value > 1 });

  my $result = $assert->validate('0.01');

  # Exception! (isa Venus::Assert::Error)

=back

=over 4

=item validate example 3

  # given: synopsis

  package main;

  $assert->constraint(float => sub { $_->value > 1 });

  my $result = $assert->validate('1.01');

  # "1.01"

=back

=over 4

=item validate example 4

  # given: synopsis

  package main;

  $assert->constraint(float => sub { $_->value > 1 });

  my $result = $assert->validate(time);

  # Exception! (isa Venus::Assert::Error)

=back

=cut

=head2 validator

  validator() (CodeRef)

The validator method returns a coderef that can be used as a value validator,
which returns the data provided if the data provided passes the registered
constraints, or throws an exception.

I<Since C<1.40>>

=over 4

=item validator example 1

  # given: synopsis

  package main;

  $assert->constraint(float => sub { $_->value > 1 });

  my $result = $assert->validator;

  # sub {...}

=back

=cut

=head2 value

  value(CodeRef $check) (Assert)

The value method configures the object to accept defined, non-reference,
values, and returns the invocant.

I<Since C<1.40>>

=over 4

=item value example 1

  # given: synopsis

  package main;

  $assert = $assert->value;

  # $assert->check(1_000_000);

  # true

=back

=cut

=head2 within

  within(Str $type) (Assert)

The within method configures the object, registering a constraint action as a
sub-match operation, to accept array or hash based values, and returns the
invocant.

I<Since C<1.40>>

=over 4

=item within example 1

  # given: synopsis

  package main;

  my $within = $assert->within('array')->code;

  my $action = $assert;

  # $assert->check([]);

  # true

  # $assert->check([sub{}]);

  # true

  # $assert->check([{}]);

  # false

  # $assert->check(bless[]);

  # true

=back

=over 4

=item within example 2

  # given: synopsis

  package main;

  my $within = $assert->within('hash')->code;

  my $action = $assert;

  # $assert->check({});

  # true

  # $assert->check({test => sub{}});

  # true

  # $assert->check({test => {}});

  # false

  # $assert->check({test => bless{}});

  # true

=back

=cut