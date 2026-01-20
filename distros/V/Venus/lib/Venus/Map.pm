package Venus::Map;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Mappable';
with 'Venus::Role::Encaseable';

# ATTRIBUTES

attr 'accept';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    value => $data,
  };
}

sub build_args {
  my ($self, $data) = @_;

  if (keys %$data == 1 && exists $data->{value}) {
    return $data;
  }
  elsif (keys %$data == 1 && exists $data->{accept}) {
    return $data;
  }
  elsif (keys %$data == 2 && exists $data->{accept} && exists $data->{value}) {
    return $data;
  }
  else {
    return {
      value => $data,
    };
  }

  return $data;
}

sub build_self {
  my ($self, $data) = @_;

  $self->{accept} ||= 'any';

  my $value = delete $self->{value};

  $self->push(%$value) if ref $value eq 'HASH';

  return $self;
}

# METHODS

sub all {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $failed = 0;

  my $keys = $self->keys;

  for my $key (@$keys) {
    my $value = $data->{$key};

    local $_ = $value;
    $failed++ if !$code->($key, $value);

    CORE::last if $failed;
  }

  return $failed ? false : true;
}

sub any {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $keys = $self->keys;

  my $found = 0;

  for my $key (@$keys) {
    my $value = $data->{$key};

    local $_ = $value;
    $found++ if $code->($key, $value);

    CORE::last if $found;
  }

  return $found ? true : false;
}

sub attest {
  my ($self) = @_;

  require Venus::Assert;

  my $assert = Venus::Assert->new;

  my $accept = $self->accept;

  $assert->expression("within[hashref, $accept]");

  return $assert->result($self->get);
}

sub call {
  my ($self, $mapper, $method, @args) = @_;

  require Venus::What;

  return $self->$mapper(sub{
    my ($key, $val) = @_;

    my $what = Venus::What->new($val)->deduce;

    local $_ = $what;

    $what->$method(@args)
  });
}

sub contains {
  my ($self, $value) = @_;

  my $data = $self->get;

  if (CORE::grep({$value eq $_} CORE::values(%{$data}))) {
    return true;
  }

  my $value_to_object = $self->value_to_object($value);

  my $value_to_refaddr = $self->value_to_refaddr($value_to_object);
  my $index_by_refaddr = $self->index_by_refaddr;

  if (exists $index_by_refaddr->{$value_to_refaddr}) {
    return true;
  }

  return false;
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
  my ($self, $index) = @_;

  return $self->remove($index);
}

sub difference {
  my ($self, $data) = @_;

  require Venus;
  require Scalar::Util;

  my $set = $self->class->new;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Map')) {
    $set->push(@$_) for grep !$self->contains($$_[1]), $data->pairs;
  }
  elsif (Scalar::Util::blessed($data) && $data->isa('Venus::Hash')) {
    $set->push(@$_) for grep !$self->contains($$_[1]), $data->pairs;
  }
  elsif (ref($data) eq 'HASH') {
    $set->push(@$_) for grep !$self->contains($$_[1]), Venus::pairs($data);
  }

  return $set;
}

sub different {
  my ($self, $data) = @_;

  my $set = $self->difference($data);

  return $set->count ? true : false;
}

sub each {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $keys = $self->keys;

  my $result = [];

  for my $key (@{$keys}) {
    my $value = $data->{$key};

    local $_ = $value;
    CORE::push(@$result, $code->($key, $value));
  }

  return wantarray ? (@$result) : $result;
}

sub empty {
  my ($self) = @_;

  $self->reset;

  return $self;
}

sub exists {
  my ($self, $index) = @_;

  my $index_by_index = $self->index_by_index;

  return exists $index_by_index->{$index} ? true : false;
}

sub first {
  my ($self) = @_;

  my $index = $self->keys->[0];

  return $self->get($index);
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

  my $keys = $self->keys;

  my $result = [];

  for my $key (@$keys) {
    my $value = $data->{$key};

    local $_ = $value;
    CORE::push(@$result, $value) if $code->($key, $value);
  }

  return wantarray ? (@$result) : $result;
}

sub head {
  my ($self, $size) = @_;

  my $pairs = $self->pairs;

  $size = !$size ? 1 : $size > @$pairs ? @$pairs : $size;

  my $index = $size - 1;

  return [CORE::map($$_[1], @{$pairs}[0..$index])];
}

sub index {
  my ($self) = @_;

  my $index = $self->encase('index', {});

  return $index;
}

sub index_by_deduced {
  my ($self) = @_;

  my $deduced = $self->index->{deduced} ||= {};

  return $deduced;
}

sub index_by_index {
  my ($self) = @_;

  my $index = $self->index->{index} ||= {};

  return $index;
}

sub index_by_names {
  my ($self) = @_;

  my $names = $self->index->{names} ||= {};

  return $names;
}

sub index_by_order {
  my ($self) = @_;

  my $order = $self->index->{order} ||= {};

  return $order;
}

sub index_by_refaddr {
  my ($self) = @_;

  my $refaddr = $self->index->{refaddr} ||= {};

  return $refaddr;
}

