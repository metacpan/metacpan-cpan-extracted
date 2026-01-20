package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Set

=cut

$test->for('name');

=tagline

Set Class

=cut

$test->for('tagline');

=abstract

Set Class for Perl 5

=cut

$test->for('abstract');

=includes

method: all
method: any
method: attest
method: call
method: contains
method: count
method: default
method: delete
method: difference
method: different
method: each
method: empty
method: exists
method: first
method: get
method: grep
method: head
method: iterator
method: intersection
method: intersect
method: join
method: keyed
method: keys
method: last
method: length
method: list
method: map
method: merge
method: new
method: none
method: one
method: order
method: pairs
method: part
method: pop
method: push
method: random
method: range
method: reverse
method: rotate
method: rsort
method: set
method: shift
method: shuffle
method: slice
method: sort
method: subset
method: superset
method: tail
method: unique
method: unshift

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Set;

  my $set = Venus::Set->new([1,1,2,2,3,3,4,4,5..9]);

  # $set->count;

  # 4

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Set');

  $result
});

=description

This package provides a representation of a collection of ordered unique values
and methods for validating and manipulating it.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Mappable
Venus::Role::Encaseable

=cut

$test->for('integrates');

=attribute accept

The accept attribute is read-write, accepts C<(string)> values, and is
optional.

=signature accept

  accept(string $data) (string)

=metadata accept

{
  since => '4.11',
}

=cut

=example-1 accept

  # given: synopsis

  package main;

  my $set_accept = $set->accept("number");

  # "number"

=cut

$test->for('example', 1, 'accept', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "number";

  $result
});

=example-2 accept

  # given: synopsis

  # given: example-1 accept

  package main;

  my $get_accept = $set->accept;

  # "number"

=cut

$test->for('example', 2, 'accept', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "number";

  $result
});

=method all

The all method returns true if the callback returns true for all of the
elements.

=signature all

  all(coderef $code) (boolean)

=metadata all

{
  since => '4.11',
}

=example-1 all

  # given: synopsis;

  my $all = $set->all(sub {
    $_ > 0;
  });

  # 1

=cut

$test->for('example', 1, 'all', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 all

  # given: synopsis;

  my $all = $set->all(sub {
    my ($key, $value) = @_;

    $value > 0;
  });

  # 1

=cut

$test->for('example', 2, 'all', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method any

The any method returns true if the callback returns true for any of the
elements.

=signature any

  any(coderef $code) (boolean)

=metadata any

{
  since => '4.11',
}

=example-1 any

  # given: synopsis;

  my $any = $set->any(sub {
    $_ > 4;
  });

=cut

$test->for('example', 1, 'any', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 any

  # given: synopsis;

  my $any = $set->any(sub {
    my ($key, $value) = @_;

    $value > 4;
  });

=cut

$test->for('example', 2, 'any', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method attest

The attest method validates the values using the L<Venus::Assert> expression in
the L</accept> attribute and returns the result.

=signature attest

  attest() (any)

=metadata attest

{
  since => '4.11',
}

=cut

=example-1 attest

  # given: synopsis

  package main;

  my $attest = $set->attest;

  # [1..9]

=cut

$test->for('example', 1, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, [1..9];

  $result
});

=example-2 attest

  # given: synopsis

  package main;

  $set->accept('number | object');

  my $attest = $set->attest;

  # [1..9]

=cut

$test->for('example', 2, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, [1..9];

  $result
});

=example-3 attest

  # given: synopsis

  package main;

  $set->accept('string');

  my $attest = $set->attest;

  # Exception! (isa Venus::Check::Error)

=cut

$test->for('example', 3, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  ok defined $result;
  ok $result->isa('Venus::Check::Error');

  $result
});

=example-4 attest

  # given: synopsis

  package main;

  $set->accept('number');

  my $attest = $set->attest;

  # [1..9]

=cut

$test->for('example', 4, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, [1..9];

  $result
});

=method call

The call method executes the given method (named using the first argument)
which performs an iteration (i.e. takes a callback) and calls the method (named
using the second argument) on the object (or value) and returns the result of
the iterable method.

=signature call

  call(string $iterable, string $method) (any)

=metadata call

{
  since => '4.11',
}

