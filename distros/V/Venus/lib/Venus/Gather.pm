package Venus::Gather;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Valuable';
with 'Venus::Role::Buildable';
with 'Venus::Role::Accessible';

use Scalar::Util ();

# ATTRIBUTES

attr 'on_none';
attr 'on_only';
attr 'on_then';
attr 'on_when';

# BUILDERS

sub build_self {
  my ($self, $data) = @_;

  $self->on_none(sub{}) if !$self->on_none;
  $self->on_only(sub{1}) if !$self->on_only;
  $self->on_then([]) if !$self->on_then;
  $self->on_when([]) if !$self->on_when;

  return $self;
}

# METHODS

sub clear {
  my ($self) = @_;

  $self->on_none(sub{});
  $self->on_only(sub{1});
  $self->on_then([]);
  $self->on_when([]);

  return $self;
}

sub data {
  my ($self, $data) = @_;

  while(my($key, $value) = each(%$data)) {
    $self->just($key)->then($value);
  }

  return $self;
}

sub expr {
  my ($self, $topic) = @_;

  $self->when(sub{
    my $value = $_[0];

    if (!defined $value) {
      return false;
    }
    if (Scalar::Util::blessed($value) && !overload::Overloaded($value)) {
      return false;
    }
    if (!Scalar::Util::blessed($value) && ref($value)) {
      return false;
    }
    if (ref($topic) eq 'Regexp' && "$value" =~ qr/$topic/) {
      return true;
    }
    elsif ("$value" eq "$topic") {
      return true;
    }
    else {
      return false;
    }
  });

  return $self;
}

sub just {
  my ($self, $topic) = @_;

  $self->when(sub{
    my $value = $_[0];

    if (!defined $value) {
      return false;
    }
    if (Scalar::Util::blessed($value) && !overload::Overloaded($value)) {
      return false;
    }
    if (!Scalar::Util::blessed($value) && ref($value)) {
      return false;
    }
    if ("$value" eq "$topic") {
      return true;
    }
    else {
      return false;
    }
  });

  return $self;
}

sub none {
  my ($self, $code) = @_;

  $self->on_none(UNIVERSAL::isa($code, 'CODE') ? $code : sub{$code});

  return $self;
}

sub only {
  my ($self, $code) = @_;

  $self->on_only($code);

  return $self;
}

sub result {
  my ($self, $data) = @_;

  $self->value(ref $data eq 'ARRAY' ? $data : [$data]) if $data;

  my $value = $self->value;
  my $result = [];
  my $matched = 0;

  local $_ = $value;
  return wantarray ? ($result, $matched) : $result if !$self->on_only->($value);

  for my $item (@$value) {
    local $_ = $item;
    for (my $i = 0; $i < @{$self->on_when}; $i++) {
      if ($self->on_when->[$i]->($item)) {
        push @$result, $self->on_then->[$i]->($item);
        $matched++;
        last;
      }
    }
  }

  if (!@$result) {
    local $_ = $value;
    my @return = ($self->on_none->($value));
    push @$result,
      ((@return == 1 && ref($return[0]) eq 'ARRAY') ? @{$return[0]} : @return);
  }

  return wantarray ? ($result, $matched) : $result;
}

sub skip {
  my ($self) = @_;

  $self->then(sub{return ()});

  return $self;
}

sub take {
  my ($self) = @_;

  $self->then(sub{return (@_)});

  return $self;
}

sub test {
  my ($self) = @_;

  my $matched = 0;

  my $value = $self->value;

  local $_ = $value;
  return $matched if !$self->on_only->($value);

  for my $item (@$value) {
    local $_ = $item;
    for (my $i = 0; $i < @{$self->on_when}; $i++) {
      if ($self->on_when->[$i]->($item)) {
        $matched++;
        last;
      }
    }
  }

  return $matched;
}