sub insert {
  my ($self, $name, $value) = @_;

  my $value_to_deduced = $self->value_to_deduced($value);
  my $value_to_object = $self->value_to_object($value);

  my $index_by_deduced = $self->index_by_deduced;
  my $index_by_index = $self->index_by_index;
  my $index_by_names = $self->index_by_names;
  my $index_by_refaddr = $self->index_by_refaddr;
  my $index_by_order = $self->index_by_order;

  my $value_to_refaddr = $self->value_to_refaddr($value_to_object);

  if (!exists $index_by_index->{$name}) {
    my $index = int keys %{$index_by_order};
    $index_by_index->{$name} = $index;
    $index_by_order->{$index} = $name;
  }
  else {
    my $old_value_to_refaddr
      = $self->value_to_refaddr($index_by_names->{$name});
    delete $index_by_refaddr->{$old_value_to_refaddr}
      if $old_value_to_refaddr && $old_value_to_refaddr ne $value_to_refaddr;
  }

  $index_by_refaddr->{$value_to_refaddr} = $name;
  $index_by_deduced->{$name} = $value_to_deduced;
  $index_by_names->{$name} = $value_to_object;

  return $value_to_object;
}

sub iterator {
  my ($self) = @_;

  my $pairs = $self->pairs;

  my $i = 0;

  return sub {
    return undef if $i > $#{$pairs};
    return wantarray ? (@{$pairs->[$i++]}) : $pairs->[$i++][1];
  }
}

sub intersection {
  my ($self, $data) = @_;

  require Scalar::Util;

  my $set = $self->class->new;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Map')) {
    $set->push(@$_) for grep $self->contains($$_[1]), $data->pairs;
  }
  elsif (Scalar::Util::blessed($data) && $data->isa('Venus::Hash')) {
    $set->push(@$_) for grep $self->contains($$_[1]), $data->pairs;
  }
  elsif (ref($data) eq 'HASH') {
    $set->push(@$_) for grep $self->contains($$_[1]), Venus::pairs($data);
  }

  return $set;
}

sub intersect {
  my ($self, $data) = @_;

  my $set = $self->intersection($data);

  return $set->count ? true : false;
}