=example-1 call

  # given: synopsis

  package main;

  my $call = $set->call('map', 'incr');

  # [2..10]

=cut

$test->for('example', 1, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2..10];

  $result
});

=example-2 call

  # given: synopsis

  package main;

  my $call = $set->call('grep', 'gt', 4);

  # [4..9]

=cut

$test->for('example', 2, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [5..9];

  $result
});

=method contains

The contains method returns true if the value provided already exists in the
set, otherwise it returns false.

=signature contains

  contains(any $value) (boolean)

=metadata contains

{
  since => '4.11',
}

=example-1 contains

  # given: synopsis;

  my $contains = $set->contains(1);

  # true

=cut

$test->for('example', 1, 'contains', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 contains

  # given: synopsis;

  my $contains = $set->contains(0);

  # false

=cut

$test->for('example', 2, 'contains', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=method count

The count method returns the number of elements within the set.

=signature count

  count() (number)

=metadata count

{
  since => '4.11',
}

=example-1 count

  # given: synopsis;

  my $count = $set->count;

  # 9

=cut

$test->for('example', 1, 'count', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 9;

  $result
});

=method default

The default method returns the default value, i.e. C<[]>.

=signature default

  default() (arrayref)

=metadata default

{
  since => '4.11',
}

=example-1 default

  # given: synopsis;

  my $default = $set->default;

  # []

=cut

$test->for('example', 1, 'default', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=method delete

The delete method returns the value of the element at the index specified after
removing it from the set.

=signature delete

  delete(number $index) (any)

=metadata delete

{
  since => '4.11',
}

=example-1 delete

  # given: synopsis;

  my $delete = $set->delete(2);

  # 3

=cut

$test->for('example', 1, 'delete', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 3;

  $result
});

=method difference

The difference method returns a new set containing only the values that don't
exist in the source.

=signature difference

  difference(arrayref | Venus::Array | Venus::Set $data) (Venus::Set)

=metadata difference

{
  since => '4.11',
}

=cut

=example-1 difference

  # given: synopsis

  package main;

  my $difference = $set->difference([9, 10, 11]);

  # bless(..., "Venus::Set")

  # $difference->list;

  # [10, 11]

=cut

$test->for('example', 1, 'difference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is $result->count, 2;
  is_deeply $result->get, [10, 11];

  $result
});

=example-2 difference

  # given: synopsis

  package main;

  my $difference = $set->difference(Venus::Set->new([9, 10, 11]));

  # bless(..., "Venus::Set")

  # $difference->list;

  # [10, 11]

=cut

$test->for('example', 2, 'difference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is $result->count, 2;
  is_deeply $result->get, [10, 11];

  $result
});

=example-3 difference

  # given: synopsis

  package main;

  use Venus::Array;

  my $difference = $set->difference(Venus::Array->new([9, 10, 11]));

  # bless(..., "Venus::Set")

  # $difference->list;

  # [10, 11]

=cut

$test->for('example', 3, 'difference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is $result->count, 2;
  is_deeply $result->get, [10, 11];

  $result
});

=method different

The different method returns true if the values provided don't exist in the
source.

=signature different

  different(arrayref | Venus::Array | Venus::Set $data) (boolean)

=metadata different

{
  since => '4.11',
}

=cut

=example-1 different

  # given: synopsis

  package main;

  my $different = $set->different([1..10]);

  # true

=cut

$test->for('example', 1, 'different', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-2 different

  # given: synopsis

  package main;

  my $different = $set->different([1..9]);

  # false

=cut

$test->for('example', 2, 'different', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=method each

The each method executes a callback for each element in the set passing the
index and value as arguments. This method can return a list of values in
list-context.

=signature each

  each(coderef $code) (arrayref)

=metadata each

{
  since => '4.11',
}

=example-1 each

  # given: synopsis;

  my $each = $set->each(sub {
    [$_]
  });

  # [[1], [2], [3], [4], [5], [6], [7], [8], [9]]

=cut

$test->for('example', 1, 'each', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [[1], [2], [3], [4], [5], [6], [7], [8], [9]];

  $result
});

=example-2 each

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

=cut

$test->for('example', 2, 'each', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 6],
    [6, 7],
    [7, 8],
    [8, 9],
  ];

  $result
});

=method empty

The empty method drops all elements from the set.

