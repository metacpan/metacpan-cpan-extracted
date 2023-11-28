package Venus::Set;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Mappable';

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

  $data->{accept} ||= 'any';

  return $data;
}

sub build_self {
  my ($self, $data) = @_;

  my $value = delete $self->{value};

  $self->push(@$value) if ref $value eq 'ARRAY';

  return $self;
}

# METHODS

sub all {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $failed = 0;

  for (my $i = 0; $i < @$data; $i++) {
    my $index = $i;
    my $value = $data->[$i];

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

  for (my $i = 0; $i < @$data; $i++) {
    my $index = $i;
    my $value = $data->[$i];

    local $_ = $value;
    $found++ if $code->($index, $value);

    CORE::last if $found;
  }

  return $found ? true : false;
}

sub assertion {
  my ($self) = @_;

  my $assert = $self->SUPER::assertion;

  $assert->match('arrayref')->format(sub{
    (ref $self || $self)->new($_)
  });


  return $assert;
}

sub attest {
  my ($self) = @_;

  require Venus::Assert;

  my $assert = Venus::Assert->new;

  my $accept = $self->accept;

  $assert->expression("within[arrayref, $accept]");

  return $assert->result($self->get);
}

sub call {
  my ($self, $mapper, $method, @args) = @_;

  require Venus::Type;

  return $self->$mapper(sub{
    my ($key, $val) = @_;

    my $type = Venus::Type->new($val)->deduce;

    local $_ = $type;

    $type->$method(@args)
  });
}

sub contains {
  my ($self, $value) = @_;

  my $value_to_object = $self->value_to_object($value);

  my $value_to_digest = $self->value_to_digest($value_to_object);
  my $index_by_digest = $self->index_by_digest;

  if (exists $index_by_digest->{$value_to_digest}) {
    return true;
  }

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

  return scalar(@$data);
}

sub default {
  return [];
}

sub delete {
  my ($self, $index) = @_;

  return undef if !$index;

  my $index_by_digest = $self->index_by_digest;
  my $index_by_order = $self->index_by_order;

  my $value = $index_by_digest->{$index_by_order->{$index}};

  return undef if !defined $value;

  return $self->remove($value);
}

sub difference {
  my ($self, $data) = @_;

  require Scalar::Util;

  my $set = $self->class->new;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Set')) {
    $set->push($_) for grep !$self->contains($_), $data->list;
  }
  elsif (Scalar::Util::blessed($data) && $data->isa('Venus::Array')) {
    $set->push($_) for grep !$self->contains($_), $data->list;
  }
  elsif (ref($data) eq 'ARRAY') {
    $set->push($_) for grep !$self->contains($_), @$data;
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

  my $result = [];

  for (my $i = 0; $i < @$data; $i++) {
    my $index = $i;
    my $value = $data->[$i];

    local $_ = $value;
    CORE::push(@$result, $code->($index, $value));
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

  my $data = $self->get;

  return $index <= $#{$data} ? true : false;
}

sub first {
  my ($self) = @_;

  return $self->get->[0];
}

sub get {
  my ($self, @args) = @_;

  return $self->value if !@args;

  my ($index) = @args;

  return $self->value->[$index];
}

sub grep {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $result = [];

  for (my $i = 0; $i < @$data; $i++) {
    my $index = $i;
    my $value = $data->[$i];

    local $_ = $value;
    CORE::push(@$result, $value) if $code->($index, $value);
  }

  return wantarray ? (@$result) : $result;
}

sub head {
  my ($self, $size) = @_;

  my $data = $self->get;

  $size = !$size ? 1 : $size > @$data ? @$data : $size;

  my $index = $size - 1;

  return [@{$data}[0..$index]];
}

sub index {
  my ($self) = @_;

  return $self->{index} ||= {};
}

sub index_by_digest {
  my ($self) = @_;

  my $digest = $self->index->{digest} ||= {};

  return $digest;
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
  my ($self, $value) = @_;

  my $value_to_object = $self->value_to_object($value);

  my $value_to_digest = $self->value_to_digest($value_to_object);
  my $index_by_digest = $self->index_by_digest;

  if (exists $index_by_digest->{$value_to_digest}) {
    return $index_by_digest->{$value_to_digest};
  }

  my $value_to_refaddr = $self->value_to_refaddr($value_to_object);
  my $index_by_refaddr = $self->index_by_refaddr;

  if (exists $index_by_refaddr->{$value_to_refaddr}) {
    return $value_to_object;
  }

  my $index_by_order = $self->index_by_order;
  $index_by_order->{int keys %{$index_by_order}} = $value_to_digest;

  $index_by_digest->{$value_to_digest} = $value_to_object;
  $index_by_refaddr->{$value_to_refaddr} = $value_to_digest;

  return $value_to_object;
}

sub iterator {
  my ($self) = @_;

  my $data = $self->get;

  my $i = 0;
  my $j = 0;

  return sub {
    return undef if $i > $#{$data};
    return wantarray ? ($j++, $data->[$i++]) : $data->[$i++];
  }
}

sub intersection {
  my ($self, $data) = @_;

  require Scalar::Util;

  my $set = $self->class->new;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Set')) {
    $set->push($_) for grep $self->contains($_), $data->list;
  }
  elsif (Scalar::Util::blessed($data) && $data->isa('Venus::Array')) {
    $set->push($_) for grep $self->contains($_), $data->list;
  }
  elsif (ref($data) eq 'ARRAY') {
    $set->push($_) for grep $self->contains($_), @$data;
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

  my $data = $self->get;

  return CORE::join($delimiter // '', @$data);
}

sub keyed {
  my ($self, @keys) = @_;

  my $data = $self->get;

  my $i = 0;
  return {map { $_ => $data->[$i++] } @keys};
}

sub keys {
  my ($self) = @_;

  my $data = $self->get;

  return [0..$#{$data}];
}

sub last {
  my ($self) = @_;

  return $self->value->[-1];
}

sub length {
  my ($self) = @_;

  return $self->count;
}

sub list {
  my ($self) = @_;

  return wantarray ? (@{$self->value}) : scalar(@{$self->value});
}

sub map {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $result = [];

  for (my $i = 0; $i < @$data; $i++) {
    my $index = $i;
    my $value = $data->[$i];

    local $_ = $value;
    CORE::push(@$result, $code->($index, $value));
  }

  return wantarray ? (@$result) : $result;
}

sub merge {
  my ($self, @data) = @_;

  require Scalar::Util;

  for my $data (@data) {
    if (Scalar::Util::blessed($data)) {
      $self->push($data->isa('Venus::Set') ? $data->list : $data);
    }
    else {
      $self->push($data);
    }
  }

  return $self;
}

sub none {
  my ($self, $code) = @_;

  my $data = $self->get;

  $code = sub{} if !$code;

  my $found = 0;

  for (my $i = 0; $i < @$data; $i++) {
    my $index = $i;
    my $value = $data->[$i];

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

  for (my $i = 0; $i < @$data; $i++) {
    my $index = $i;
    my $value = $data->[$i];

    local $_ = $value;
    $found++ if $code->($index, $value);

    CORE::last if $found > 1;
  }

  return $found == 1 ? true : false;
}

sub order {
  my ($self, @args) = @_;

  return $self if !@args;

  my $data = $self->get;

  $self->reset;

  my %seen = ();

  @$data = (map $data->[$_], grep !$seen{$_}++, (@args), 0..$#{$data});

  $self->insert($_) for @$data;

  return $self;
}

sub pairs {
  my ($self) = @_;

  my $data = $self->get;

  my $i = 0;
  my $result = [map +[$i++, $_], @$data];

  return wantarray ? (@$result) : $result;
}

sub part {
  my ($self, $code) = @_;

  my $data = $self->get;

  my $results = [[], []];

  for (my $i = 0; $i < @$data; $i++) {
    my $index = $i;
    my $value = $data->[$i];
    local $_ = $value;
    my $result = $code->($index, $value);
    my $slot = $result ? $$results[0] : $$results[1];

    CORE::push(@$slot, $value);
  }

  return wantarray ? (@$results) : $results;
}

sub pop {
  my ($self) = @_;

  return $self->remove($self->last);
}

sub push {
  my ($self, @args) = @_;

  $self->insert($_) for @args;

  return $self->get;
}

sub random {
  my ($self) = @_;

  my $data = $self->get;

  return @$data[rand($#{$data}+1)];
}

sub range {
  my ($self, @args) = @_;

  return $self->slice(@args) if @args > 1;

  my ($note) = @args;

  return $self->slice if !defined $note;

  my ($f, $l) = split /:/, $note, 2;

  my $data = $self->get;

  $f = 0 if !defined $f || $f eq '';
  $l = $f if !defined $l;
  $l = $#$data if !defined $l || $l eq '';

  $f = 0+$f;
  $l = 0+$l;

  $l = $#$data + $l if $f > -1 && $l < 0;

  return $self->slice($f..$l);
}

sub remove {
  my ($self, $value) = @_;

  my $value_to_object = $self->value_to_object($value);

  my $value_to_digest = $self->value_to_digest($value_to_object);
  my $index_by_digest = $self->index_by_digest;

  if (exists $index_by_digest->{$value_to_digest}) {
    $value_to_object = delete $index_by_digest->{$value_to_digest};
    $value_to_digest = $self->value_to_digest($value_to_object);
  }

  my $value_to_refaddr = $self->value_to_refaddr($value_to_object);
  my $index_by_refaddr = $self->index_by_refaddr;

  if (exists $index_by_refaddr->{$value_to_refaddr}) {
    delete $index_by_refaddr->{$value_to_refaddr};
  }

  my $count = 0;
  my $index_by_order = $self->index_by_order;

  %{$index_by_order} = map {$count++, $index_by_order->{$_}}
    CORE::grep {$index_by_order->{$_} ne $value_to_digest}
      CORE::sort(CORE::keys(%{$index_by_order}));

  return $value_to_object;
}

sub reset {
  my ($self, @data) = @_;

  delete $self->{index};

  $self->insert($_) for @data;

  return $self;
}

sub reverse {
  my ($self) = @_;

  my $data = $self->get;

  $self->reset;

  $self->insert($_) for CORE::reverse(@$data);

  return $self->get;
}

sub rotate {
  my ($self) = @_;

  my $data = $self->get;

  $self->reset;

  CORE::push(@$data, CORE::shift(@$data));

  $self->insert($_) for @$data;

  return $self->get;
}

sub rsort {
  my ($self) = @_;

  my $data = $self->get;

  return [CORE::sort { $b cmp $a } @$data];
}

sub set {
  my ($self, @args) = @_;

  return $self->value if !@args;

  return $self->insert(@args);
}

sub shift {
  my ($self) = @_;

  my $data = $self->get;

  $self->reset;

  my $result = CORE::shift(@$data);

  $self->insert($_) for @$data;

  return $result;
}

sub shuffle {
  my ($self) = @_;

  my $data = $self->get;
  my $result = [@$data];

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

  my $data = $self->get;

  return [@$data[@args]];
}

sub sort {
  my ($self) = @_;

  my $data = $self->get;

  return [CORE::sort { $a cmp $b } @$data];
}

sub subset {
  my ($self, $data) = @_;

  require Scalar::Util;

  my $set = $self->class->new;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Set')) {
    $set->push($_) for grep $self->contains($_), $data->list;
    return true if $data->count == $set->count;
  }
  elsif (Scalar::Util::blessed($data) && $data->isa('Venus::Array')) {
    $set->push($_) for grep $self->contains($_), $data->list;
    return true if $data->count == $set->count;
  }
  elsif (ref($data) eq 'ARRAY') {
    $set->push($_) for grep $self->contains($_), @$data;
    return true if @$data == $set->count;
  }

  return false;
}

sub superset {
  my ($self, $data) = @_;

  require Scalar::Util;

  my $set = $self->class->new;

  if (Scalar::Util::blessed($data) && $data->isa('Venus::Set')) {
    $set->push($_) for grep !$data->contains($_), $self->list;
    return false if $set->count || $data->count <= $self->count;;
  }
  elsif (Scalar::Util::blessed($data) && $data->isa('Venus::Array')) {
    my $temp = $self->class->new($data->get);
    $set->push($_) for grep !$temp->contains($_), $self->list;
    return false if $set->count || $temp->count <= $self->count;
  }
  elsif (ref($data) eq 'ARRAY') {
    my $temp = $self->class->new($data);
    $set->push($_) for grep !$temp->contains($_), $self->list;
    return false if $set->count || $temp->count <= $self->count;
  }

  return true;
}

sub tail {
  my ($self, $size) = @_;

  my $data = $self->get;

  $size = !$size ? 1 : $size > @$data ? @$data : $size;

  my $index = $#$data - ($size - 1);

  return [@{$data}[$index..$#$data]];
}

sub unique {
  my ($self) = @_;

  my $data = $self->get;

  return $data;
}

sub unshift {
  my ($self, @args) = @_;

  my $data = $self->get;

  $self->reset;

  CORE::unshift(@$data, @args);

  $self->insert($_) for @$data;

  return $data;
}

sub value {
  my ($self) = @_;

  my $index_by_digest = $self->index_by_digest;
  my $index_by_order = $self->index_by_order;

  return [
    CORE::map {$index_by_digest->{$index_by_order->{$_}}}
      CORE::sort(CORE::keys(%{$index_by_order}))
  ];
}

sub value_to_digest {
  my ($self, $value) = @_;

  require Digest;

  my $digest = Digest->new('SHA-1');
  my $method = "Venus::Role::Dumpable::dump";

  return $digest->add($value->$method)->hexdigest;
}

sub value_to_object {
  my ($self, $value) = @_;

  require Venus::Type;

  return Venus::Type->new($value)->deduce;
}

sub value_to_refaddr {
  my ($self, $value) = @_;

  require Scalar::Util;

  return Scalar::Util::refaddr($value);
}

1;



=head1 NAME

Venus::Set - Set Class

=cut

=head1 ABSTRACT

Set Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Set;

  my $set = Venus::Set->new([1,1,2,2,3,3,4,4,5..9]);

  # $set->count;

  # 4

=cut

=head1 DESCRIPTION

This package provides a representation of a collection of ordered unique values
and methods for validating and manipulating it.

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

  my $set_accept = $set->accept("number");

  # "number"

=back

=over 4

=item accept example 2

  # given: synopsis

  # given: example-1 accept

  package main;

  my $get_accept = $set->accept;

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

  my $all = $set->all(sub {
    $_ > 0;
  });

  # 1

=back

=over 4

=item all example 2

  # given: synopsis;

  my $all = $set->all(sub {
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

  my $any = $set->any(sub {
    $_ > 4;
  });

=back

=over 4

=item any example 2

  # given: synopsis;

  my $any = $set->any(sub {
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

  my $attest = $set->attest;

  # [1..9]

=back

=over 4

=item attest example 2

  # given: synopsis

  package main;

  $set->accept('number | object');

  my $attest = $set->attest;

  # [1..9]

=back

=over 4

=item attest example 3

  # given: synopsis

  package main;

  $set->accept('string');

  my $attest = $set->attest;

  # Exception! (isa Venus::Check::Error)

=back

=over 4

=item attest example 4

  # given: synopsis

  package main;

  $set->accept('Venus::Number');

  my $attest = $set->attest;

  # [1..9]

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

  # given: synopsis

  package main;

  my $call = $set->call('map', 'incr');

  # [2..10]

=back

=over 4

=item call example 2

  # given: synopsis

  package main;

  my $call = $set->call('grep', 'gt', 4);

  # [4..9]

=back

=cut

=head2 contains

  contains(any $value) (boolean)

The contains method returns true if the value provided already exists in the
set, otherwise it returns false.

I<Since C<4.11>>

=over 4

=item contains example 1

  # given: synopsis;

  my $contains = $set->contains(1);

  # true

=back

=over 4

=item contains example 2

  # given: synopsis;

  my $contains = $set->contains(0);

  # false

=back

=cut

=head2 count

  count() (number)

The count method returns the number of elements within the set.

I<Since C<4.11>>

=over 4

=item count example 1

  # given: synopsis;

  my $count = $set->count;

  # 9

=back

=cut

=head2 default

  default() (arrayref)

The default method returns the default value, i.e. C<[]>.

I<Since C<4.11>>

=over 4

=item default example 1

  # given: synopsis;

  my $default = $set->default;

  # []

=back

=cut

=head2 delete

  delete(number $index) (any)

The delete method returns the value of the element at the index specified after
removing it from the array.

I<Since C<4.11>>

=over 4

=item delete example 1

  # given: synopsis;

  my $delete = $set->delete(2);

  # 3

=back

=cut

=head2 difference

  difference(arrayref | Venus::Array | Venus::Set $data) (Venus::Set)

The difference method returns a new set containing only the values that don't
exist in the source.

I<Since C<4.11>>

=over 4

=item difference example 1

  # given: synopsis

  package main;

  my $difference = $set->difference([9, 10, 11]);

  # bless(..., "Venus::Set")

  # $difference->list;

  # [10, 11]

=back

=over 4

=item difference example 2

  # given: synopsis

  package main;

  my $difference = $set->difference(Venus::Set->new([9, 10, 11]));

  # bless(..., "Venus::Set")

  # $difference->list;

  # [10, 11]

=back

=over 4

=item difference example 3

  # given: synopsis

  package main;

  use Venus::Array;

  my $difference = $set->difference(Venus::Array->new([9, 10, 11]));

  # bless(..., "Venus::Set")

  # $difference->list;

  # [10, 11]

=back

=cut

=head2 different

  different(arrayref | Venus::Array | Venus::Set $data) (boolean)

The different method returns true if the values provided don't exist in the
source.

I<Since C<4.11>>

=over 4

=item different example 1

  # given: synopsis

  package main;

  my $different = $set->different([1..10]);

  # true

=back

=over 4

=item different example 2

  # given: synopsis

  package main;

  my $different = $set->different([1..9]);

  # false

=back

=cut

=head2 each

  each(coderef $code) (arrayref)

The each method executes a callback for each element in the array passing the
index and value as arguments. This method can return a list of values in
list-context.

I<Since C<4.11>>

=over 4

=item each example 1

  # given: synopsis;

  my $each = $set->each(sub {
    [$_]
  });

  # [[1], [2], [3], [4], [5], [6], [7], [8], [9]]

=back

=over 4

=item each example 2

  # given: synopsis;

  my $each = $set->each(sub {
    my ($key, $value) = @_;

    [$key, $value]
  });

  # [
  #   [0, 1],
  #   [1, 2],
  #   [2, 3],
  #   [3, 4],
  #   [4, 5],
  #   [5, 6],
  #   [6, 7],
  #   [7, 8],
  #   [8, 9],
  # ]

=back

=cut

=head2 empty

  empty() (Venus::Array)

The empty method drops all elements from the set.

I<Since C<4.11>>

=over 4

=item empty example 1

  # given: synopsis;

  my $empty = $set->empty;

  # bless({}, "Venus::Set")

=back

=cut

=head2 exists

  exists(number $index) (boolean)

The exists method returns true if the element at the index specified exists,
otherwise it returns false.

I<Since C<4.11>>

=over 4

=item exists example 1

  # given: synopsis;

  my $exists = $set->exists(0);

  # true

=back

=cut

=head2 first

  first() (any)

The first method returns the value of the first element.

I<Since C<4.11>>

=over 4

=item first example 1

  # given: synopsis;

  my $first = $set->first;

  # 1

=back

=cut

=head2 get

  get(number $index) (any)

The get method returns the value at the position specified.

I<Since C<4.11>>

=over 4

=item get example 1

  # given: synopsis

  package main;

  my $get = $set->get(0);

  # 1

=back

=over 4

=item get example 2

  # given: synopsis

  package main;

  my $get = $set->get(3);

  # 4

=back

=cut

=head2 grep

  grep(coderef $code) (arrayref)

The grep method executes a callback for each element in the array passing the
value as an argument, returning a new array reference containing the elements
for which the returned true. This method can return a list of values in
list-context.

I<Since C<4.11>>

=over 4

=item grep example 1

  # given: synopsis;

  my $grep = $set->grep(sub {
    $_ > 3
  });

  # [4..9]

=back

=over 4

=item grep example 2

  # given: synopsis;

  my $grep = $set->grep(sub {
    my ($key, $value) = @_;

    $value > 3
  });

  # [4..9]

=back

=cut

=head2 intersect

  intersect(arrayref | Venus::Array | Venus::Set $data) (boolean)

The intersect method returns true if the values provided already exist in the
source.

I<Since C<4.11>>

=over 4

=item intersect example 1

  # given: synopsis

  package main;

  my $intersect = $set->intersect([9, 10]);

  # true

=back

=over 4

=item intersect example 2

  # given: synopsis

  package main;

  my $intersect = $set->intersect([10, 11]);

  # false

=back

=cut

=head2 intersection

  intersection(arrayref | Venus::Array | Venus::Set $data) (Venus::Set)

The intersection method returns a new set containing only the values that
already exist in the source.

I<Since C<4.11>>

=over 4

=item intersection example 1

  # given: synopsis

  package main;

  $set->push(10);

  my $intersection = $set->intersection([9, 10, 11]);

  # bless(..., "Venus::Set")

  # $intersection->list;

  # [9, 10]

=back

=over 4

=item intersection example 2

  # given: synopsis

  package main;

  $set->push(10);

  my $intersection = $set->intersection(Venus::Set->new([9, 10, 11]));

  # bless(..., "Venus::Set")

  # $intersection->list;

  # [9, 10]

=back

=over 4

=item intersection example 3

  # given: synopsis

  package main;

  use Venus::Array;

  $set->push(10);

  my $intersection = $set->intersection(Venus::Array->new([9, 10, 11]));

  # bless(..., "Venus::Set")

  # $intersection->list;

  # [9, 10]

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

  my $iterator = $set->iterator;

  # sub { ... }

  # while (my $value = $iterator->()) {
  #   say $value; # 1
  # }

=back

=over 4

=item iterator example 2

  # given: synopsis;

  my $iterator = $set->iterator;

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

  # given: synopsis;

  my $join = $set->join;

  # 123456789

=back

=over 4

=item join example 2

  # given: synopsis;

  my $join = $set->join(', ');

  # "1, 2, 3, 4, 5, 6, 7, 8, 9"

=back

=cut

=head2 keyed

  keyed(string @keys) (hashref)

The keyed method returns a hash reference where the arguments become the keys,
and the elements of the array become the values.

I<Since C<4.11>>

=over 4

=item keyed example 1

  package main;

  use Venus::Array;

  my $set = Venus::Array->new([1..4]);

  my $keyed = $set->keyed('a'..'d');

  # { a => 1, b => 2, c => 3, d => 4 }

=back

=cut

=head2 keys

  keys() (arrayref)

The keys method returns an array reference consisting of the indicies of the
array.

I<Since C<4.11>>

=over 4

=item keys example 1

  # given: synopsis;

  my $keys = $set->keys;

  # [0..8]

=back

=cut

=head2 last

  last() (any)

The last method returns the value of the last element in the array.

I<Since C<4.11>>

=over 4

=item last example 1

  # given: synopsis;

  my $last = $set->last;

  # 9

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

  my $length = $set->length;

  # 9

=back

=cut

=head2 list

  list() (any)

The list method returns a shallow copy of the underlying array reference as an
array reference.

I<Since C<4.11>>

=over 4

=item list example 1

  # given: synopsis;

  my $list = $set->list;

  # 9

=back

=over 4

=item list example 2

  # given: synopsis;

  my @list = $set->list;

  # (1..9)

=back

=cut

=head2 map

  map(coderef $code) (arrayref)

The map method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing the
elements for which the argument returns a value or non-empty list. This method
can return a list of values in list-context.

I<Since C<4.11>>

=over 4

=item map example 1

  # given: synopsis;

  my $map = $set->map(sub {
    $_ * 2
  });

  # [2, 4, 6, 8, 10, 12, 14, 16, 18]

=back

=over 4

=item map example 2

  # given: synopsis;

  my $map = $set->map(sub {
    my ($key, $value) = @_;

    [$key, ($value * 2)]
  });

  # [
  #   [0, 2],
  #   [1, 4],
  #   [2, 6],
  #   [3, 8],
  #   [4, 10],
  #   [5, 12],
  #   [6, 14],
  #   [7, 16],
  #   [8, 18],
  # ]

=back

=cut

=head2 merge

  merge(any @data) (Venus::Set)

The merge method merges the arguments provided with the existing set.

I<Since C<4.11>>

=over 4

=item merge example 1

  # given: synopsis;

  my $merge = $set->merge(6..9);

  # bless(..., "Venus::Set")

  # $set->list;

  # [1..9]

=back

=over 4

=item merge example 2

  # given: synopsis;

  my $merge = $set->merge(8, 10);

  # bless(..., "Venus::Set")

  # $set->list;

  # [1..10]

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

  my $none = $set->none(sub {
    $_ < 1
  });

  # 1

=back

=over 4

=item none example 2

  # given: synopsis;

  my $none = $set->none(sub {
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

  my $one = $set->one(sub {
    $_ == 1
  });

  # 1

=back

=over 4

=item one example 2

  # given: synopsis;

  my $one = $set->one(sub {
    my ($key, $value) = @_;

    $value == 1
  });

  # 1

=back

=cut

=head2 order

  order(number @indices) (Venus::Array)

The order method reorders the array items based on the indices provided and
returns the invocant.

I<Since C<4.11>>

=over 4

=item order example 1

  # given: synopsis;

  my $order = $set->order;

  # bless(..., "Venus::Set")

  # $set->list;

  # [1..9]

=back

=over 4

=item order example 2

  # given: synopsis;

  my $order = $set->order(8,7,6);

  # bless(..., "Venus::Set")

  # $set->list;

  # [9,8,7,1,2,3,4,5,6]

=back

=over 4

=item order example 3

  # given: synopsis;

  my $order = $set->order(0,2,1);

  # bless(..., "Venus::Set")

  # $set->list;

  # [1,3,2,4,5,6,7,8,9]

=back

=cut

=head2 pairs

  pairs() (arrayref)

The pairs method is an alias to the pairs_array method. This method can return
a list of values in list-context.

I<Since C<4.11>>

=over 4

=item pairs example 1

  # given: synopsis;

  my $pairs = $set->pairs;

  # [
  #   [0, 1],
  #   [1, 2],
  #   [2, 3],
  #   [3, 4],
  #   [4, 5],
  #   [5, 6],
  #   [6, 7],
  #   [7, 8],
  #   [8, 9],
  # ]

=back

=cut

=head2 part

  part(coderef $code) (tuple[arrayref, arrayref])

The part method iterates over each element in the array, executing the code
reference supplied in the argument, using the result of the code reference to
partition to array into two distinct array references. This method can return a
list of values in list-context.

I<Since C<4.11>>

=over 4

=item part example 1

  # given: synopsis;

  my $part = $set->part(sub {
    $_ > 5
  });

  # [[6..9], [1..5]]

=back

=over 4

=item part example 2

  # given: synopsis;

  my $part = $set->part(sub {
    my ($key, $value) = @_;

    $value < 5
  });

  # [[1..4], [5..9]]

=back

=cut

=head2 pop

  pop() (any)

The pop method returns the last element of the array shortening it by one.
Note, this method modifies the array.

I<Since C<4.11>>

=over 4

=item pop example 1

  # given: synopsis;

  my $pop = $set->pop;

  # 9

=back

=cut

=head2 push

  push(any @data) (arrayref)

The push method appends the array by pushing the agruments onto it and returns
itself.

I<Since C<4.11>>

=over 4

=item push example 1

  # given: synopsis;

  my $push = $set->push(10);

  # [1..10]

=back

=cut

=head2 random

  random() (any)

The random method returns a random element from the array.

I<Since C<4.11>>

=over 4

=item random example 1

  # given: synopsis;

  my $random = $set->random;

  # 2

  # my $random = $set->random;

  # 1

=back

=cut

=head2 range

  range(number | string @args) (arrayref)

The range method accepts a I<"range expression"> and returns the result of
calling the L</slice> method with the computed range.

I<Since C<4.11>>

=over 4

=item range example 1

  # given: synopsis

  package main;

  my $range = $set->range;

  # []

=back

=over 4

=item range example 2

  # given: synopsis

  package main;

  my $range = $set->range(0);

  # [1]

=back

=over 4

=item range example 3

  # given: synopsis

  package main;

  my $range = $set->range('0:');

  # [1..9]

=back

=over 4

=item range example 4

  # given: synopsis

  package main;

  my $range = $set->range(':4');

  # [1..5]

=back

=over 4

=item range example 5

  # given: synopsis

  package main;

  my $range = $set->range('8:');

  # [9]

=back

=over 4

=item range example 6

  # given: synopsis

  package main;

  my $range = $set->range('4:');

  # [5..9]

=back

=over 4

=item range example 7

  # given: synopsis

  package main;

  my $range = $set->range('0:2');

  # [1..3]

=back

=over 4

=item range example 8

  # given: synopsis

  package main;

  my $range = $set->range('2:4');

  # [3..5]

=back

=over 4

=item range example 9

  # given: synopsis

  package main;

  my $range = $set->range(0..3);

  # [1..4]

=back

=over 4

=item range example 10

  # given: synopsis

  package main;

  my $range = $set->range('-1:8');

  # [9,1..9]

=back

=over 4

=item range example 11

  # given: synopsis

  package main;

  my $range = $set->range('0:8');

  # [1..9]

=back

=over 4

=item range example 12

  # given: synopsis

  package main;

  my $range = $set->range('0:-2');

  # [1..7]

=back

=over 4

=item range example 13

  # given: synopsis

  package main;

  my $range = $set->range('-2:-2');

  # [8]

=back

=over 4

=item range example 14

  # given: synopsis

  package main;

  my $range = $set->range('0:-20');

  # []

=back

=over 4

=item range example 15

  # given: synopsis

  package main;

  my $range = $set->range('-2:-20');

  # []

=back

=over 4

=item range example 16

  # given: synopsis

  package main;

  my $range = $set->range('-2:-6');

  # []

=back

=over 4

=item range example 17

  # given: synopsis

  package main;

  my $range = $set->range('-2:-8');

  # []

=back

=over 4

=item range example 18

  # given: synopsis

  package main;

  my $range = $set->range('-2:-9');

  # []

=back

=over 4

=item range example 19

  # given: synopsis

  package main;

  my $range = $set->range('-5:-1');

  # [5..9]

=back

=cut

=head2 reverse

  reverse() (arrayref)

The reverse method returns an array reference containing the elements in the
array in reverse order.

I<Since C<4.11>>

=over 4

=item reverse example 1

  # given: synopsis;

  my $reverse = $set->reverse;

  # [9, 8, 7, 6, 5, 4, 3, 2, 1]

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

  # given: synopsis;

  my $rotate = $set->rotate;

  # [2..9, 1]

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

  my $rsort = $set->rsort;

  # [9, 8, 7, 6, 5, 4, 3, 2, 1]

=back

=cut

=head2 set

  set(any $value) (any)

The set method inserts a new value into the set if it doesn't exist.

I<Since C<4.11>>

=over 4

=item set example 1

  # given: synopsis

  package main;

  $set = $set->set(10);

  # 10

=back

=over 4

=item set example 2

  # given: synopsis

  package main;

  $set = $set->set(0);

  # 0

=back

=cut

=head2 shift

  shift() (any)

The shift method returns the first element of the array shortening it by one.

I<Since C<4.11>>

=over 4

=item shift example 1

  # given: synopsis;

  my $shift = $set->shift;

  # 1

=back

=cut

=head2 shuffle

  shuffle() (arrayref)

The shuffle method returns an array with the items in a randomized order.

I<Since C<4.11>>

=over 4

=item shuffle example 1

  # given: synopsis

  package main;

  my $shuffle = $set->shuffle;

  # [4, 5, 8, 7, 2, 9, 6, 3, 1]

=back

=cut

=head2 slice

  slice(string @keys) (arrayref)

The slice method returns a hash reference containing the elements in the array
at the index(es) specified in the arguments.

I<Since C<4.11>>

=over 4

=item slice example 1

  # given: synopsis;

  my $slice = $set->slice(2, 4);

  # [3, 5]

=back

=cut

=head2 sort

  sort() (arrayref)

The sort method returns an array reference containing the values in the array
sorted alphanumerically.

I<Since C<4.11>>

=over 4

=item sort example 1

  package main;

  use Venus::Set;

  my $set = Venus::Set->new(['d','c','b','a']);

  my $sort = $set->sort;

  # ["a".."d"]

=back

=cut

=head2 subset

  subset(arrayref | Venus::Array | Venus::Set $data) (boolean)

The subset method returns true if all the values provided already exist in the
source.

I<Since C<4.11>>

=over 4

=item subset example 1

  # given: synopsis

  package main;

  my $subset = $set->subset([1..4]);

  # true

=back

=over 4

=item subset example 2

  # given: synopsis

  package main;

  my $subset = $set->subset([1..10]);

  # false

=back

=over 4

=item subset example 3

  # given: synopsis

  package main;

  my $subset = $set->subset([1..9]);

  # true

=back

=cut

=head2 superset

  superset(arrayref | Venus::Array | Venus::Set $data) (boolean)

The superset method returns true if all the values in the source exists in the
values provided.

I<Since C<4.11>>

=over 4

=item superset example 1

  # given: synopsis

  package main;

  my $superset = $set->superset([1..10]);

  # true

=back

=over 4

=item superset example 2

  # given: synopsis

  package main;

  my $superset = $set->superset([1..9]);

  # false

=back

=over 4

=item superset example 3

  # given: synopsis

  package main;

  my $superset = $set->superset([0..9]);

  # true

=back

=cut

=head2 unique

  unique() (arrayref)

The unique method returns an array reference consisting of the unique elements
in the array.

I<Since C<4.11>>

=over 4

=item unique example 1

  package main;

  use Venus::Set;

  my $set = Venus::Set->new([1,1,1,1,2,3,1]);

  my $unique = $set->unique;

  # [1, 2, 3]

=back

=cut

=head2 unshift

  unshift(any @data) (arrayref)

The unshift method prepends the array by pushing the agruments onto it and
returns itself.

I<Since C<4.11>>

=over 4

=item unshift example 1

  # given: synopsis;

  my $unshift = $set->unshift(-2,-1,0);

  # [-2..9]

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