sub join {
  my ($self, $delimiter) = @_;

  my $pairs = $self->pairs;

  return CORE::join($delimiter // '', map $$_[1], @{$pairs});
}

sub keys {
  my ($self) = @_;

  my $index_by_order = $self->index_by_order;

  return [CORE::map($index_by_order->{$_},
    CORE::sort(CORE::keys(%{$index_by_order})))];
}

sub last {
  my ($self) = @_;

  my $index = $self->keys->[-1];

  return $self->get($index);
}

sub length {
  my ($self) = @_;

  return $self->count;
}

sub list {
  my ($self) = @_;

  return wantarray ? (map $$_[1], @{$self->pairs}) : $self->count;
}

sub map {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $keys = $self->keys;

  my $result = [];

  for my $key (@$keys) {
    my $value = $data->{$key};

    local $_ = $value;
    CORE::push(@$result, $code->($key, $value));
  }

  return wantarray ? (@$result) : $result;
}

sub merge {
  my ($self, @data) = @_;

  require Scalar::Util;

  if (@data == 1
    && Scalar::Util::blessed($data[0])
    && ($data[0]->isa('Venus::Map') || $data[0]->isa('Venus::Hash')))
  {
    @data = map +(@$_), $data[0]->pairs;
  }

  $self->push(@data);

  return $self;
}

sub none {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $keys = $self->keys;

  my $found = 0;

  for my $key (@{$keys}) {
    my $value = $data->{$key};

    local $_ = $value;
    $found++ if $code->($key, $value);

    CORE::last if $found;
  }

  return $found ? false : true;
}

sub object_to_value {
  my ($self, $value) = @_;

  require Venus::What;

  return Venus::What->new($value)->detract;
}

sub one {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $keys = $self->keys;

  my $found = 0;

  for my $key (@{$keys}) {
    my $value = $data->{$key};

    local $_ = $value;
    $found++ if $code->($key, $value);

    CORE::last if $found > 1;
  }

  return $found == 1 ? true : false;
}

sub order {
  my ($self, @args) = @_;

  return $self if !@args;

  my $pairs = $self->pairs;

  my $index_by_index = $self->index_by_index;

  @args = map $index_by_index->{$_}, @args;

  $self->reset;

  my %seen = ();

  @$pairs = (map $pairs->[$_], grep !$seen{$_}++, (@args), 0..$#{$pairs});

  $self->insert(@$_) for @$pairs;

  return $self;
}

sub pairs {
  my ($self) = @_;

  my $index_by_deduced = $self->index_by_deduced;
  my $index_by_names = $self->index_by_names;
  my $index_by_order = $self->index_by_order;

  my $result = [
    CORE::map([
        $index_by_order->{$_},
        $index_by_deduced->{$index_by_order->{$_}}
        ? $self->object_to_value($index_by_names->{$index_by_order->{$_}})
        : $index_by_names->{$index_by_order->{$_}}
      ],
      CORE::sort(CORE::keys(%{$index_by_order})))
  ];

  return wantarray ? (@$result) : $result;
}

sub part {
  my ($self, $code) = @_;

  my $data = $self->get;

  my $results = [{}, {}];

  my $keys = $self->keys;

  for my $key (@{$keys}) {
    my $value = $data->{$key};
    local $_ = $value;
    my $result = $code->($key, $value);
    my $slot = $result ? $$results[0] : $$results[1];

    $slot->{$key} = $value;
  }

  return wantarray ? (@$results) : $results;
}

sub pop {
  my ($self) = @_;

  my $index = $self->keys->[-1];

  return $self->remove($index);
}

sub push {
  my ($self, @args) = @_;

  require Venus;

  @args = Venus::flat(@args);

  for (my $i = 0; $i < @args; $i += 2) {
    $self->insert($args[$i], $args[$i+1] // undef);
  }

  return $self->get;
}

sub random {
  my ($self) = @_;

  my $pairs = $self->pairs;

  return (@$pairs[rand($#{$pairs}+1)])->[1];
}

sub range {
  my ($self, @args) = @_;

  return $self->slice(@args) if @args > 1;

  my ($note) = @args;

  return $self->slice if !defined $note;

  require Venus::Range;

  return scalar Venus::Range->parse($note, [map $$_[1], @{$self->pairs}])->select;
}

sub remove {
  my ($self, $name) = @_;

  my $index_by_deduced = $self->index_by_deduced;
  my $index_by_index = $self->index_by_index;
  my $index_by_names = $self->index_by_names;
  my $index_by_refaddr = $self->index_by_refaddr;
  my $index_by_order = $self->index_by_order;

  return undef if !exists $index_by_names->{$name};

  my $value_to_object = delete $index_by_names->{$name};
  my $value_to_deduced = delete $index_by_deduced->{$name};

  my $value_to_refaddr = $self->value_to_refaddr($value_to_object);

  delete $index_by_order->{delete $index_by_index->{$name}};
  delete $index_by_refaddr->{$value_to_refaddr};

  my $point = 0;

  for my $index (CORE::sort(CORE::keys(%{$index_by_order}))) {
    if ($index != $point) {
      $index_by_order->{$point} = delete $index_by_order->{$index};
      $index_by_index->{$index_by_order->{$point}} = $point;
    }
    $point++;
  }

  return $value_to_deduced
    ? $self->object_to_value($value_to_object)
    : $value_to_object;
}

sub reset {
  my ($self, @data) = @_;

  $self->uncase('index');

  $self->insert($_) for @data;

  return $self;
}

sub reverse {
  my ($self) = @_;

  my $keys = $self->keys;

  $self->order(CORE::reverse(@{$keys}));

  my $pairs = $self->pairs;

  return [CORE::map($$_[1], @{$pairs})];
}

sub rotate {
  my ($self) = @_;

  my $pairs = $self->pairs;

  $self->reset;

  CORE::push(@$pairs, CORE::shift(@$pairs));

  $self->insert(@$_) for @$pairs;

  return [CORE::map($$_[1], @{$pairs})];
}

sub rsort {
  my ($self) = @_;

  my $pairs = $self->pairs;

  return [CORE::sort { $b cmp $a } CORE::map $$_[1], @{$pairs}];
}

sub set {
  my ($self, @args) = @_;

  return $self->value if !@args;

  return $self->push(@args);
}

sub shift {
  my ($self) = @_;

  my $index = $self->keys->[0];

  my $result = $self->remove($index);

  return $result;
}

sub shuffle {
  my ($self) = @_;

  my $pairs = $self->pairs;

  my $result = [CORE::map $$_[1], @{$pairs}];

  for my $index (0..$#$result) {
    my $other = int(rand(@$result));
    my $stash = $result->[$index];
    $result->[$index] = $result->[$other];
    $result->[$other] = $stash;
  }

  return $result;
}

sub slice {
  my ($self, @args) = @_;

  my $pairs = $self->pairs;

  return [map $$_[1], @$pairs[@args]];
}

sub sort {
  my ($self) = @_;

  my $pairs = $self->pairs;

  return [CORE::sort { $a cmp $b } CORE::map $$_[1], @{$pairs}];
}

sub subset {
  my ($self, $data) = @_;

  require Scalar::Util;

  my $set = $self->class->new;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Map')) {
    $set->push(@$_) for grep $self->contains($$_[1]), $data->pairs;
    return true if $data->count == $set->count;
  }
  elsif (Scalar::Util::blessed($data) && $data->isa('Venus::Hash')) {
    $set->push(@$_) for grep $self->contains($$_[1]), $data->pairs;
    return true if $data->count == $set->count;
  }
  elsif (ref($data) eq 'HASH') {
    $set->push(@$_) for grep $self->contains($$_[1]), Venus::pairs($data);
    return true if CORE::keys(%$data) == $set->count;
  }

  return false;
}

sub superset {
  my ($self, $data) = @_;

  require Scalar::Util;

  my $set = $self->class->new;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Map')) {
    $set->push(@$_) for grep !$data->contains($$_[1]), $self->pairs;
    return false if $set->count || $data->count <= $self->count;;
  }
  elsif (Scalar::Util::blessed($data) && $data->isa('Venus::Hash')) {
    my $temp = $self->class->new($data->get);
    $set->push(@$_) for grep !$temp->contains($$_[1]), $self->pairs;
    return false if $set->count || $temp->count <= $self->count;
  }
  elsif (ref($data) eq 'HASH') {
    my $temp = $self->class->new($data);
    $set->push(@$_) for grep !$temp->contains($$_[1]), $self->pairs;
    return false if $set->count || $temp->count <= $self->count;
  }

  return true;
}

sub tail {
  my ($self, $size) = @_;

  my $pairs = $self->pairs;

  $size = !$size ? 1 : $size > @$pairs ? @$pairs : $size;

  my $index = $#$pairs - ($size - 1);

  return [CORE::map($$_[1], @{$pairs}[$index..$#$pairs])];
}

sub unshift {
  my ($self, @args) = @_;

  my @keys;

  require Venus;

  @args = Venus::flat(@args);

  for (my $i = 0; $i < @args; $i += 2) {
    CORE::push(@keys, $args[$i]);
    $self->insert($args[$i], $args[$i+1] // undef);
  }

  $self->order(@keys);

  return $self->get;
}

sub value {
  my ($self) = @_;

  my $results = {};

  my $index_by_deduced = $self->index_by_deduced;
  my $index_by_order = $self->index_by_order;
  my $index_by_names = $self->index_by_names;

  for my $index (CORE::sort(CORE::keys(%{$index_by_order}))) {
    my $name = $index_by_order->{$index};
    my $deduced = $index_by_deduced->{$name};
    my $value = $index_by_names->{$name};
    $results->{$name} = $deduced ? $self->object_to_value($value) : $value;
  }

  return $results;
}

sub value_to_deduced {
  my ($self, $value) = @_;

  require Scalar::Util;

  return Scalar::Util::blessed($value) ? false : true;
}

sub value_to_object {
  my ($self, $value) = @_;

  require Venus::What;

  return Venus::What->new($value)->deduce;
}

sub value_to_refaddr {
  my ($self, $value) = @_;

  require Scalar::Util;

  return Scalar::Util::refaddr($value);
}

sub values {
  my ($self) = @_;

  my $results = [];

  my $index_by_deduced = $self->index_by_deduced;
  my $index_by_order = $self->index_by_order;
  my $index_by_names = $self->index_by_names;

  for my $index (CORE::sort(CORE::keys(%{$index_by_order}))) {
    my $name = $index_by_order->{$index};
    my $deduced = $index_by_deduced->{$name};
    my $value = $index_by_names->{$name};
    CORE::push(@{$results}, $deduced ? $self->object_to_value($value) : $value);
  }

  return $results;
}

1;



=head1 NAME

Venus::Map - Map Class

=cut

=head1 ABSTRACT

Map Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Map;

  my $map = Venus::Map->new({1..8});

  # $map->count;

  # 4

=cut

=head1 DESCRIPTION

This package provides a representation of a collection of ordered key/value
pairs and methods for validating and manipulating it.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 accept

  accept(string $data) (string)

The accept attribute is read-write, accepts C<(string)> values, and is
optional.

I<Since C<4.11>>

=over 4

=item accept example 1

  # given: synopsis

  package main;

  my $map_accept = $map->accept("number");

  # "number"

=back

=over 4

=item accept example 2

  # given: synopsis

  # given: example-1 accept

  package main;

  my $get_accept = $map->accept;

  # "number"

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Mappable>

L<Venus::Role::Encaseable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 all

  all(coderef $code) (boolean)

The all method returns true if the callback returns true for all of the
elements.

I<Since C<4.11>>

=over 4

=item all example 1

  # given: synopsis;

  my $all = $map->all(sub {
    $_ > 0;
  });

  # 1

=back

=over 4

=item all example 2

  # given: synopsis;

  my $all = $map->all(sub {
    my ($key, $value) = @_;

    $value > 0;
  });

  # 1

=back

=cut

=head2 any

  any(coderef $code) (boolean)

The any method returns true if the callback returns true for any of the
elements.

I<Since C<4.11>>

=over 4

=item any example 1

  # given: synopsis;

  my $any = $map->any(sub {
    $_ > 4;
  });

=back

=over 4

=item any example 2

  # given: synopsis;

  my $any = $map->any(sub {
    my ($key, $value) = @_;

    $value > 4;
  });

=back

=cut

=head2 attest

  attest() (any)

The attest method validates the values using the L<Venus::Assert> expression in
the L</accept> attribute and returns the result.

I<Since C<4.11>>

=over 4

=item attest example 1

  # given: synopsis

  package main;

  my $attest = $map->attest;

  # {1..8}

=back

=over 4

=item attest example 2

  # given: synopsis

  package main;

  $map->accept('number | object');

  my $attest = $map->attest;

  # {1..8}

=back

=over 4

=item attest example 3

  # given: synopsis

  package main;

  $map->accept('string');

  my $attest = $map->attest;

  # Exception! (isa Venus::Check::Error)

=back

=over 4

=item attest example 4

  # given: synopsis

  package main;

  $map->accept('number');

  my $attest = $map->attest;

  # {1..8}

=back

=cut

=head2 call

  call(string $iterable, string $method) (any)

The call method executes the given method (named using the first argument)
which performs an iteration (i.e. takes a callback) and calls the method (named
using the second argument) on the object (or value) and returns the result of
the iterable method.

I<Since C<4.11>>

=over 4

=item call example 1

  package main;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $call = $map->call('map', 'incr');

  # [3,5,7,9]

=back

=over 4

=item call example 2

  package main;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $call = $map->call('grep', 'gt', 4);

  # [6,8]

=back

=cut

=head2 contains

  contains(any $value) (boolean)

The contains method returns true if the value provided already exists in the
map, otherwise it returns false.

I<Since C<4.11>>

=over 4

=item contains example 1

  # given: synopsis;

  my $contains = $map->contains(2);

  # true

=back

=over 4

=item contains example 2

  # given: synopsis;

  my $contains = $map->contains(0);

  # false

=back

=cut

=head2 count

  count() (number)

The count method returns the number of elements within the map.

I<Since C<4.11>>

=over 4

=item count example 1

  # given: synopsis;

  my $count = $map->count;

  # 9

=back

=cut

=head2 default

  default() (hashref)

The default method returns the default value, i.e. C<{}>.

I<Since C<4.11>>

=over 4

=item default example 1

  # given: synopsis;

  my $default = $map->default;

  # {}

=back

=cut

=head2 delete

  delete(string $key) (any)

The delete method returns the value of the element corresponding to the key specified after
removing it from the map.

I<Since C<4.11>>

=over 4

=item delete example 1

  # given: synopsis;

  my $delete = $map->delete(1);

  # 2

=back

=cut

=head2 difference

  difference(hashref | Venus::Hash | Venus::Map $data) (Venus::Map)

The difference method returns a new map containing only the values that don't
exist in the source.

I<Since C<4.11>>

=over 4

=item difference example 1

  # given: synopsis

  package main;

  my $difference = $map->difference({7..10});

  # bless(..., "Venus::Map")

  # $difference->list;

  # [10]

=back

=over 4

=item difference example 2

  # given: synopsis

  package main;

  my $difference = $map->difference(Venus::Map->new({7,8,9,10,11,12}));

  # bless(..., "Venus::Map")

  # $difference->list;

  # [10, 12]

=back

=over 4

=item difference example 3

  # given: synopsis

  package main;

  use Venus::Hash;

  my $difference = $map->difference(Venus::Hash->new({7,8,9,10,11,12}));

  # bless(..., "Venus::Map")

  # $difference->list;

  # [10, 12]

=back

=cut

=head2 different

  different(hashref | Venus::Hash | Venus::Map $data) (boolean)

The different method returns true if the values provided don't exist in the
source.

I<Since C<4.11>>

=over 4

=item different example 1

  # given: synopsis

  package main;

  my $different = $map->different({1..10});

  # true

=back

=over 4

=item different example 2

  # given: synopsis

  package main;

  my $different = $map->different({1..8});

  # false

=back

=cut

=head2 each

  each(coderef $code) (hashref)

The each method executes a callback for each element in the map passing the
key and value as arguments. This method can return a list of values in
list-context.

I<Since C<4.11>>

=over 4

=item each example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $each = $map->each(sub {
    [$_]
  });

  # [[2], [4], [6], [8]]

=back

=over 4

=item each example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(8,7,6,5,4,3,2,1);

  my $each = $map->each(sub {
    my ($key, $value) = @_;

    [$key, $value]
  });

  # [
  #   [8, 7],
  #   [6, 5],
  #   [4, 3],
  #   [2, 1],
  # ]

=back

=cut

=head2 empty

  empty() (Venus::Hash)

The empty method drops all elements from the map.

I<Since C<4.11>>

=over 4

=item empty example 1

  # given: synopsis;

  my $empty = $map->empty;

  # bless({}, "Venus::Map")

=back

=cut

=head2 exists

  exists(string $key) (boolean)

The exists method returns true if the element corresponding with the key
specified exists, otherwise it returns false.

I<Since C<4.11>>

=over 4

=item exists example 1

  # given: synopsis;

  my $exists = $map->exists(1);

  # true

=back

=cut

=head2 first

  first() (any)

The first method returns the value of the first element.

I<Since C<4.11>>

=over 4

=item first example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $first = $map->first;

  # 2

=back

=over 4

=item first example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(8,7,6,5,4,3,2,1);

  my $first = $map->first;

  # 7

=back

=cut

=head2 get

  get(string $key) (any)

The get method returns the value at the position specified.

I<Since C<4.11>>

=over 4

=item get example 1

  # given: synopsis

  package main;

  my $get = $map->get(1);

  # 2

=back

=over 4

=item get example 2

  # given: synopsis

  package main;

  my $get = $map->get(3);

  # 4

=back

=cut

=head2 grep

  grep(coderef $code) (hashref)

The grep method executes a callback for each element in the array passing the
value as an argument, returning a new array reference containing the elements
for which the returned true. This method can return a list of values in
list-context.

I<Since C<4.11>>

=over 4

=item grep example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $grep = $map->grep(sub {
    $_ > 4
  });

  # [6,8]

=back

=over 4

=item grep example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $grep = $map->grep(sub {
    my ($key, $value) = @_;

    $value > 4
  });

  # [6,8]

=back

=cut

=head2 head

  head(number $size) (hashref)

The head method returns the topmost elements, limited by the desired size
specified.

I<Since C<4.11>>

=over 4

=item head example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head;

  # [2]

=back

=over 4

=item head example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head(1);

  # [2]

=back

=over 4

=item head example 3

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head(2);

  # [2,4]

=back

=over 4

=item head example 4

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head(5);

  # [2,4,6,8]

=back

=over 4

=item head example 5

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head(20);

  # [2,4,6,8]

=back

=cut

=head2 intersect

  intersect(hashref | Venus::Hash | Venus::Map $data) (boolean)

The intersect method returns true if the values provided already exist in the
source.

I<Since C<4.11>>

=over 4

=item intersect example 1

  # given: synopsis

  package main;

  my $intersect = $map->intersect({7,8});

  # true

=back

=over 4

=item intersect example 2

  # given: synopsis

  package main;

  my $intersect = $map->intersect({9,10});

  # false

=back

=cut

=head2 intersection

  intersection(hashref | Venus::Hash | Venus::Map $data) (Venus::Map)

The intersection method returns a new map containing only the values that
already exist in the source.

I<Since C<4.11>>

=over 4

=item intersection example 1

  # given: synopsis

  package main;

  $map->push(9,10);

  my $intersection = $map->intersection({9,10,11,12});

  # bless(..., "Venus::Map")

  # $intersection->list;

  # [10]

=back

=over 4

=item intersection example 2

  # given: synopsis

  package main;

  $map->push(9,10);

  my $intersection = $map->intersection(Venus::Map->new({9,10,11,12}));

  # bless(..., "Venus::Map")

  # $intersection->list;

  # [10]

=back

=over 4

=item intersection example 3

  # given: synopsis

  package main;

  use Venus::Hash;

  $map->push(9,10);

  my $intersection = $map->intersection(Venus::Hash->new({9,10,11,12}));

  # bless(..., "Venus::Map")

  # $intersection->list;

  # [10]

=back

=cut

=head2 iterator

  iterator() (coderef)

The iterator method returns a code reference which can be used to iterate over
the array. Each time the iterator is executed it will return the next element
in the array until all elements have been seen, at which point the iterator
will return an undefined value. This method can return a tuple with the key and
value in list-context.

I<Since C<4.11>>

=over 4

=item iterator example 1

  # given: synopsis;

  my $iterator = $map->iterator;

  # sub { ... }

  # while (my $value = $iterator->()) {
  #   say $value; # 1
  # }

=back

=over 4

=item iterator example 2

  # given: synopsis;

  my $iterator = $map->iterator;

  # sub { ... }

  # while (grep defined, my ($key, $value) = $iterator->()) {
  #   say $value; # 1
  # }

=back

=cut

=head2 join

  join(string $seperator) (string)

The join method returns a string consisting of all the elements in the array
joined by the join-string specified by the argument. Note: If the argument is
omitted, an empty string will be used as the join-string.

I<Since C<4.11>>

=over 4

=item join example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $join = $map->join;

  # 2468

=back

=over 4

=item join example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $join = $map->join(', ');

  # "2, 4, 6, 8"

=back

=cut

=head2 keys

  keys() (hashref)

The keys method returns an array reference consisting of the indicies of the
array.

I<Since C<4.11>>

=over 4

=item keys example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $keys = $map->keys;

  # [1,3,5,7]

=back

=cut

=head2 last

  last() (any)

The last method returns the value of the last element in the array.

I<Since C<4.11>>

=over 4

=item last example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $last = $map->last;

  # 8

=back

=cut

=head2 length

  length() (number)

The length method returns the number of elements within the array, and is an
alias for the L</count> method.

I<Since C<4.11>>

=over 4

=item length example 1

  # given: synopsis;

  my $length = $map->length;

  # 4

=back

=cut

=head2 list

  list() (any)

The list method returns a shallow copy of the underlying array reference as an
array reference.

I<Since C<4.11>>

=over 4

=item list example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $list = $map->list;

  # 4

=back

=over 4

=item list example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my @list = $map->list;

  # (2,4,6,8)

=back

=cut

=head2 map

  map(coderef $code) (hashref)

The map method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing the
elements for which the argument returns a value or non-empty list. This method
can return a list of values in list-context.

I<Since C<4.11>>

=over 4

=item map example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $result = $map->map(sub {
    $_ * 2
  });

  # [4,8,12,16]

=back

=over 4

=item map example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $result = $map->map(sub {
    my ($key, $value) = @_;

    [$key, ($value * 2)]
  });

  # [
  #   [1, 4],
  #   [3, 8],
  #   [5, 12],
  #   [7, 16],
  # ]

=back

=cut

=head2 merge

  merge(any @data) (Venus::Map)

The merge method merges the arguments provided with the existing map.

I<Since C<4.11>>

=over 4

=item merge example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $merge = $map->merge(7..10);

  # bless(..., "Venus::Map")

  # $map->list;

  # [2,4,6,8,10]

=back

=over 4

=item merge example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $merge = $map->merge(Venus::Map->new->do('set', 5..10));

  # bless(..., "Venus::Map")

  # $map->list;

  # [2,4,6,8,10]

=back

=cut

=head2 new

  new(any @args) (Venus::Map)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Map;

  my $new = Venus::Map->new;

  # bless(..., "Venus::Map")

=back

=over 4

=item new example 2

  package main;

  use Venus::Map;

  my $new = Venus::Map->new({1..8});

  # bless(..., "Venus::Map")

=back

=over 4

=item new example 3

  package main;

  use Venus::Map;

  my $new = Venus::Map->new(value => {1..8});

  # bless(..., "Venus::Map")

=back

=cut

=head2 none

  none(coderef $code) (boolean)

The none method returns true if none of the elements in the array meet the
criteria set by the operand and rvalue.

I<Since C<4.11>>

=over 4

=item none example 1

  # given: synopsis;

  my $none = $map->none(sub {
    $_ < 1
  });

  # 1

=back

=over 4

=item none example 2

  # given: synopsis;

  my $none = $map->none(sub {
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

I<Since C<4.11>>

=over 4

=item one example 1

  # given: synopsis;

  my $one = $map->one(sub {
    $_ == 2
  });

  # 1

=back

=over 4

=item one example 2

  # given: synopsis;

  my $one = $map->one(sub {
    my ($key, $value) = @_;

    $value == 2
  });

  # 1

=back

=cut

=head2 order

  order(number @indices) (Venus::Map)

The order method reorders the array items based on the indices provided and
returns the invocant.

I<Since C<4.11>>

=over 4

=item order example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $order = $map->order;

  # bless(..., "Venus::Map")

  # $map->keys;

  # [1,3,5,7]

=back

=over 4

=item order example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $order = $map->order(5,3);

  # bless(..., "Venus::Map")

  # $map->keys;

  # [5,3,1,7]

=back

=over 4

=item order example 3

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $order = $map->order(7);

  # bless(..., "Venus::Map")

  # $map->keys;

  # [7,1,3,5]

=back

=cut

=head2 pairs

  pairs() (hashref)

The pairs method is an alias to the pairs_array method. This method can return
a list of values in list-context.

I<Since C<4.11>>

=over 4

=item pairs example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $pairs = $map->pairs;

  # [
  #   [1, 2],
  #   [3, 4],
  #   [5, 6],
  #   [7, 8],
  # ]

=back

=cut

=head2 part

  part(coderef $code) (tuple[hashref, hashref])

The part method iterates over each element in the array, executing the code
reference supplied in the argument, using the result of the code reference to
partition to array into two distinct array references. This method can return a
list of values in list-context.

I<Since C<4.11>>

=over 4

=item part example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $part = $map->part(sub {
    $_ > 4
  });

  # [{5..8}, {1..4}]

=back

=over 4

=item part example 2

  # given: synopsis;

  my $part = $map->part(sub {
    my ($key, $value) = @_;

    $value < 5
  });

  # [{1..4}, {5..8}]

=back

=cut

=head2 pop

  pop() (any)

The pop method returns the last element of the array shortening it by one.
Note, this method modifies the array.

I<Since C<4.11>>

=over 4

=item pop example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $pop = $map->pop;

  # 8

=back

=cut

=head2 push

  push(any @data) (hashref)

The push method appends the array by pushing the agruments onto it and returns
itself.

I<Since C<4.11>>

=over 4

=item push example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $push = $map->push(9,10);

  # {1..10}

=back

=cut

=head2 random

  random() (any)

The random method returns a random element from the array.

I<Since C<4.11>>

=over 4

=item random example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $random = $map->random;

  # 2

  # my $random = $map->random;

  # 1

=back

=cut

=head2 range

  range(number | string @args) (hashref)

The range method accepts a I<"range expression"> and returns the result of
calling the L</slice> method with the computed range.

I<Since C<4.11>>

=over 4

=item range example 1

  # given: synopsis

  package main;

  my $range = $map->range;

  # []

=back

=over 4

=item range example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range(0);

  # [2]

=back

=over 4

=item range example 3

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('0:');

  # [2,4,6,8]

=back

=over 4

=item range example 4

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range(':2');

  # [2,4,6]

=back

=over 4

=item range example 5

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('3:');

  # [8]

=back

=over 4

=item range example 6

  # given: synopsis

  package main;

  my $range = $map->range('4:');

  # []

=back

=over 4

=item range example 7

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('0:1');

  # [2,4]

=back

=over 4

=item range example 8

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('2:4');

  # [6,8]

=back

=over 4

=item range example 9

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range(0..2);

  # [2,4,6]

=back

=over 4

=item range example 10

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('-1:3');

  # [8]

=back

=over 4

=item range example 11

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('0:4');

  # [2,4,6,8]

=back

=over 4

=item range example 12

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('0:-2');

  # [2,4,6]

=back

=over 4

=item range example 13

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('-2:-2');

  # [6]

=back

=over 4

=item range example 14

  # given: synopsis

  package main;

  my $range = $map->range('0:-20');

  # []

=back

=over 4

=item range example 15

  # given: synopsis

  package main;

  my $range = $map->range('-2:-20');

  # []

=back

=over 4

=item range example 16

  # given: synopsis

  package main;

  my $range = $map->range('-2:-6');

  # []

=back

=over 4

=item range example 17

  # given: synopsis

  package main;

  my $range = $map->range('-2:-8');

  # []

=back

=over 4

=item range example 18

  # given: synopsis

  package main;

  my $range = $map->range('-2:-9');

  # []

=back

=over 4

=item range example 19

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('-4:-1');

  # [2,4,6,8]

=back

=cut

=head2 reverse

  reverse() (arrayref)

The reverse method returns an array reference containing the elements in the
array in reverse order.

I<Since C<4.11>>

=over 4

=item reverse example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $reverse = $map->reverse;

  # [8,6,4,2]

=back

=cut

=head2 rotate

  rotate() (arrayref)

The rotate method rotates the elements in the array such that first elements
becomes the last element and the second element becomes the first element each
time this method is called.

I<Since C<4.11>>

=over 4

=item rotate example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $rotate = $map->rotate;

  # [4,6,8,2]

=back

=cut

=head2 rsort

  rsort() (arrayref)

The rsort method returns an array reference containing the values in the array
sorted alphanumerically in reverse.

I<Since C<4.11>>

=over 4

=item rsort example 1

  # given: synopsis;

  my $rsort = $map->rsort;

  # [8,6,4,2]

=back

=cut

=head2 set

  set(any %pairs) (hashref)

The set method inserts a new value into the map if it doesn't exist.

I<Since C<4.11>>

=over 4

=item set example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  $map = $map->set(9,10);

  # {1..10}

=back

=over 4

=item set example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  $map = $map->set(1..8);

  # {1..8}

=back

=cut

=head2 shift

  shift() (any)

The shift method returns the first element of the array shortening it by one.

I<Since C<4.11>>

=over 4

=item shift example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $shift = $map->shift;

  # 2

=back

=cut

=head2 shuffle

  shuffle() (arrayref)

The shuffle method returns an array with the values returned in a randomized order.

I<Since C<4.11>>

=over 4

=item shuffle example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..20);

  my $shuffle = $map->shuffle;

  # [6, 12, 2, 20, 18, 16, 10, 4, 8, 14]

=back

=cut

=head2 slice

  slice(string @keys) (hashref)

The slice method returns a hash reference containing the elements in the array
at the positions specified in the arguments.

I<Since C<4.11>>

=over 4

=item slice example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $slice = $map->slice(0, 1);

  # [2, 4]

=back

=over 4

=item slice example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $slice = $map->slice(3, 1);

  # [8, 4]

=back

=cut

=head2 sort

  sort() (hashref)

The sort method returns an array reference containing the values in the array
sorted alphanumerically.

I<Since C<4.11>>

=over 4

=item sort example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new({1 => 'a', 2 => 'b', 3 => 'c', 4 => 'd'});

  my $sort = $map->sort;

  # ["a".."d"]

=back

=cut

=head2 subset

  subset(hashref | Venus::Hash | Venus::Map $data) (boolean)

The subset method returns true if all the values provided already exist in the
source.

I<Since C<4.11>>

=over 4

=item subset example 1

  # given: synopsis

  package main;

  my $subset = $map->subset({1..6});

  # true

=back

=over 4

=item subset example 2

  # given: synopsis

  package main;

  my $subset = $map->subset({1..10});

  # false

=back

=over 4

=item subset example 3

  # given: synopsis

  package main;

  my $subset = $map->subset({1,2});

  # true

=back

=cut

=head2 superset

  superset(hashref | Venus::Hash | Venus::Map $data) (boolean)

The superset method returns true if all the values in the source exists in the
values provided.

I<Since C<4.11>>

=over 4

=item superset example 1

  # given: synopsis

  package main;

  my $superset = $map->superset({1..10});

  # true

=back

=over 4

=item superset example 2

  # given: synopsis

  package main;

  my $superset = $map->superset({1..6});

  # false

=back

=over 4

=item superset example 3

  # given: synopsis

  package main;

  my $superset = $map->superset({1..8});

  # true

=back

=cut

=head2 tail

  tail(number $size) (hashref)

The tail method returns the bottommost elements, limited by the desired size
specified.

I<Since C<4.11>>

=over 4

=item tail example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail;

  # [8]

=back

=over 4

=item tail example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail(1);

  # [8]

=back

=over 4

=item tail example 3

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail(2);

  # [6,8]

=back

=over 4

=item tail example 4

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail(4);

  # [2,4,6,8]

=back

=over 4

=item tail example 5

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail(20);

  # [2,4,6,8]

=back

=cut

=head2 unshift

  unshift(any @data) (hashref)

The unshift method prepends the array by pushing the agruments onto it and
returns itself.

I<Since C<4.11>>

=over 4

=item unshift example 1

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $unshift = $map->unshift(9,10,11,12);

  # {1..12}

=back

=over 4

=item unshift example 2

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->do('set', 1..8);

  # my $unshift = $map->unshift(9,10,11,12);

  # {1..12}

  # $map->keys;

  # [9,11,1,3,5,7]

=back

=cut

=head2 values

  values() (arrayref)

The values method returns an array reference consisting of all the values in
the hash.

I<Since C<4.15>>

=over 4

=item values example 1

  # given: synopsis;

  my $values = $map->values;

  # [2, 4, 6, 8]

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