=signature empty

  empty() (Venus::Array)

=metadata empty

{
  since => '4.11',
}

=example-1 empty

  # given: synopsis;

  my $empty = $set->empty;

  # bless({}, "Venus::Set")

=cut

$test->for('example', 1, 'empty', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->value, [];

  $result
});

=method exists

The exists method returns true if the element at the index specified exists,
otherwise it returns false.

=signature exists

  exists(number $index) (boolean)

=metadata exists

{
  since => '4.11',
}

=example-1 exists

  # given: synopsis;

  my $exists = $set->exists(0);

  # true

=cut

$test->for('example', 1, 'exists', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method first

The first method returns the value of the first element.

=signature first

  first() (any)

=metadata first

{
  since => '4.11',
}

=example-1 first

  # given: synopsis;

  my $first = $set->first;

  # 1

=cut

$test->for('example', 1, 'first', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method get

The get method returns the value at the position specified.

=signature get

  get(number $index) (any)

=metadata get

{
  since => '4.11',
}

=cut

=example-1 get

  # given: synopsis

  package main;

  my $get = $set->get(0);

  # 1

=cut

$test->for('example', 1, 'get', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-2 get

  # given: synopsis

  package main;

  my $get = $set->get(3);

  # 4

=cut

$test->for('example', 2, 'get', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 4;

  $result
});

=method grep

The grep method executes a callback for each element in the array passing the
value as an argument, returning a new array reference containing the elements
for which the returned true. This method can return a list of values in
list-context.

=signature grep

  grep(coderef $code) (arrayref)

=metadata grep

{
  since => '4.11',
}

=example-1 grep

  # given: synopsis;

  my $grep = $set->grep(sub {
    $_ > 3
  });

  # [4..9]

=cut

$test->for('example', 1, 'grep', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [4..9];

  $result
});

=example-2 grep

  # given: synopsis;

  my $grep = $set->grep(sub {
    my ($key, $value) = @_;

    $value > 3
  });

  # [4..9]

=cut

$test->for('example', 2, 'grep', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [4..9];

  $result
});

=method head

The head method returns the topmost elements, limited by the desired size
specified.

=signature head

  head(number $size) (arrayref)

=metadata head

{
  since => '4.11',
}

=example-1 head

  # given: synopsis;

  my $head = $set->head;

  # [1]

=cut

$test->for('example', 1, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [1];

  $result
});

=example-2 head

  # given: synopsis;

  my $head = $set->head(1);

  # [1]

=cut

$test->for('example', 2, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [1];

  $result
});

=example-3 head

  # given: synopsis;

  my $head = $set->head(2);

  # [1,2]

=cut

$test->for('example', 3, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [1,2];

  $result
});

=example-4 head

  # given: synopsis;

  my $head = $set->head(5);

  # [1..5]

=cut

$test->for('example', 4, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [1,2,3,4,5];

  $result
});

=example-5 head

  # given: synopsis;

  my $head = $set->head(20);

  # [1..9]

=cut

$test->for('example', 5, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [1,2,3,4,5,6,7,8,9];

  $result
});

=method iterator

The iterator method returns a code reference which can be used to iterate over
the array. Each time the iterator is executed it will return the next element
in the array until all elements have been seen, at which point the iterator
will return an undefined value. This method can return a tuple with the key and
value in list-context.

=signature iterator

  iterator() (coderef)

=metadata iterator

{
  since => '4.11',
}

=example-1 iterator

  # given: synopsis;

  my $iterator = $set->iterator;

  # sub { ... }

  # while (my $value = $iterator->()) {
  #   say $value; # 1
  # }

=cut

$test->for('example', 1, 'iterator', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  while (my $value = $result->()) {
    ok $value =~ m{\d};
  }

  $result
});

=example-2 iterator

  # given: synopsis;

  my $iterator = $set->iterator;

  # sub { ... }

  # while (grep defined, my ($key, $value) = $iterator->()) {
  #   say $value; # 1
  # }

=cut

$test->for('example', 2, 'iterator', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  while (grep defined, my ($key, $value) = $result->()) {
    ok $key =~ m{\d};
    ok $value =~ m{\d};
  }

  $result
});

=method intersection

The intersection method returns a new set containing only the values that
already exist in the source.

=signature intersection

  intersection(arrayref | Venus::Array | Venus::Set $data) (Venus::Set)

=metadata intersection

{
  since => '4.11',
}

=cut

=example-1 intersection

  # given: synopsis

  package main;

  $set->push(10);

  my $intersection = $set->intersection([9, 10, 11]);

  # bless(..., "Venus::Set")

  # $intersection->list;

  # [9, 10]

=cut

$test->for('example', 1, 'intersection', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is $result->count, 2;
  is_deeply $result->get, [9, 10];

  $result
});

=example-2 intersection

  # given: synopsis

  package main;

  $set->push(10);

  my $intersection = $set->intersection(Venus::Set->new([9, 10, 11]));

  # bless(..., "Venus::Set")

  # $intersection->list;

  # [9, 10]

=cut

$test->for('example', 2, 'intersection', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is $result->count, 2;
  is_deeply $result->get, [9, 10];

  $result
});

=example-3 intersection

  # given: synopsis

  package main;

  use Venus::Array;

  $set->push(10);

  my $intersection = $set->intersection(Venus::Array->new([9, 10, 11]));

  # bless(..., "Venus::Set")

  # $intersection->list;

  # [9, 10]

=cut

$test->for('example', 3, 'intersection', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is $result->count, 2;
  is_deeply $result->get, [9, 10];

  $result
});

=method intersect

The intersect method returns true if the values provided already exist in the
source.

=signature intersect

  intersect(arrayref | Venus::Array | Venus::Set $data) (boolean)

=metadata intersect

{
  since => '4.11',
}

=cut

=example-1 intersect

  # given: synopsis

  package main;

  my $intersect = $set->intersect([9, 10]);

  # true

=cut

$test->for('example', 1, 'intersect', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-2 intersect

  # given: synopsis

  package main;

  my $intersect = $set->intersect([10, 11]);

  # false

=cut

$test->for('example', 2, 'intersect', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=method join

The join method returns a string consisting of all the elements in the array
joined by the join-string specified by the argument. Note: If the argument is
omitted, an empty string will be used as the join-string.

=signature join

  join(string $seperator) (string)

=metadata join

{
  since => '4.11',
}

=example-1 join

  # given: synopsis;

  my $join = $set->join;

  # 123456789

=cut

$test->for('example', 1, 'join', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 123456789;

  $result
});

=example-2 join

  # given: synopsis;

  my $join = $set->join(', ');

  # "1, 2, 3, 4, 5, 6, 7, 8, 9"

=cut

$test->for('example', 2, 'join', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "1, 2, 3, 4, 5, 6, 7, 8, 9";

  $result
});

=method keyed

The keyed method returns a hash reference where the arguments become the keys,
and the elements of the array become the values.

=signature keyed

  keyed(string @keys) (hashref)

=metadata keyed

{
  since => '4.11',
}

=example-1 keyed

  package main;

  use Venus::Array;

  my $set = Venus::Array->new([1..4]);

  my $keyed = $set->keyed('a'..'d');

  # { a => 1, b => 2, c => 3, d => 4 }

=cut

$test->for('example', 1, 'keyed', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, { a => 1, b => 2, c => 3, d => 4 };

  $result
});

=method keys

The keys method returns an array reference consisting of the indicies of the
array.

=signature keys

  keys() (arrayref)

=metadata keys

{
  since => '4.11',
}

=example-1 keys

  # given: synopsis;

  my $keys = $set->keys;

  # [0..8]

=cut

$test->for('example', 1, 'keys', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [0..8];

  $result
});

=method last

The last method returns the value of the last element in the array.

=signature last

  last() (any)

=metadata last

{
  since => '4.11',
}

=example-1 last

  # given: synopsis;

  my $last = $set->last;

  # 9

=cut

$test->for('example', 1, 'last', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 9;

  $result
});

=method length

The length method returns the number of elements within the array, and is an
alias for the L</count> method.

=signature length

  length() (number)

=metadata length

{
  since => '4.11',
}

=example-1 length

  # given: synopsis;

  my $length = $set->length;

  # 9

=cut

$test->for('example', 1, 'length', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, 9;

  $result
});

=method list

The list method returns a shallow copy of the underlying array reference as an
array reference.

=signature list

  list() (any)