sub then {
  my ($self, $code) = @_;

  my $next = $#{$self->on_when};

  $self->on_then->[$next] = UNIVERSAL::isa($code, 'CODE') ? $code : sub{$code};

  return $self;
}

sub when {
  my ($self, $code, @args) = @_;

  my $next = (@{$self->on_when}-$#{$self->on_then}) > 1 ? -1 : @{$self->on_when};

  $self->on_when->[$next] = sub {
    (local $_ = $_[0])->$code(@args);
  };

  return $self;
}

sub where {
  my ($self) = @_;

  my $where = $self->new;

  $self->then(sub{@{scalar($where->result(@_))}});

  return $where;
}

1;



=head1 NAME

Venus::Gather - Gather Class

=cut

=head1 ABSTRACT

Gather Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->when(sub{$_ eq 1})->then(sub{"one"});
  $gather->when(sub{$_ eq 2})->then(sub{"two"});

  $gather->none(sub{"?"});

  my $result = $gather->result;

  # ["?"]

=cut

=head1 DESCRIPTION

This package provides an object-oriented interface for complex pattern matching
operations on collections of data, e.g. array references. See L<Venus::Match>
for operating on scalar values.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 on_none

  on_none(CodeRef)

This attribute is read-write, accepts C<(CodeRef)> values, is optional, and defaults to C<sub{}>.

=cut

=head2 on_only

  on_only(CodeRef)

This attribute is read-write, accepts C<(CodeRef)> values, is optional, and defaults to C<sub{1}>.

=cut

=head2 on_then

  on_then(ArrayRef[CodeRef])

This attribute is read-write, accepts C<(ArrayRef[CodeRef])> values, is optional, and defaults to C<[]>.

=cut

=head2 on_when

  on_when(ArrayRef[CodeRef])

This attribute is read-write, accepts C<(ArrayRef[CodeRef])> values, is optional, and defaults to C<[]>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Accessible>

L<Venus::Role::Buildable>

L<Venus::Role::Valuable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 clear

  clear() (Gather)

The clear method resets all gather conditions and returns the invocant.

I<Since C<1.55>>

=over 4

=item clear example 1

  # given: synopsis

  package main;

  my $clear = $gather->clear;

  # bless(..., "Venus::Gather")

=back

=cut

=head2 data

  data(HashRef $data) (Gather)

The data method takes a hashref (i.e. lookup table) and creates gather
conditions and actions based on the keys and values found.

I<Since C<1.55>>

=over 4

=item data example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->data({
    "one" => 1,
    "two" => 2,
    "three" => 3,
    "four" => 4,
    "five" => 5,
    "six" => 6,
    "seven" => 7,
    "eight" => 8,
    "nine" => 9,
    "zero" => 0,
  });

  my $result = $gather->none('?')->result;

  # [1..9, 0]

=back

=over 4

=item data example 2

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->data({
    "zero" => 0,
  });

  my $result = $gather->none('?')->result;

  # [0]

=back

=cut

=head2 expr

  expr(Str | RegexpRef $expr) (Gather)

The expr method registers a L</when> condition that check if the match value is
an exact string match of the C<$topic> if the topic is a string, or that it
matches against the topic if the topic is a regular expression.

I<Since C<1.55>>

=over 4

=item expr example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->expr('one')->then(sub{[split //]});

  my $result = $gather->result;

  # [["o", "n", "e"]]

=back

=over 4

=item expr example 2

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->expr(qr/^o/)->then(sub{[split //]});

  my $result = $gather->result;

  # [["o", "n", "e"]]

=back

=cut

=head2 just

  just(Str $topic) (Gather)

The just method registers a L</when> condition that check if the match value is
an exact string match of the C<$topic> provided.

I<Since C<1.55>>

=over 4

=item just example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just('one')->then(1);
  $gather->just('two')->then(2);
  $gather->just('three')->then(3);

  my $result = $gather->result;

  # [1,2,3]

=back

=over 4

=item just example 2

  package main;

  use Venus::Gather;
  use Venus::String;

  my $gather = Venus::Gather->new([
    Venus::String->new("one"),
    Venus::String->new("two"),
    Venus::String->new("three"),
    Venus::String->new("four"),
    Venus::String->new("five"),
    Venus::String->new("six"),
    Venus::String->new("seven"),
    Venus::String->new("eight"),
    Venus::String->new("nine"),
    Venus::String->new("zero"),
  ]);

  $gather->just('one')->then(1);
  $gather->just('two')->then(2);
  $gather->just('three')->then(3);

  my $result = $gather->result;

  # [1,2,3]

=back

=over 4

=item just example 3

  package main;

  use Venus::Gather;
  use Venus::String;

  my $gather = Venus::Gather->new([
    Venus::String->new("one"),
    Venus::String->new("two"),
    Venus::String->new("three"),
    Venus::String->new("four"),
    Venus::String->new("five"),
    Venus::String->new("six"),
    Venus::String->new("seven"),
    Venus::String->new("eight"),
    Venus::String->new("nine"),
    Venus::String->new("zero"),
  ]);

  $gather->just('one')->then(1);
  $gather->just('six')->then(6);

  my $result = $gather->result;

  # [1,6]

=back

=cut

=head2 none

  none(Any | CodeRef $code) (Gather)

The none method registers a special condition that returns a result only when
no other conditions have been matched.

I<Since C<1.55>>

=over 4

=item none example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just('ten')->then(10);

  $gather->none('none');

  my $result = $gather->result;

  # ["none"]

=back

=over 4

=item none example 2

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just('ten')->then(10);

  $gather->none(sub{[map "no $_", @$_]});

  my $result = $gather->result;

  # [
  #   "no one",
  #   "no two",
  #   "no three",
  #   "no four",
  #   "no five",
  #   "no six",
  #   "no seven",
  #   "no eight",
  #   "no nine",
  #   "no zero",
  # ]

=back

=cut

=head2 only

  only(CodeRef $code) (Gather)

The only method registers a special condition that only allows matching on the
value only if the code provided returns truthy.

I<Since C<1.55>>

=over 4

=item only example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->only(sub{grep /^[A-Z]/, @$_});

  $gather->just('one')->then(1);

  my $result = $gather->result;

  # []

=back

=over 4

=item only example 2

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->only(sub{grep /e$/, @$_});

  $gather->expr(qr/e$/)->take;

  my $result = $gather->result;

  # [
  #   "one",
  #   "three",
  #   "five",
  #   "nine",
  # ]

=back

=cut

=head2 result

  result(Any $data) (Any)

The result method evaluates the registered conditions and returns the result of
the action (i.e. the L</then> code) or the special L</none> condition if there
were no matches. In list context, this method returns both the result and
whether or not a condition matched. Optionally, when passed an argument this
method assign the argument as the value/topic and then perform the operation.

I<Since C<1.55>>

=over 4

=item result example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just('one')->then(1);
  $gather->just('six')->then(6);

  my $result = $gather->result;

  # [1,6]

=back

=over 4

=item result example 2

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just('one')->then(1);
  $gather->just('six')->then(6);

  my ($result, $gathered) = $gather->result;

  # ([1,6], 2)

=back

=over 4

=item result example 3

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just('One')->then(1);
  $gather->just('Six')->then(6);

  my ($result, $gathered) = $gather->result;

  # ([], 0)

=back

=over 4

=item result example 4

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just(1)->then(1);
  $gather->just(6)->then(6);

  my $result = $gather->result([1..9, 0]);

  # [1,6]

=back

=over 4

=item result example 5

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just('one')->then(1);
  $gather->just('six')->then(6);

  my $result = $gather->result([10..20]);

  # []

=back

=cut

=head2 skip

  skip() (Gather)

The skip method registers a L</then> condition which ignores (i.e. skips) the
matched line item.

I<Since C<1.55>>

=over 4

=item skip example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->expr(qr/e$/)->skip;

  $gather->expr(qr/.*/)->take;

  my $result = $gather->result;

  # ["two", "four", "six", "seven", "eight", "zero"]

=back

=cut

=head2 take

  take() (Gather)

The take method registers a L</then> condition which returns (i.e. takes) the
matched line item as-is.

I<Since C<1.55>>

=over 4

=item take example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->expr(qr/e$/)->take;

  my $result = $gather->result;

  # ["one", "three", "five", "nine"]

=back

=cut

=head2 then

  then(Any | CodeRef $code) (Gather)

The then method registers an action to be executed if the corresponding gather
condition returns truthy.

I<Since C<1.55>>

=over 4

=item then example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just('one');
  $gather->then(1);

  $gather->just('two');
  $gather->then(2);

  my $result = $gather->result;

  # [1,2]

=back

=over 4

=item then example 2

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->just('one');
  $gather->then(1);

  $gather->just('two');
  $gather->then(2);
  $gather->then(0);

  my $result = $gather->result;

  # [1,0]

=back

=cut

=head2 when

  when(Str | CodeRef $code, Any @args) (Gather)

The when method registers a match condition that will be passed the match value
during evaluation. If the match condition returns truthy the corresponding
action will be used to return a result. If the match value is an object, this
method can take a method name and arguments which will be used as a match
condition.

I<Since C<1.55>>

=over 4

=item when example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new([
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "zero",
  ]);

  $gather->when(sub{$_ eq 'one'});
  $gather->then(1);

  $gather->when(sub{$_ eq 'two'});
  $gather->then(2);

  $gather->when(sub{$_ eq 'six'});
  $gather->then(6);

  my $result = $gather->result;

  # [1,2,6]

=back

=cut

=head2 where

  where() (Gather)

The where method registers an action as a sub-match operation, to be executed
if the corresponding match condition returns truthy. This method returns the
sub-match object.

I<Since C<1.55>>

=over 4

=item where example 1

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new;

  my $subgather1 = $gather->expr(qr/^p([a-z]+)ch/)->where;

  $subgather1->just('peach')->then('peach-123');
  $subgather1->just('patch')->then('patch-456');
  $subgather1->just('punch')->then('punch-789');

  my $subgather2 = $gather->expr(qr/^m([a-z]+)ch/)->where;

  $subgather2->just('merch')->then('merch-123');
  $subgather2->just('march')->then('march-456');
  $subgather2->just('mouch')->then('mouch-789');

  my $result = $gather->result(['peach', 'preach']);

  # ["peach-123"]

=back

=over 4

=item where example 2

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new;

  my $subgather1 = $gather->expr(qr/^p([a-z]+)ch/)->where;

  $subgather1->just('peach')->then('peach-123');
  $subgather1->just('patch')->then('patch-456');
  $subgather1->just('punch')->then('punch-789');

  my $subgather2 = $gather->expr(qr/^m([a-z]+)ch/)->where;

  $subgather2->just('merch')->then('merch-123');
  $subgather2->just('march')->then('march-456');
  $subgather2->just('mouch')->then('mouch-789');

  my $result = $gather->result(['march', 'merch']);

  # ["march-456", "merch-123"]

=back

=over 4

=item where example 3

  package main;

  use Venus::Gather;

  my $gather = Venus::Gather->new;

  my $subgather1 = $gather->expr(qr/^p([a-z]+)ch/)->where;

  $subgather1->just('peach')->then('peach-123');
  $subgather1->just('patch')->then('patch-456');
  $subgather1->just('punch')->then('punch-789');

  my $subgather2 = $gather->expr(qr/^m([a-z]+)ch/)->where;

  $subgather2->just('merch')->then('merch-123');
  $subgather2->just('march')->then('march-456');
  $subgather2->just('mouch')->then('mouch-789');

  my $result = $gather->result(['pirch']);

  # []

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut