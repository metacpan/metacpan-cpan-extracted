package Venus::Hash;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base', 'with';

base 'Venus::Kind::Value';

with 'Venus::Role::Mappable';

# BUILDERS

sub build_args {
  my ($self, $data) = @_;

  if (keys %$data == 1 && exists $data->{value}) {
    return $data;
  }
  return {
    value => $data
  };
}

# METHODS

sub all {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $failed = 0;

  for my $index (CORE::keys %$data) {
    my $value = $data->{$index};

    local $_ = $value;
    $failed++ if !$code->($index, $value);

    CORE::last if $failed;
  }

  return $failed ? false : true;
}

sub any {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $found = 0;

  for my $index (CORE::keys %$data) {
    my $value = $data->{$index};

    local $_ = $value;
    $found++ if $code->($index, $value);

    CORE::last if $found;
  }

  return $found ? true : false;
}

sub call {
  my ($self, $mapper, $method, @args) = @_;

  require Venus::Type;

  return $self->$mapper(sub{
    my ($key, $val) = @_;

    my $type = Venus::Type->new($val)->deduce;

    local $_ = $type;

    $key, $type->$method(@args)
  });
}

sub count {
  my ($self) = @_;

  my $data = $self->get;

  return scalar(CORE::keys(%$data));
}

sub default {
  return {};
}

sub delete {
  my ($self, $key) = @_;

  my $data = $self->get;

  return CORE::delete($data->{$key});
}

sub each {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $results = [];

  for my $index (CORE::sort(CORE::keys(%$data))) {
    my $value = $data->{$index};

    local $_ = $value;
    CORE::push(@$results, $code->($index, $value));
  }

  return wantarray ? (@$results) : $results;
}

sub empty {
  my ($self) = @_;

  my $data = $self->get;

  CORE::delete(@$data{CORE::keys(%$data)});

  return $data;
}

sub exists {
  my ($self, $key) = @_;

  my $data = $self->get;

  return CORE::exists($data->{$key}) ? true : false;
}

sub find {
  my ($self, @args) = @_;

  my $seen = 0;
  my $item = my $data = $self->get;

  for (my $i = 0; $i < @args; $i++) {
    if (ref($item) eq 'ARRAY') {
      if ($args[$i] !~ /^\d+$/) {
        $item = undef;
        $seen = 0;
        CORE::last;
      }
      $seen = $args[$i] <= $#{$item};
      $item = $item->[$args[$i]];
    }
    elsif (ref($item) eq 'HASH') {
      $seen = exists $item->{$args[$i]};
      $item = $item->{$args[$i]};
    }
    else {
      $item = undef;
      $seen = 0;
    }
  }

  return wantarray ? ($item, int(!!$seen)) : $item;
}

sub get {
  my ($self, @args) = @_;

  return $self->value if !@args;

  my ($index) = @args;

  return $self->value->{$index};
}

sub grep {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $result = [];

  for my $index (CORE::sort(CORE::keys(%$data))) {
    my $value = $data->{$index};

    local $_ = $value;
    CORE::push(@$result, $index, $value) if $code->($index, $value);
  }

  return wantarray ? (@$result) : $result;
}

sub iterator {
  my ($self) = @_;

  my $data = $self->get;
  my @keys = CORE::sort(CORE::keys(%{$data}));

  my $i = 0;
  my $j = 0;

  return sub {
    return undef if $i > $#keys;
    return wantarray ? ($keys[$j++], $data->{$keys[$i++]}) : $data->{$keys[$i++]};
  }
}

sub keys {
  my ($self) = @_;

  my $data = $self->get;

  return [CORE::sort(CORE::keys(%$data))];
}

sub length {
  my ($self) = @_;

  return $self->count;
}

sub list {
  my ($self) = @_;

  return wantarray ? (%{$self->value}) : scalar(CORE::keys(%{$self->value}));
}

sub map {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $result = [];

  for my $index (CORE::sort(CORE::keys(%$data))) {
    my $value = $data->{$index};

    local $_ = $value;
    CORE::push(@$result, ($code->($index, $value)));
  }

  return wantarray ? (@$result) : $result;
}

sub merge {
  my ($self, @rvalues) = @_;

  require Venus;

  my $lvalue = {%{$self->get}};

  return Venus::merge($lvalue, @rvalues);
}

sub none {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $found = 0;

  for my $index (CORE::sort(CORE::keys(%$data))) {
    my $value = $data->{$index};

    local $_ = $value;
    $found++ if $code->($index, $value);

    CORE::last if $found;
  }

  return $found ? false : true;
}

sub one {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $found = 0;

  for my $index (CORE::sort(CORE::keys(%$data))) {
    my $value = $data->{$index};

    local $_ = $value;
    $found++ if $code->($index, $value);

    CORE::last if $found > 1;
  }

  return $found == 1 ? true : false;
}