=metadata list

{
  since => '4.11',
}

=example-1 list

  # given: synopsis;

  my $list = $set->list;

  # 9

=cut

$test->for('example', 1, 'list', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 9;

  $result
});

=example-2 list

  # given: synopsis;

  my @list = $set->list;

  # (1..9)

=cut

$test->for('example', 2, 'list', sub {
  my ($tryable) = @_;
  ok my @result = $tryable->result;
  is_deeply [@result], [1..9];

  @result
});

=method map

The map method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing the
elements for which the argument returns a value or non-empty list. This method
can return a list of values in list-context.

=signature map

  map(coderef $code) (arrayref)

=metadata map

{
  since => '4.11',
}

=example-1 map

  # given: synopsis;

  my $map = $set->map(sub {
    $_ * 2
  });

  # [2, 4, 6, 8, 10, 12, 14, 16, 18]

=cut

$test->for('example', 1, 'map', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result,[2, 4, 6, 8, 10, 12, 14, 16, 18];

  $result
});

=example-2 map

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

=cut

$test->for('example', 2, 'map', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    [0, 2],
    [1, 4],
    [2, 6],
    [3, 8],
    [4, 10],
    [5, 12],
    [6, 14],
    [7, 16],
    [8, 18],
  ];

  $result
});

=method merge

The merge method merges the arguments provided with the existing set.

=signature merge

  merge(any @data) (Venus::Set)

=metadata merge

{
  since => '4.11',
}

=example-1 merge

  # given: synopsis;

  my $merge = $set->merge(6..9);

  # bless(..., "Venus::Set")

  # $set->list;

  # [1..9]

=cut

$test->for('example', 1, 'merge', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply scalar($result->get), [1..9];

  $result
});

=example-2 merge

  # given: synopsis;

  my $merge = $set->merge(8, 10);

  # bless(..., "Venus::Set")

  # $set->list;

  # [1..10]

=cut

$test->for('example', 2, 'merge', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply scalar($result->get), [1..10];

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Set)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Set;

  my $new = Venus::Set->new;

  # bless(..., "Venus::Set")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->value, [];

  $result
});

=example-2 new

  package main;

  use Venus::Set;

  my $new = Venus::Set->new([1,1,2,2,3,3,4,4,5..9]);

  # bless(..., "Venus::Set")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->value, [1..9];

  $result
});

=example-3 new

  package main;

  use Venus::Set;

  my $new = Venus::Set->new(value => [1,1,2,2,3,3,4,4,5..9]);

  # bless(..., "Venus::Set")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->value, [1..9];

  $result
});

=method none

The none method returns true if none of the elements in the array meet the
criteria set by the operand and rvalue.

=signature none

  none(coderef $code) (boolean)

=metadata none

{
  since => '4.11',
}

=example-1 none

  # given: synopsis;

  my $none = $set->none(sub {
    $_ < 1
  });

  # 1

=cut

$test->for('example', 1, 'none', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 none

  # given: synopsis;

  my $none = $set->none(sub {
    my ($key, $value) = @_;

    $value < 1
  });

  # 1

=cut

$test->for('example', 2, 'none', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method one

The one method returns true if only one of the elements in the array meet the
criteria set by the operand and rvalue.

=signature one

  one(coderef $code) (boolean)

=metadata one

{
  since => '4.11',
}

=example-1 one

  # given: synopsis;

  my $one = $set->one(sub {
    $_ == 1
  });

  # 1

=cut

$test->for('example', 1, 'one', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 one

  # given: synopsis;

  my $one = $set->one(sub {
    my ($key, $value) = @_;

    $value == 1
  });

  # 1

=cut

$test->for('example', 2, 'one', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method order

The order method reorders the array items based on the indices provided and
returns the invocant.

=signature order

  order(number @indices) (Venus::Set)

=metadata order

{
  since => '4.11',
}

=example-1 order

  # given: synopsis;

  my $order = $set->order;

  # bless(..., "Venus::Set")

  # $set->list;

  # [1..9]

=cut

$test->for('example', 1, 'order', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result->get, [1..9];

  $result
});

=example-2 order

  # given: synopsis;

  my $order = $set->order(8,7,6);

  # bless(..., "Venus::Set")

  # $set->list;

  # [9,8,7,1,2,3,4,5,6]

=cut

$test->for('example', 2, 'order', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result->get, [9,8,7,1,2,3,4,5,6];

  $result
});

=example-3 order

  # given: synopsis;

  my $order = $set->order(0,2,1);

  # bless(..., "Venus::Set")

  # $set->list;

  # [1,3,2,4,5,6,7,8,9]

=cut

$test->for('example', 3, 'order', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result->get, [1,3,2,4,5,6,7,8,9];

  $result
});

=method pairs

The pairs method is an alias to the pairs_array method. This method can return
a list of values in list-context.

=signature pairs

  pairs() (arrayref)

=metadata pairs

{
  since => '4.11',
}

=example-1 pairs

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

=cut

$test->for('example', 1, 'pairs', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 6],
    [6, 7],
    [7, 8],
    [8, 9],
  ];

  $result
});

=method part

The part method iterates over each element in the array, executing the code
reference supplied in the argument, using the result of the code reference to
partition to array into two distinct array references. This method can return a
list of values in list-context.

=signature part

  part(coderef $code) (tuple[arrayref, arrayref])

=metadata part

{
  since => '4.11',
}

=example-1 part

  # given: synopsis;

  my $part = $set->part(sub {
    $_ > 5
  });

  # [[6..9], [1..5]]

=cut

$test->for('example', 1, 'part', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [[6..9], [1..5]];

  $result
});

=example-2 part

  # given: synopsis;

  my $part = $set->part(sub {
    my ($key, $value) = @_;

    $value < 5
  });

  # [[1..4], [5..9]]

=cut

$test->for('example', 2, 'part', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [[1..4], [5..9]];

  $result
});

=method pop

The pop method returns the last element of the array shortening it by one.
Note, this method modifies the array.

=signature pop

  pop() (any)

=metadata pop

{
  since => '4.11',
}

=example-1 pop

  # given: synopsis;

  my $pop = $set->pop;

  # 9

=cut

$test->for('example', 1, 'pop', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 9;

  $result
});

=method push

The push method appends the array by pushing the agruments onto it and returns
itself.

=signature push

  push(any @data) (arrayref)

=metadata push

{
  since => '4.11',
}

=example-1 push

  # given: synopsis;

  my $push = $set->push(10);

  # [1..10]

=cut

$test->for('example', 1, 'push', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [1..10];

  $result
});

=method random

The random method returns a random element from the array.

=signature random

  random() (any)

=metadata random

{
  since => '4.11',
}

=example-1 random

  # given: synopsis;

  my $random = $set->random;

  # 2

  # my $random = $set->random;

  # 1

=cut

$test->for('example', 1, 'random', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=method range

The range method accepts a I<"range expression"> and returns the result of
calling the L</slice> method with the computed range.

=signature range

  range(number | string @args) (arrayref)

=metadata range

{
  since => '4.11',
}

=cut

=example-1 range

  # given: synopsis

  package main;

  my $range = $set->range;

  # []

=cut

$test->for('example', 1, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 range

  # given: synopsis

  package main;

  my $range = $set->range(0);

  # [1]

=cut

$test->for('example', 2, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1];

  $result
});

=example-3 range

  # given: synopsis

  package main;

  my $range = $set->range('0:');

  # [1..9]

=cut

$test->for('example', 3, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..9];

  $result
});

=example-4 range

  # given: synopsis

  package main;

  my $range = $set->range(':4');

  # [1..5]

=cut

$test->for('example', 4, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..5];

  $result
});

=example-5 range

  # given: synopsis

  package main;

  my $range = $set->range('8:');

  # [9]

=cut

$test->for('example', 5, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [9];

  $result
});

=example-6 range

  # given: synopsis

  package main;

  my $range = $set->range('4:');

  # [5..9]

=cut

$test->for('example', 6, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [5..9];

  $result
});

=example-7 range

  # given: synopsis

  package main;

  my $range = $set->range('0:2');

  # [1..3]

=cut

$test->for('example', 7, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..3];

  $result
});

=example-8 range

  # given: synopsis

  package main;

  my $range = $set->range('2:4');

  # [3..5]

=cut

$test->for('example', 8, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [3..5];

  $result
});

=example-9 range

  # given: synopsis

  package main;

  my $range = $set->range(0..3);

  # [1..4]