sub pairs {
  my ($self) = @_;

  my $data = $self->get;

  my $result = [CORE::map { [$_, $data->{$_}] } CORE::sort(CORE::keys(%$data))];

  return wantarray ? (@$result) : $result;
}

sub path {
  my ($self, $path) = @_;

  my @path = CORE::grep(/./, CORE::split(/\W/, $path));

  return wantarray ? ($self->find(@path)) : $self->find(@path);
}

sub puts {
  my ($self, @args) = @_;

  my $result = [];

  require Venus::Array;

  for (my $i = 0; $i < @args; $i += 2) {
    my ($into, $path) = @args[$i, $i+1];

    next if !defined $path;

    my $value;
    my @range;

    ($path, @range) = @{$path} if ref $path eq 'ARRAY';

    $value = $self->path($path);
    $value = Venus::Array->new($value)->range(@range) if ref $value eq 'ARRAY';

    if (ref $into eq 'SCALAR') {
      $$into = $value;
    }

    CORE::push @{$result}, $value;
  }

  return wantarray ? (@{$result}) : $result;
}

sub random {
  my ($self) = @_;

  my $data = $self->get;
  my $keys = [CORE::keys(%$data)];

  return $data->{@$keys[rand($#{$keys}+1)]};
}

sub reset {
  my ($self) = @_;

  my $data = $self->get;

  @$data{CORE::keys(%$data)} = ();

  return $data;
}

sub reverse {
  my ($self) = @_;

  my $data = $self->get;

  my $result = {};

  for (CORE::grep(CORE::defined($data->{$_}), CORE::sort(CORE::keys(%$data)))) {
    $result->{$_} = $data->{$_};
  }

  return {CORE::reverse(%$result)};
}

sub set {
  my ($self, @args) = @_;

  return $self->value if !@args;

  return $self->value(@args) if @args == 1 && ref $args[0] eq 'HASH';

  my ($index, $value) = @args;

  return if not defined $index;

  return $self->value->{$index} = $value;
}

sub slice {
  my ($self, @args) = @_;

  my $data = $self->get;

  return [@{$data}{@args}];
}

1;



=head1 NAME

Venus::Hash - Hash Class

=cut

=head1 ABSTRACT

Hash Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({1..8});

  # $hash->random;

=cut

=head1 DESCRIPTION

This package provides methods for manipulating hash data.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Value>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Mappable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 all

  all(coderef $code) (boolean)

The all method returns true if the callback returns true for all of the
elements.

I<Since C<0.01>>

=over 4

=item all example 1

  # given: synopsis;

  my $all = $hash->all(sub {
    $_ > 1
  });

  # 1

=back

=over 4

=item all example 2

  # given: synopsis;

  my $all = $hash->all(sub {
    my ($key, $value) = @_;

    $value > 1
  });

  # 1

=back

=cut

=head2 any

  any(coderef $code) (boolean)

The any method returns true if the callback returns true for any of the
elements.

I<Since C<0.01>>

=over 4

=item any example 1

  # given: synopsis;

  my $any = $hash->any(sub {
    $_ < 1
  });

  # 0

=back

=over 4

=item any example 2

  # given: synopsis;

  my $any = $hash->any(sub {
    my ($key, $value) = @_;

    $value < 1
  });

  # 0

=back

=cut

=head2 call

  call(string $iterable, string $method) (any)

The call method executes the given method (named using the first argument)
which performs an iteration (i.e. takes a callback) and calls the method (named
using the second argument) on the object (or value) and returns the result of
the iterable method.

I<Since C<1.02>>

=over 4

=item call example 1

  # given: synopsis

  package main;

  my $call = $hash->call('map', 'incr');

  # ['1', 3, '3', 5, '5', 7, '7', 9]

=back

=over 4

=item call example 2

  # given: synopsis

  package main;

  my $call = $hash->call('grep', 'gt', 4);

  # [5..8]

=back

=cut

=head2 cast

  cast(string $kind) (object | undef)

The cast method converts L<"value"|Venus::Kind::Value> objects between
different I<"value"> object types, based on the name of the type provided. This
method will return C<undef> if the invocant is not a L<Venus::Kind::Value>.

I<Since C<0.08>>

=over 4

=item cast example 1

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('array');

  # bless({ value => [{}] }, "Venus::Array")

=back

=over 4

=item cast example 2

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('boolean');

  # bless({ value => 1 }, "Venus::Boolean")

=back

=over 4

=item cast example 3

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('code');

  # bless({ value => sub { ... } }, "Venus::Code")

=back

=over 4

=item cast example 4

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('float');

  # bless({ value => "1.0" }, "Venus::Float")

=back

=over 4

=item cast example 5

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('hash');

  # bless({ value => {} }, "Venus::Hash")

=back

=over 4

=item cast example 6

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('number');

  # bless({ value => 2 }, "Venus::Number")

=back

=over 4

=item cast example 7

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('regexp');

  # bless({ value => qr/(?^u:\{\})/ }, "Venus::Regexp")

=back

=over 4

=item cast example 8

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('scalar');

  # bless({ value => \{} }, "Venus::Scalar")

=back

=over 4

=item cast example 9

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('string');

  # bless({ value => "{}" }, "Venus::String")

=back

=over 4

=item cast example 10

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new;

  my $cast = $hash->cast('undef');

  # bless({ value => undef }, "Venus::Undef")

=back

=cut

=head2 count

  count() (number)

The count method returns the total number of keys defined.

I<Since C<0.01>>

=over 4

=item count example 1

  # given: synopsis;

  my $count = $hash->count;

  # 4

=back

=cut

=head2 default

  default() (hashref)

The default method returns the default value, i.e. C<{}>.

I<Since C<0.01>>

=over 4

=item default example 1

  # given: synopsis;

  my $default = $hash->default;

  # {}

=back

=cut

=head2 delete

  delete(string $key) (any)

The delete method returns the value matching the key specified in the argument
and returns the value.

I<Since C<0.01>>

=over 4

=item delete example 1

  # given: synopsis;

  my $delete = $hash->delete(1);

  # 2

=back

=cut

=head2 each

  each(coderef $code) (arrayref)

The each method executes callback for each element in the hash passing the
routine the key and value at the current position in the loop. This method can
return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item each example 1

  # given: synopsis;

  my $each = $hash->each(sub {
    [$_]
  });

  # [[2], [4], [6], [8]]

=back

=over 4

=item each example 2

  # given: synopsis;

  my $each = $hash->each(sub {
    my ($key, $value) = @_;

    [$key, $value]
  });

  # [[1, 2], [3, 4], [5, 6], [7, 8]]

=back

=cut

=head2 empty

  empty() (hashref)

The empty method drops all elements from the hash.

I<Since C<0.01>>

=over 4

=item empty example 1

  # given: synopsis;

  my $empty = $hash->empty;

  # {}

=back

=cut

=head2 eq

  eq(any $arg) (boolean)

The eq method performs an I<"equals"> operation using the argument provided.

I<Since C<0.08>>

=over 4

=item eq example 1

  package main;

  use Venus::Array;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Array->new;

  my $result = $lvalue->eq($rvalue);

  # 0

=back

=over 4

=item eq example 2

  package main;

  use Venus::Code;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Code->new;

  my $result = $lvalue->eq($rvalue);

  # 0

=back

=over 4

=item eq example 3

  package main;

  use Venus::Float;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Float->new;

  my $result = $lvalue->eq($rvalue);

  # 0

=back

=over 4

=item eq example 4

  package main;

  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Hash->new;

  my $result = $lvalue->eq($rvalue);

  # 1

=back

=over 4

=item eq example 5

  package main;

  use Venus::Hash;
  use Venus::Number;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Number->new;

  my $result = $lvalue->eq($rvalue);

  # 0

=back

=over 4

=item eq example 6

  package main;

  use Venus::Hash;
  use Venus::Regexp;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Regexp->new;

  my $result = $lvalue->eq($rvalue);

  # 0

=back

=over 4

=item eq example 7

  package main;

  use Venus::Hash;
  use Venus::Scalar;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Scalar->new;

  my $result = $lvalue->eq($rvalue);

  # 0

=back

=over 4

=item eq example 8

  package main;

  use Venus::Hash;
  use Venus::String;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::String->new;

  my $result = $lvalue->eq($rvalue);

  # 0

=back

=over 4

=item eq example 9

  package main;

  use Venus::Hash;
  use Venus::Undef;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Undef->new;

  my $result = $lvalue->eq($rvalue);

  # 0

=back

=cut

=head2 exists

  exists(string $key) (boolean)

The exists method returns true if the value matching the key specified in the
argument exists, otherwise returns false.

I<Since C<0.01>>

=over 4

=item exists example 1

  # given: synopsis;

  my $exists = $hash->exists(1);

  # 1

=back

=over 4

=item exists example 2

  # given: synopsis;

  my $exists = $hash->exists(0);

  # 0

=back

=cut

=head2 find

  find(string @data) (any)

The find method traverses the data structure using the keys and indices
provided, returning the value found or undef. In list-context, this method
returns a tuple, i.e. the value found and boolean representing whether the
match was successful.

I<Since C<0.01>>

=over 4

=item find example 1

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({'foo' => {'bar' => 'baz'},'bar' => ['baz']});

  my $find = $hash->find('foo', 'bar');

  # "baz"

=back

=over 4

=item find example 2

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({'foo' => {'bar' => 'baz'},'bar' => ['baz']});

  my $find = $hash->find('bar', 0);

  # "baz"

=back

=over 4

=item find example 3

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({'foo' => {'bar' => 'baz'},'bar' => ['baz']});

  my $find = $hash->find('bar');

  # ["baz"]

=back

=over 4

=item find example 4

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({'foo' => {'bar' => 'baz'},'bar' => ['baz']});

  my ($find, $exists) = $hash->find('baz');

  # (undef, 0)

=back

=cut

=head2 ge

  ge(any $arg) (boolean)

The ge method performs a I<"greater-than-or-equal-to"> operation using the
argument provided.

I<Since C<0.08>>

=over 4

=item ge example 1

  package main;

  use Venus::Array;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Array->new;

  my $result = $lvalue->ge($rvalue);

  # 0

=back

=over 4

=item ge example 2

  package main;

  use Venus::Code;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Code->new;

  my $result = $lvalue->ge($rvalue);

  # 0

=back

=over 4

=item ge example 3

  package main;

  use Venus::Float;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Float->new;

  my $result = $lvalue->ge($rvalue);

  # 1

=back

=over 4

=item ge example 4

  package main;

  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Hash->new;

  my $result = $lvalue->ge($rvalue);

  # 1

=back

=over 4

=item ge example 5

  package main;

  use Venus::Hash;
  use Venus::Number;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Number->new;

  my $result = $lvalue->ge($rvalue);

  # 1

=back

=over 4

=item ge example 6

  package main;

  use Venus::Hash;
  use Venus::Regexp;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Regexp->new;

  my $result = $lvalue->ge($rvalue);

  # 0

=back

=over 4

=item ge example 7

  package main;

  use Venus::Hash;
  use Venus::Scalar;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Scalar->new;

  my $result = $lvalue->ge($rvalue);

  # 0

=back

=over 4

=item ge example 8

  package main;

  use Venus::Hash;
  use Venus::String;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::String->new;

  my $result = $lvalue->ge($rvalue);

  # 1

=back

=over 4

=item ge example 9

  package main;

  use Venus::Hash;
  use Venus::Undef;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Undef->new;

  my $result = $lvalue->ge($rvalue);

  # 1

=back

=cut

=head2 gele

  gele(any $arg1, any $arg2) (boolean)

The gele method performs a I<"greater-than-or-equal-to"> operation on the 1st
argument, and I<"lesser-than-or-equal-to"> operation on the 2nd argument.

I<Since C<0.08>>

=over 4

=item gele example 1

  package main;

  use Venus::Array;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Array->new;

  my $result = $lvalue->gele($rvalue);

  # 0

=back

=over 4

=item gele example 2

  package main;

  use Venus::Code;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Code->new;

  my $result = $lvalue->gele($rvalue);

  # 0

=back

=over 4

=item gele example 3

  package main;

  use Venus::Float;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Float->new;

  my $result = $lvalue->gele($rvalue);

  # 0

=back

=over 4

=item gele example 4

  package main;

  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Hash->new;

  my $result = $lvalue->gele($rvalue);

  # 0

=back

=over 4

=item gele example 5

  package main;

  use Venus::Hash;
  use Venus::Number;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Number->new;

  my $result = $lvalue->gele($rvalue);

  # 0

=back

=over 4

=item gele example 6

  package main;

  use Venus::Hash;
  use Venus::Regexp;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Regexp->new;

  my $result = $lvalue->gele($rvalue);

  # 0

=back

=over 4

=item gele example 7

  package main;

  use Venus::Hash;
  use Venus::Scalar;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Scalar->new;

  my $result = $lvalue->gele($rvalue);

  # 0

=back

=over 4

=item gele example 8

  package main;

  use Venus::Hash;
  use Venus::String;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::String->new;

  my $result = $lvalue->gele($rvalue);

  # 0

=back

=over 4

=item gele example 9

  package main;

  use Venus::Hash;
  use Venus::Undef;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Undef->new;

  my $result = $lvalue->gele($rvalue);

  # 0

=back

=cut

=head2 grep

  grep(coderef $code) (arrayref)

The grep method executes callback for each key/value pair in the hash passing
the routine the key and value at the current position in the loop and returning
a new hash reference containing the elements for which the argument evaluated
true. This method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item grep example 1

  # given: synopsis;

  my $grep = $hash->grep(sub {
    $_ >= 3
  });

  # [3..8]

=back

=over 4

=item grep example 2

  # given: synopsis;

  my $grep = $hash->grep(sub {
    my ($key, $value) = @_;

    $value >= 3
  });

  # [3..8]

=back

=cut

=head2 gt

  gt(any $arg) (boolean)

The gt method performs a I<"greater-than"> operation using the argument provided.

I<Since C<0.08>>

=over 4

=item gt example 1

  package main;

  use Venus::Array;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Array->new;

  my $result = $lvalue->gt($rvalue);

  # 0

=back

=over 4

=item gt example 2

  package main;

  use Venus::Code;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Code->new;

  my $result = $lvalue->gt($rvalue);

  # 0

=back

=over 4

=item gt example 3

  package main;

  use Venus::Float;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Float->new;

  my $result = $lvalue->gt($rvalue);

  # 1

=back

=over 4

=item gt example 4

  package main;

  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Hash->new;

  my $result = $lvalue->gt($rvalue);

  # 0

=back

=over 4

=item gt example 5

  package main;

  use Venus::Hash;
  use Venus::Number;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Number->new;

  my $result = $lvalue->gt($rvalue);

  # 1

=back

=over 4

=item gt example 6

  package main;

  use Venus::Hash;
  use Venus::Regexp;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Regexp->new;

  my $result = $lvalue->gt($rvalue);

  # 0

=back

=over 4

=item gt example 7

  package main;

  use Venus::Hash;
  use Venus::Scalar;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Scalar->new;

  my $result = $lvalue->gt($rvalue);

  # 0

=back

=over 4

=item gt example 8

  package main;

  use Venus::Hash;
  use Venus::String;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::String->new;

  my $result = $lvalue->gt($rvalue);

  # 1

=back

=over 4

=item gt example 9

  package main;

  use Venus::Hash;
  use Venus::Undef;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Undef->new;

  my $result = $lvalue->gt($rvalue);

  # 1

=back

=cut

=head2 gtlt

  gtlt(any $arg1, any $arg2) (boolean)

The gtlt method performs a I<"greater-than"> operation on the 1st argument, and
I<"lesser-than"> operation on the 2nd argument.

I<Since C<0.08>>

=over 4

=item gtlt example 1

  package main;

  use Venus::Array;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Array->new;

  my $result = $lvalue->gtlt($rvalue);

  # 0

=back

=over 4

=item gtlt example 2

  package main;

  use Venus::Code;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Code->new;

  my $result = $lvalue->gtlt($rvalue);

  # 0

=back

=over 4

=item gtlt example 3

  package main;

  use Venus::Float;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Float->new;

  my $result = $lvalue->gtlt($rvalue);

  # 0

=back

=over 4

=item gtlt example 4

  package main;

  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Hash->new;

  my $result = $lvalue->gtlt($rvalue);

  # 0

=back

=over 4

=item gtlt example 5

  package main;

  use Venus::Hash;
  use Venus::Number;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Number->new;

  my $result = $lvalue->gtlt($rvalue);

  # 0

=back

=over 4

=item gtlt example 6

  package main;

  use Venus::Hash;
  use Venus::Regexp;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Regexp->new;

  my $result = $lvalue->gtlt($rvalue);

  # 0

=back

=over 4

=item gtlt example 7

  package main;

  use Venus::Hash;
  use Venus::Scalar;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Scalar->new;

  my $result = $lvalue->gtlt($rvalue);

  # 0

=back

=over 4

=item gtlt example 8

  package main;

  use Venus::Hash;
  use Venus::String;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::String->new;

  my $result = $lvalue->gtlt($rvalue);

  # 0

=back

=over 4

=item gtlt example 9

  package main;

  use Venus::Hash;
  use Venus::Undef;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Undef->new;

  my $result = $lvalue->gtlt($rvalue);

  # 0

=back

=cut

=head2 iterator

  iterator() (coderef)

The iterator method returns a code reference which can be used to iterate over
the hash. Each time the iterator is executed it will return the values of the
next element in the hash until all elements have been seen, at which point the
iterator will return an undefined value. This method can return a tuple with
the key and value in list-context.

I<Since C<0.01>>

=over 4

=item iterator example 1

  # given: synopsis;

  my $iterator = $hash->iterator;

  # sub { ... }

  # while (my $value = $iterator->()) {
  #   say $value; # 1
  # }

=back

=over 4

=item iterator example 2

  # given: synopsis;

  my $iterator = $hash->iterator;

  # sub { ... }

  # while (grep defined, my ($key, $value) = $iterator->()) {
  #   say $value; # 1
  # }

=back

=cut

=head2 keys

  keys() (arrayref)

The keys method returns an array reference consisting of all the keys in the
hash.

I<Since C<0.01>>

=over 4

=item keys example 1

  # given: synopsis;

  my $keys = $hash->keys;

  # [1, 3, 5, 7]

=back

=cut

=head2 le

  le(any $arg) (boolean)

The le method performs a I<"lesser-than-or-equal-to"> operation using the
argument provided.

I<Since C<0.08>>

=over 4

=item le example 1

  package main;

  use Venus::Array;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Array->new;

  my $result = $lvalue->le($rvalue);

  # 0

=back

=over 4

=item le example 2

  package main;

  use Venus::Code;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Code->new;

  my $result = $lvalue->le($rvalue);

  # 1

=back

=over 4

=item le example 3

  package main;

  use Venus::Float;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Float->new;

  my $result = $lvalue->le($rvalue);

  # 0

=back

=over 4

=item le example 4

  package main;

  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Hash->new;

  my $result = $lvalue->le($rvalue);

  # 1

=back

=over 4

=item le example 5

  package main;

  use Venus::Hash;
  use Venus::Number;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Number->new;

  my $result = $lvalue->le($rvalue);

  # 0

=back

=over 4

=item le example 6

  package main;

  use Venus::Hash;
  use Venus::Regexp;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Regexp->new;

  my $result = $lvalue->le($rvalue);

  # 1

=back

=over 4

=item le example 7

  package main;

  use Venus::Hash;
  use Venus::Scalar;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Scalar->new;

  my $result = $lvalue->le($rvalue);

  # 0

=back

=over 4

=item le example 8

  package main;

  use Venus::Hash;
  use Venus::String;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::String->new;

  my $result = $lvalue->le($rvalue);

  # 0

=back

=over 4

=item le example 9

  package main;

  use Venus::Hash;
  use Venus::Undef;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Undef->new;

  my $result = $lvalue->le($rvalue);

  # 0

=back

=cut

=head2 length

  length() (number)

The length method returns the total number of keys defined, and is an alias for
the L</count> method.

I<Since C<0.08>>

=over 4

=item length example 1

  # given: synopsis;

  my $length = $hash->length;

  # 4

=back

=cut

=head2 list

  list() (any)

The list method returns a shallow copy of the underlying hash reference as an
array reference.

I<Since C<0.01>>

=over 4

=item list example 1

  # given: synopsis;

  my $list = $hash->list;

  # 4

=back

=over 4

=item list example 2

  # given: synopsis;

  my @list = $hash->list;

  # (1..8)

=back

=cut

=head2 lt

  lt(any $arg) (boolean)

The lt method performs a I<"lesser-than"> operation using the argument provided.

I<Since C<0.08>>

=over 4

=item lt example 1

  package main;

  use Venus::Array;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Array->new;

  my $result = $lvalue->lt($rvalue);

  # 0

=back

=over 4

=item lt example 2

  package main;

  use Venus::Code;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Code->new;

  my $result = $lvalue->lt($rvalue);

  # 1

=back

=over 4

=item lt example 3

  package main;

  use Venus::Float;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Float->new;

  my $result = $lvalue->lt($rvalue);

  # 0

=back

=over 4

=item lt example 4

  package main;

  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Hash->new;

  my $result = $lvalue->lt($rvalue);

  # 0

=back

=over 4

=item lt example 5

  package main;

  use Venus::Hash;
  use Venus::Number;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Number->new;

  my $result = $lvalue->lt($rvalue);

  # 0

=back

=over 4

=item lt example 6

  package main;

  use Venus::Hash;
  use Venus::Regexp;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Regexp->new;

  my $result = $lvalue->lt($rvalue);

  # 1

=back

=over 4

=item lt example 7

  package main;

  use Venus::Hash;
  use Venus::Scalar;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Scalar->new;

  my $result = $lvalue->lt($rvalue);

  # 0

=back

=over 4

=item lt example 8

  package main;

  use Venus::Hash;
  use Venus::String;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::String->new;

  my $result = $lvalue->lt($rvalue);

  # 0

=back

=over 4

=item lt example 9

  package main;

  use Venus::Hash;
  use Venus::Undef;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Undef->new;

  my $result = $lvalue->lt($rvalue);

  # 0

=back

=cut

=head2 map

  map(coderef $code) (arrayref)

The map method executes callback for each key/value in the hash passing the
routine the value at the current position in the loop and returning a new hash
reference containing the elements for which the argument returns a value or
non-empty list. This method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item map example 1

  # given: synopsis;

  my $map = $hash->map(sub {
    $_ * 2
  });

  # [4, 8, 12, 16]

=back

=over 4

=item map example 2

  # given: synopsis;

  my $map = $hash->map(sub {
    my ($key, $value) = @_;

    [$key, ($value * 2)]
  });

  # [[1, 4], [3, 8], [5, 12], [7, 16]]

=back

=cut

=head2 merge

  merge(hashref @data) (hashref)

The merge method returns a hash reference where the elements in the hash and
the elements in the argument(s) are merged. This operation performs a deep
merge and clones the datasets to ensure no side-effects.

I<Since C<0.01>>

=over 4

=item merge example 1

  # given: synopsis;

  my $merge = $hash->merge({1 => 'a'});

  # { 1 => "a", 3 => 4, 5 => 6, 7 => 8 }

=back

=over 4

=item merge example 2

  # given: synopsis;

  my $merge = $hash->merge({1 => 'a'}, {5 => 'b'});

  # { 1 => "a", 3 => 4, 5 => "b", 7 => 8 }

=back

=cut

=head2 ne

  ne(any $arg) (boolean)

The ne method performs a I<"not-equal-to"> operation using the argument provided.

I<Since C<0.08>>

=over 4

=item ne example 1

  package main;

  use Venus::Array;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Array->new;

  my $result = $lvalue->ne($rvalue);

  # 1

=back

=over 4

=item ne example 2

  package main;

  use Venus::Code;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Code->new;

  my $result = $lvalue->ne($rvalue);

  # 1

=back

=over 4

=item ne example 3

  package main;

  use Venus::Float;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Float->new;

  my $result = $lvalue->ne($rvalue);

  # 1

=back

=over 4

=item ne example 4

  package main;

  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Hash->new;

  my $result = $lvalue->ne($rvalue);

  # 0

=back

=over 4

=item ne example 5

  package main;

  use Venus::Hash;
  use Venus::Number;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Number->new;

  my $result = $lvalue->ne($rvalue);

  # 1

=back

=over 4

=item ne example 6

  package main;

  use Venus::Hash;
  use Venus::Regexp;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Regexp->new;

  my $result = $lvalue->ne($rvalue);

  # 1

=back

=over 4

=item ne example 7

  package main;

  use Venus::Hash;
  use Venus::Scalar;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Scalar->new;

  my $result = $lvalue->ne($rvalue);

  # 1

=back

=over 4

=item ne example 8

  package main;

  use Venus::Hash;
  use Venus::String;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::String->new;

  my $result = $lvalue->ne($rvalue);

  # 1

=back

=over 4

=item ne example 9

  package main;

  use Venus::Hash;
  use Venus::Undef;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Undef->new;

  my $result = $lvalue->ne($rvalue);

  # 1

=back

=cut

=head2 none

  none(coderef $code) (boolean)

The none method returns true if none of the elements in the array meet the
criteria set by the operand and rvalue.

I<Since C<0.01>>

=over 4

=item none example 1

  # given: synopsis;

  my $none = $hash->none(sub {
    $_ < 1
  });

  # 1

=back

=over 4

=item none example 2

  # given: synopsis;

  my $none = $hash->none(sub {
    my ($key, $value) = @_;

    $value < 1
  });

  # 1

=back

=cut

=head2 one

  one(coderef $code) (boolean)

The one method returns true if only one of the elements in the array meet the
criteria set by the operand and rvalue.

I<Since C<0.01>>

=over 4

=item one example 1

  # given: synopsis;

  my $one = $hash->one(sub {
    $_ == 2
  });

  # 1

=back

=over 4

=item one example 2

  # given: synopsis;

  my $one = $hash->one(sub {
    my ($key, $value) = @_;

    $value == 2
  });

  # 1

=back

=cut

=head2 pairs

  pairs() (arrayref)

The pairs method is an alias to the pairs_array method. This method can return
a list of values in list-context.

I<Since C<0.01>>

=over 4

=item pairs example 1

  # given: synopsis;

  my $pairs = $hash->pairs;

  # [[1, 2], [3, 4], [5, 6], [7, 8]]

=back

=cut

=head2 path

  path(string $expr) (any)

The path method traverses the data structure using the path expr provided,
returning the value found or undef. In list-context, this method returns a
tuple, i.e. the value found and boolean representing whether the match was
successful.

I<Since C<0.01>>

=over 4

=item path example 1

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({'foo' => {'bar' => 'baz'},'bar' => ['baz']});

  my $path = $hash->path('/foo/bar');

  # "baz"

=back

=over 4

=item path example 2

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({'foo' => {'bar' => 'baz'},'bar' => ['baz']});

  my $path = $hash->path('/bar/0');

  # "baz"

=back

=over 4

=item path example 3

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({'foo' => {'bar' => 'baz'},'bar' => ['baz']});

  my $path = $hash->path('/bar');

  # ["baz"]

=back

=over 4

=item path example 4

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({'foo' => {'bar' => 'baz'},'bar' => ['baz']});

  my ($path, $exists) = $hash->path('/baz');

  # (undef, 0)

=back

=cut

=head2 puts

  puts(any @args) (arrayref)

The puts method select values from within the underlying data structure using
L<Venus::Hash/path>, optionally assigning the value to the preceeding scalar
reference and returns all the values selected.

I<Since C<3.20>>

=over 4

=item puts example 1

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({
    size => "small",
    fruit => "apple",
    meta => {
      expiry => '5d',
    },
    color => "red",
  });

  my $puts = $hash->puts(undef, 'fruit', undef, 'color');

  # ["apple", "red"]

=back

=over 4

=item puts example 2

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({
    size => "small",
    fruit => "apple",
    meta => {
      expiry => '5d',
    },
    color => "red",
  });

  $hash->puts(\my $fruit, 'fruit', \my $expiry, 'meta.expiry');

  my $puts = [$fruit, $expiry];

  # ["apple", "5d"]

=back

=over 4

=item puts example 3

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({
    size => "small",
    fruit => "apple",
    meta => {
      expiry => '5d',
    },
    color => "red",
  });

  $hash->puts(
    \my $fruit, 'fruit',
    \my $color, 'color',
    \my $expiry, 'meta.expiry',
    \my $ripe, 'meta.ripe',
  );

  my $puts = [$fruit, $color, $expiry, $ripe];

  # ["apple", "red", "5d", undef]

=back

=over 4

=item puts example 4

  package main;

  use Venus::Hash;

  my $hash = Venus::Hash->new({set => [1..20]});

  $hash->puts(
    \my $a, 'set.0',
    \my $b, 'set.1',
    \my $m, ['set', '2:-2'],
    \my $x, 'set.18',
    \my $y, 'set.19',
  );

  my $puts = [$a, $b, $m, $x, $y];

  # [1, 2, [3..18], 19, 20]

=back

=cut

=head2 random

  random() (any)

The random method returns a random element from the array.

I<Since C<0.01>>

=over 4

=item random example 1

  # given: synopsis;

  my $random = $hash->random;

  # 6

  # my $random = $hash->random;

  # 4

=back

=cut

=head2 reset

  reset() (arrayref)

The reset method returns nullifies the value of each element in the hash.

I<Since C<0.01>>

=over 4

=item reset example 1

  # given: synopsis;

  my $reset = $hash->reset;

  # { 1 => undef, 3 => undef, 5 => undef, 7 => undef }

=back

=cut

=head2 reverse

  reverse() (hashref)

The reverse method returns a hash reference consisting of the hash's keys and
values inverted. Note, keys with undefined values will be dropped.

I<Since C<0.01>>

=over 4

=item reverse example 1

  # given: synopsis;

  my $reverse = $hash->reverse;

  # { 2 => 1, 4 => 3, 6 => 5, 8 => 7 }

=back

=cut

=head2 slice

  slice(string @keys) (arrayref)

The slice method returns an array reference of the values that correspond to
the key(s) specified in the arguments.

I<Since C<0.01>>

=over 4

=item slice example 1

  # given: synopsis;

  my $slice = $hash->slice(1, 3);

  # [2, 4]

=back

=cut

=head2 tv

  tv(any $arg) (boolean)

The tv method performs a I<"type-and-value-equal-to"> operation using argument
provided.

I<Since C<0.08>>

=over 4

=item tv example 1

  package main;

  use Venus::Array;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Array->new;

  my $result = $lvalue->tv($rvalue);

  # 0

=back

=over 4

=item tv example 2

  package main;

  use Venus::Code;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Code->new;

  my $result = $lvalue->tv($rvalue);

  # 0

=back

=over 4

=item tv example 3

  package main;

  use Venus::Float;
  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Float->new;

  my $result = $lvalue->tv($rvalue);

  # 0

=back

=over 4

=item tv example 4

  package main;

  use Venus::Hash;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Hash->new;

  my $result = $lvalue->tv($rvalue);

  # 1

=back

=over 4

=item tv example 5

  package main;

  use Venus::Hash;
  use Venus::Number;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Number->new;

  my $result = $lvalue->tv($rvalue);

  # 0

=back

=over 4

=item tv example 6

  package main;

  use Venus::Hash;
  use Venus::Regexp;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Regexp->new;

  my $result = $lvalue->tv($rvalue);

  # 0

=back

=over 4

=item tv example 7

  package main;

  use Venus::Hash;
  use Venus::Scalar;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Scalar->new;

  my $result = $lvalue->tv($rvalue);

  # 0

=back

=over 4

=item tv example 8

  package main;

  use Venus::Hash;
  use Venus::String;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::String->new;

  my $result = $lvalue->tv($rvalue);

  # 0

=back

=over 4

=item tv example 9

  package main;

  use Venus::Hash;
  use Venus::Undef;

  my $lvalue = Venus::Hash->new;
  my $rvalue = Venus::Undef->new;

  my $result = $lvalue->tv($rvalue);

  # 0

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