=cut

$test->for('example', 9, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..4];

  $result
});

=example-10 range

  # given: synopsis

  package main;

  my $range = $set->range('-1:8');

  # [9]

=cut

$test->for('example', 10, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [9];

  $result
});

=example-11 range

  # given: synopsis

  package main;

  my $range = $set->range('0:8');

  # [1..9]

=cut

$test->for('example', 11, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..9];

  $result
});

=example-12 range

  # given: synopsis

  package main;

  my $range = $set->range('0:-2');

  # [1..8]

=cut

$test->for('example', 12, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..8];

  $result
});

=example-13 range

  # given: synopsis

  package main;

  my $range = $set->range('-2:-2');

  # [8]

=cut

$test->for('example', 13, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [8];

  $result
});

=example-14 range

  # given: synopsis

  package main;

  my $range = $set->range('0:-20');

  # []

=cut

$test->for('example', 14, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-15 range

  # given: synopsis

  package main;

  my $range = $set->range('-2:-20');

  # []

=cut

$test->for('example', 15, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-16 range

  # given: synopsis

  package main;

  my $range = $set->range('-2:-6');

  # []

=cut

$test->for('example', 16, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-17 range

  # given: synopsis

  package main;

  my $range = $set->range('-2:-8');

  # []

=cut

$test->for('example', 17, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-18 range

  # given: synopsis

  package main;

  my $range = $set->range('-2:-9');

  # []

=cut

$test->for('example', 18, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-19 range

  # given: synopsis

  package main;

  my $range = $set->range('-5:-1');

  # [5..9]

=cut

$test->for('example', 19, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [5..9];

  $result
});

=method reverse

The reverse method returns an array reference containing the elements in the
array in reverse order.

=signature reverse

  reverse() (arrayref)

=metadata reverse

{
  since => '4.11',
}

=example-1 reverse

  # given: synopsis;

  my $reverse = $set->reverse;

  # [9, 8, 7, 6, 5, 4, 3, 2, 1]

=cut

$test->for('example', 1, 'reverse', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [9, 8, 7, 6, 5, 4, 3, 2, 1];

  $result
});

=method rotate

The rotate method rotates the elements in the array such that first elements
becomes the last element and the second element becomes the first element each
time this method is called.

=signature rotate

  rotate() (arrayref)

=metadata rotate

{
  since => '4.11',
}

=example-1 rotate

  # given: synopsis;

  my $rotate = $set->rotate;

  # [2..9, 1]

=cut

$test->for('example', 1, 'rotate', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2..9, 1];

  $result
});

=method rsort

The rsort method returns an array reference containing the values in the array
sorted alphanumerically in reverse.

=signature rsort

  rsort() (arrayref)

=metadata rsort

{
  since => '4.11',
}

=example-1 rsort

  # given: synopsis;

  my $rsort = $set->rsort;

  # [9, 8, 7, 6, 5, 4, 3, 2, 1]

=cut

$test->for('example', 1, 'rsort', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [9, 8, 7, 6, 5, 4, 3, 2, 1];

  $result
});

=method set

The set method inserts a new value into the set if it doesn't exist.

=signature set

  set(any $value) (any)

=metadata set

{
  since => '4.11',
}

=cut

=example-1 set

  # given: synopsis

  package main;

  $set = $set->set(10);

  # 10

=cut

$test->for('example', 1, 'set', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 10;

  $result
});

=example-2 set

  # given: synopsis

  package main;

  $set = $set->set(0);

  # 0

=cut

$test->for('example', 2, 'set', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=method shift

The shift method returns the first element of the array shortening it by one.

=signature shift

  shift() (any)

=metadata shift

{
  since => '4.11',
}

=example-1 shift

  # given: synopsis;

  my $shift = $set->shift;

  # 1

=cut

$test->for('example', 1, 'shift', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method shuffle

The shuffle method returns an array with the items in a randomized order.

=signature shuffle

  shuffle() (arrayref)

=metadata shuffle

{
  since => '4.11',
}

=example-1 shuffle

  # given: synopsis

  package main;

  my $shuffle = $set->shuffle;

  # [4, 5, 8, 7, 2, 9, 6, 3, 1]

=cut

$test->for('example', 1, 'shuffle', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  isnt "@$result", "1 2 3 4 5 6 7 8 9";

  $result
});

=method slice

The slice method returns a hash reference containing the elements in the array
at the index(es) specified in the arguments.

=signature slice

  slice(string @keys) (arrayref)

=metadata slice

{
  since => '4.11',
}

=example-1 slice

  # given: synopsis;

  my $slice = $set->slice(2, 4);

  # [3, 5]

=cut

$test->for('example', 1, 'slice', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [3, 5];

  $result
});

=method sort

The sort method returns an array reference containing the values in the array
sorted alphanumerically.

=signature sort

  sort() (arrayref)

=metadata sort

{
  since => '4.11',
}

=example-1 sort

  package main;

  use Venus::Set;

  my $set = Venus::Set->new(['d','c','b','a']);

  my $sort = $set->sort;

  # ["a".."d"]

=cut

$test->for('example', 1, 'sort', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["a".."d"];

  $result
});

=method tail

The tail method returns the bottommost elements, limited by the desired size
specified.

=signature tail

  tail(number $size) (arrayref)

=metadata tail

{
  since => '4.11',
}

=example-1 tail

  # given: synopsis;

  my $tail = $set->tail;

  # [9]

=cut

$test->for('example', 1, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [9];

  $result
});

=example-2 tail

  # given: synopsis;

  my $tail = $set->tail(1);

  # [9]

=cut

$test->for('example', 2, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [9];

  $result
});

=example-3 tail

  # given: synopsis;

  my $tail = $set->tail(2);

  # [8,9]

=cut

$test->for('example', 3, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [8,9];

  $result
});

=example-4 tail

  # given: synopsis;

  my $tail = $set->tail(5);

  # [5..9]

=cut

$test->for('example', 4, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [5..9];

  $result
});

=example-5 tail

  # given: synopsis;

  my $tail = $set->tail(20);

  # [1..9]

=cut

$test->for('example', 5, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [1,2,3,4,5,6,7,8,9];

  $result
});

=method subset

The subset method returns true if all the values provided already exist in the
source.

=signature subset

  subset(arrayref | Venus::Array | Venus::Set $data) (boolean)

=metadata subset

{
  since => '4.11',
}

=cut

=example-1 subset

  # given: synopsis

  package main;

  my $subset = $set->subset([1..4]);

  # true

=cut

$test->for('example', 1, 'subset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-2 subset

  # given: synopsis

  package main;

  my $subset = $set->subset([1..10]);

  # false

=cut

$test->for('example', 2, 'subset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-3 subset

  # given: synopsis

  package main;

  my $subset = $set->subset([1..9]);

  # true

=cut

$test->for('example', 1, 'subset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method superset

The superset method returns true if all the values in the source exists in the
values provided.

=signature superset

  superset(arrayref | Venus::Array | Venus::Set $data) (boolean)

=metadata superset

{
  since => '4.11',
}

=cut

=example-1 superset

  # given: synopsis

  package main;

  my $superset = $set->superset([1..10]);

  # true

=cut

$test->for('example', 1, 'superset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-2 superset

  # given: synopsis

  package main;

  my $superset = $set->superset([1..9]);

  # false

=cut

$test->for('example', 2, 'superset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-3 superset

  # given: synopsis

  package main;

  my $superset = $set->superset([0..9]);

  # true

=cut

$test->for('example', 1, 'superset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method unique

The unique method returns an array reference consisting of the unique elements
in the array.

=signature unique

  unique() (arrayref)

=metadata unique

{
  since => '4.11',
}

=example-1 unique

  package main;

  use Venus::Set;

  my $set = Venus::Set->new([1,1,1,1,2,3,1]);

  my $unique = $set->unique;

  # [1, 2, 3]

=cut

$test->for('example', 1, 'unique', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [1, 2, 3];

  $result
});

=method unshift

The unshift method prepends the array by pushing the agruments onto it and
returns itself.

=signature unshift

  unshift(any @data) (arrayref)

=metadata unshift

{
  since => '4.11',
}

=example-1 unshift

  # given: synopsis;

  my $unshift = $set->unshift(-2,-1,0);

  # [-2..9]

=cut

$test->for('example', 1, 'unshift', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [-2..9];

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Set.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
