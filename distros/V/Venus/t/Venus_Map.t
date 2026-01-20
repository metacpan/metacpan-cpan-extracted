package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Map

=cut

$test->for('name');

=tagline

Map Class

=cut

$test->for('tagline');

=abstract

Map Class for Perl 5

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
method: values

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Map;

  my $map = Venus::Map->new({1..8});

  # $map->count;

  # 4

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Map');

  $result
});

=description

This package provides a representation of a collection of ordered key/value
pairs and methods for validating and manipulating it.

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

  my $map_accept = $map->accept("number");

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

  my $get_accept = $map->accept;

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

  my $all = $map->all(sub {
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

  my $all = $map->all(sub {
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

  my $any = $map->any(sub {
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

  my $any = $map->any(sub {
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

  my $attest = $map->attest;

  # {1..8}

=cut

$test->for('example', 1, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, {1..8};

  $result
});

=example-2 attest

  # given: synopsis

  package main;

  $map->accept('number | object');

  my $attest = $map->attest;

  # {1..8}

=cut

$test->for('example', 2, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, {1..8};

  $result
});

=example-3 attest

  # given: synopsis

  package main;

  $map->accept('string');

  my $attest = $map->attest;

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

  $map->accept('number');

  my $attest = $map->attest;

  # {1..8}

=cut

$test->for('example', 4, 'attest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, {1..8};

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

  package main;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $call = $map->call('map', 'incr');

  # [3,5,7,9]

=cut

$test->for('example', 1, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [3,5,7,9];

  $result
});

=example-2 call

  package main;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $call = $map->call('grep', 'gt', 4);

  # [6,8]

=cut

$test->for('example', 2, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [6,8];

  $result
});

=method contains

The contains method returns true if the value provided already exists in the
map, otherwise it returns false.

=signature contains

  contains(any $value) (boolean)

=metadata contains

{
  since => '4.11',
}

=example-1 contains

  # given: synopsis;

  my $contains = $map->contains(2);

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

  my $contains = $map->contains(0);

  # false

=cut

$test->for('example', 2, 'contains', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=method count

The count method returns the number of elements within the map.

=signature count

  count() (number)

=metadata count

{
  since => '4.11',
}

=example-1 count

  # given: synopsis;

  my $count = $map->count;

  # 9

=cut

$test->for('example', 1, 'count', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 4;

  $result
});

=method default

The default method returns the default value, i.e. C<{}>.

=signature default

  default() (hashref)

=metadata default

{
  since => '4.11',
}

=example-1 default

  # given: synopsis;

  my $default = $map->default;

  # {}

=cut

$test->for('example', 1, 'default', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=method delete

The delete method returns the value of the element corresponding to the key specified after
removing it from the map.

=signature delete

  delete(string $key) (any)

=metadata delete

{
  since => '4.11',
}

=example-1 delete

  # given: synopsis;

  my $delete = $map->delete(1);

  # 2

=cut

$test->for('example', 1, 'delete', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 2;

  $result
});

=method difference

The difference method returns a new map containing only the values that don't
exist in the source.

=signature difference

  difference(hashref | Venus::Hash | Venus::Map $data) (Venus::Map)

=metadata difference

{
  since => '4.11',
}

=cut

=example-1 difference

  # given: synopsis

  package main;

  my $difference = $map->difference({7..10});

  # bless(..., "Venus::Map")

  # $difference->list;

  # [10]

=cut

$test->for('example', 1, 'difference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is $result->count, 1;
  is_deeply $result->get, {9,10};

  $result
});

=example-2 difference

  # given: synopsis

  package main;

  my $difference = $map->difference(Venus::Map->new({7,8,9,10,11,12}));

  # bless(..., "Venus::Map")

  # $difference->list;

  # [10, 12]

=cut

$test->for('example', 2, 'difference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is $result->count, 2;
  is_deeply $result->get, {9,10,11,12};

  $result
});

=example-3 difference

  # given: synopsis

  package main;

  use Venus::Hash;

  my $difference = $map->difference(Venus::Hash->new({7,8,9,10,11,12}));

  # bless(..., "Venus::Map")

  # $difference->list;

  # [10, 12]

=cut

$test->for('example', 3, 'difference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is $result->count, 2;
  is_deeply $result->get, {9,10,11,12};

  $result
});

=method different

The different method returns true if the values provided don't exist in the
source.

=signature different

  different(hashref | Venus::Hash | Venus::Map $data) (boolean)

=metadata different

{
  since => '4.11',
}

=cut

=example-1 different

  # given: synopsis

  package main;

  my $different = $map->different({1..10});

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

  my $different = $map->different({1..8});

  # false

=cut

$test->for('example', 2, 'different', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=method each

The each method executes a callback for each element in the map passing the
key and value as arguments. This method can return a list of values in
list-context.

=signature each

  each(coderef $code) (hashref)

=metadata each

{
  since => '4.11',
}

=example-1 each

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $each = $map->each(sub {
    [$_]
  });

  # [[2], [4], [6], [8]]

=cut

$test->for('example', 1, 'each', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [[2], [4], [6], [8]];

  $result
});

=example-2 each

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

=cut

$test->for('example', 2, 'each', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    [8, 7],
    [6, 5],
    [4, 3],
    [2, 1],
  ];

  $result
});

=method empty

The empty method drops all elements from the map.

=signature empty

  empty() (Venus::Hash)

=metadata empty

{
  since => '4.11',
}

=example-1 empty

  # given: synopsis;

  my $empty = $map->empty;

  # bless({}, "Venus::Map")

=cut

$test->for('example', 1, 'empty', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->value, {};

  $result
});

=method exists

The exists method returns true if the element corresponding with the key
specified exists, otherwise it returns false.

=signature exists

  exists(string $key) (boolean)

=metadata exists

{
  since => '4.11',
}

=example-1 exists

  # given: synopsis;

  my $exists = $map->exists(1);

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

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $first = $map->first;

  # 2

=cut

$test->for('example', 1, 'first', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 2;

  $result
});

=example-2 first

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(8,7,6,5,4,3,2,1);

  my $first = $map->first;

  # 7

=cut

$test->for('example', 2, 'first', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 7;

  $result
});

=method get

The get method returns the value at the position specified.

=signature get

  get(string $key) (any)

=metadata get

{
  since => '4.11',
}

=cut

=example-1 get

  # given: synopsis

  package main;

  my $get = $map->get(1);

  # 2

=cut

$test->for('example', 1, 'get', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 2;

  $result
});

=example-2 get

  # given: synopsis

  package main;

  my $get = $map->get(3);

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

  grep(coderef $code) (hashref)

=metadata grep

{
  since => '4.11',
}

=example-1 grep

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $grep = $map->grep(sub {
    $_ > 4
  });

  # [6,8]

=cut

$test->for('example', 1, 'grep', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [6,8];

  $result
});

=example-2 grep

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $grep = $map->grep(sub {
    my ($key, $value) = @_;

    $value > 4
  });

  # [6,8]

=cut

$test->for('example', 2, 'grep', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [6,8];

  $result
});

=method head

The head method returns the topmost elements, limited by the desired size
specified.

=signature head

  head(number $size) (hashref)

=metadata head

{
  since => '4.11',
}

=example-1 head

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head;

  # [2]

=cut

$test->for('example', 1, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2];

  $result
});

=example-2 head

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head(1);

  # [2]

=cut

$test->for('example', 2, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2];

  $result
});

=example-3 head

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head(2);

  # [2,4]

=cut

$test->for('example', 3, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2,4];

  $result
});

=example-4 head

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head(5);

  # [2,4,6,8]

=cut

$test->for('example', 4, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2,4,6,8];

  $result
});

=example-5 head

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $head = $map->head(20);

  # [2,4,6,8]

=cut

$test->for('example', 5, 'head', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2,4,6,8];

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

  my $iterator = $map->iterator;

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

  my $iterator = $map->iterator;

  # sub { ... }

  # while (grep defined, my ($key, $value) = $iterator->()) {
  #   say $value; # 1
  # }

=cut

$test->for('example', 2, 'iterator', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  while (grep defined, my ($key, $value) = $result->()) {
    ok $key =~ m{\w};
    ok $value =~ m{\d};
  }

  $result
});

=method intersection

The intersection method returns a new map containing only the values that
already exist in the source.

=signature intersection

  intersection(hashref | Venus::Hash | Venus::Map $data) (Venus::Map)

=metadata intersection

{
  since => '4.11',
}

=cut

=example-1 intersection

  # given: synopsis

  package main;

  $map->push(9,10);

  my $intersection = $map->intersection({9,10,11,12});

  # bless(..., "Venus::Map")

  # $intersection->list;

  # [10]

=cut

$test->for('example', 1, 'intersection', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is $result->count, 1;
  is_deeply $result->get, {9,10};

  $result
});

=example-2 intersection

  # given: synopsis

  package main;

  $map->push(9,10);

  my $intersection = $map->intersection(Venus::Map->new({9,10,11,12}));

  # bless(..., "Venus::Map")

  # $intersection->list;

  # [10]

=cut

$test->for('example', 2, 'intersection', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is $result->count, 1;
  is_deeply $result->get, {9, 10};

  $result
});

=example-3 intersection

  # given: synopsis

  package main;

  use Venus::Hash;

  $map->push(9,10);

  my $intersection = $map->intersection(Venus::Hash->new({9,10,11,12}));

  # bless(..., "Venus::Map")

  # $intersection->list;

  # [10]

=cut

$test->for('example', 3, 'intersection', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is $result->count, 1;
  is_deeply $result->get, {9, 10};

  $result
});

=method intersect

The intersect method returns true if the values provided already exist in the
source.

=signature intersect

  intersect(hashref | Venus::Hash | Venus::Map $data) (boolean)

=metadata intersect

{
  since => '4.11',
}

=cut

=example-1 intersect

  # given: synopsis

  package main;

  my $intersect = $map->intersect({7,8});

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

  my $intersect = $map->intersect({9,10});

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

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $join = $map->join;

  # 2468

=cut

$test->for('example', 1, 'join', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 2468;

  $result
});

=example-2 join

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $join = $map->join(', ');

  # "2, 4, 6, 8"

=cut

$test->for('example', 2, 'join', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "2, 4, 6, 8";

  $result
});

=method keys

The keys method returns an array reference consisting of the indicies of the
array.

=signature keys

  keys() (hashref)

=metadata keys

{
  since => '4.11',
}

=example-1 keys

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $keys = $map->keys;

  # [1,3,5,7]

=cut

$test->for('example', 1, 'keys', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [1,3,5,7];

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

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $last = $map->last;

  # 8

=cut

$test->for('example', 1, 'last', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 8;

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

  my $length = $map->length;

  # 4

=cut

$test->for('example', 1, 'length', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, 4;

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

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $list = $map->list;

  # 4

=cut

$test->for('example', 1, 'list', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 4;

  $result
});

=example-2 list

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my @list = $map->list;

  # (2,4,6,8)

=cut

$test->for('example', 2, 'list', sub {
  my ($tryable) = @_;
  ok my @result = $tryable->result;
  is_deeply \@result, [2,4,6,8];

  @result
});

=method map

The map method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing the
elements for which the argument returns a value or non-empty list. This method
can return a list of values in list-context.

=signature map

  map(coderef $code) (hashref)

=metadata map

{
  since => '4.11',
}

=example-1 map

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $result = $map->map(sub {
    $_ * 2
  });

  # [4,8,12,16]

=cut

$test->for('example', 1, 'map', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [4,8,12,16];

  $result
});

=example-2 map

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

=cut

$test->for('example', 2, 'map', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    [1, 4],
    [3, 8],
    [5, 12],
    [7, 16],
  ];

  $result
});

=method merge

The merge method merges the arguments provided with the existing map.

=signature merge

  merge(any @data) (Venus::Map)

=metadata merge

{
  since => '4.11',
}

=example-1 merge

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $merge = $map->merge(7..10);

  # bless(..., "Venus::Map")

  # $map->list;

  # [2,4,6,8,10]

=cut

$test->for('example', 1, 'merge', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->get, {1..10};

  $result
});

=example-2 merge

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $merge = $map->merge(Venus::Map->new->do('set', 5..10));

  # bless(..., "Venus::Map")

  # $map->list;

  # [2,4,6,8,10]

=cut

$test->for('example', 2, 'merge', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->get, {1..10};

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Map)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Map;

  my $new = Venus::Map->new;

  # bless(..., "Venus::Map")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->value, {};

  $result
});

=example-2 new

  package main;

  use Venus::Map;

  my $new = Venus::Map->new({1..8});

  # bless(..., "Venus::Map")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->value, {1..8};

  $result
});

=example-3 new

  package main;

  use Venus::Map;

  my $new = Venus::Map->new(value => {1..8});

  # bless(..., "Venus::Map")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->value, {1..8};

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

  my $none = $map->none(sub {
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

  my $none = $map->none(sub {
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

  my $one = $map->one(sub {
    $_ == 2
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

  my $one = $map->one(sub {
    my ($key, $value) = @_;

    $value == 2
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

  order(number @indices) (Venus::Map)

=metadata order

{
  since => '4.11',
}

=example-1 order

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $order = $map->order;

  # bless(..., "Venus::Map")

  # $map->keys;

  # [1,3,5,7]

=cut

$test->for('example', 1, 'order', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result->keys, [1,3,5,7];

  $result
});

=example-2 order

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $order = $map->order(5,3);

  # bless(..., "Venus::Map")

  # $map->keys;

  # [5,3,1,7]

=cut

$test->for('example', 2, 'order', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result->keys, [5,3,1,7];

  $result
});

=example-3 order

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $order = $map->order(7);

  # bless(..., "Venus::Map")

  # $map->keys;

  # [7,1,3,5]

=cut

$test->for('example', 3, 'order', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result->keys, [7,1,3,5];

  $result
});

=method pairs

The pairs method is an alias to the pairs_array method. This method can return
a list of values in list-context.

=signature pairs

  pairs() (hashref)

=metadata pairs

{
  since => '4.11',
}

=example-1 pairs

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

=cut

$test->for('example', 1, 'pairs', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    [1, 2],
    [3, 4],
    [5, 6],
    [7, 8],
  ];

  $result
});

=method part

The part method iterates over each element in the array, executing the code
reference supplied in the argument, using the result of the code reference to
partition to array into two distinct array references. This method can return a
list of values in list-context.

=signature part

  part(coderef $code) (tuple[hashref, hashref])

=metadata part

{
  since => '4.11',
}

=example-1 part

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $part = $map->part(sub {
    $_ > 4
  });

  # [{5..8}, {1..4}]

=cut

$test->for('example', 1, 'part', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [{5..8}, {1..4}];

  $result
});

=example-2 part

  # given: synopsis;

  my $part = $map->part(sub {
    my ($key, $value) = @_;

    $value < 5
  });

  # [{1..4}, {5..8}]

=cut

$test->for('example', 2, 'part', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [{1..4}, {5..8}];

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

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $pop = $map->pop;

  # 8

=cut

$test->for('example', 1, 'pop', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 8;

  $result
});

=method push

The push method appends the array by pushing the agruments onto it and returns
itself.

=signature push

  push(any @data) (hashref)

=metadata push

{
  since => '4.11',
}

=example-1 push

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $push = $map->push(9,10);

  # {1..10}

=cut

$test->for('example', 1, 'push', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {1..10};

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

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $random = $map->random;

  # 2

  # my $random = $map->random;

  # 1

=cut

$test->for('example', 1, 'random', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result >= 2 && $result <= 8;

  $result
});

=method range

The range method accepts a I<"range expression"> and returns the result of
calling the L</slice> method with the computed range.

=signature range

  range(number | string @args) (hashref)

=metadata range

{
  since => '4.11',
}

=cut

=example-1 range

  # given: synopsis

  package main;

  my $range = $map->range;

  # []

=cut

$test->for('example', 1, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range(0);

  # [2]

=cut

$test->for('example', 2, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2];

  $result
});

=example-3 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('0:');

  # [2,4,6,8]

=cut

$test->for('example', 3, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2,4,6,8];

  $result
});

=example-4 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range(':2');

  # [2,4,6]

=cut

$test->for('example', 4, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2,4,6];

  $result
});

=example-5 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('3:');

  # [8]

=cut

$test->for('example', 5, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [8];

  $result
});

=example-6 range

  # given: synopsis

  package main;

  my $range = $map->range('4:');

  # []

=cut

$test->for('example', 6, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-7 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('0:1');

  # [2,4]

=cut

$test->for('example', 7, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2,4];

  $result
});

=example-8 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('2:4');

  # [6,8]

=cut

$test->for('example', 8, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [6,8];

  $result
});

=example-9 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range(0..2);

  # [2,4,6]

=cut

$test->for('example', 9, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2,4,6];

  $result
});

=example-10 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('-1:3');

  # [8]

=cut

$test->for('example', 10, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [8];

  $result
});

=example-11 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('0:4');

  # [2,4,6,8]

=cut

$test->for('example', 11, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2,4,6,8];

  $result
});

=example-12 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('0:-2');

  # [2,4,6]

=cut

$test->for('example', 12, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2,4,6];

  $result
});

=example-13 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('-2:-2');

  # [6]

=cut

$test->for('example', 13, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [6];

  $result
});

=example-14 range

  # given: synopsis

  package main;

  my $range = $map->range('0:-20');

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

  my $range = $map->range('-2:-20');

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

  my $range = $map->range('-2:-6');

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

  my $range = $map->range('-2:-8');

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

  my $range = $map->range('-2:-9');

  # []

=cut

$test->for('example', 18, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-19 range

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  my $range = $map->range('-4:-1');

  # [2,4,6,8]

=cut

$test->for('example', 19, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2,4,6,8];

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

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $reverse = $map->reverse;

  # [8,6,4,2]

=cut

$test->for('example', 1, 'reverse', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [8,6,4,2];

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

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $rotate = $map->rotate;

  # [4,6,8,2]

=cut

$test->for('example', 1, 'rotate', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [4,6,8,2];

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

  my $rsort = $map->rsort;

  # [8,6,4,2]

=cut

$test->for('example', 1, 'rsort', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [8,6,4,2];

  $result
});

=method set

The set method inserts a new value into the map if it doesn't exist.

=signature set

  set(any %pairs) (hashref)

=metadata set

{
  since => '4.11',
}

=cut

=example-1 set

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  $map = $map->set(9,10);

  # {1..10}

=cut

$test->for('example', 1, 'set', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {1..10};

  $result
});

=example-2 set

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  package main;

  $map = $map->set(1..8);

  # {1..8}

=cut

$test->for('example', 2, 'set', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {1..8};

  $result
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

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $shift = $map->shift;

  # 2

=cut

$test->for('example', 1, 'shift', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 2;

  $result
});

=method shuffle

The shuffle method returns an array with the values returned in a randomized order.

=signature shuffle

  shuffle() (arrayref)

=metadata shuffle

{
  since => '4.11',
}

=example-1 shuffle

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..20);

  my $shuffle = $map->shuffle;

  # [6, 12, 2, 20, 18, 16, 10, 4, 8, 14]

=cut

$test->for('example', 1, 'shuffle', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  isnt "@$result", "2 4 6 8 10 12 14 16 18 20";

  $result
});

=method slice

The slice method returns a hash reference containing the elements in the array
at the positions specified in the arguments.

=signature slice

  slice(string @keys) (hashref)

=metadata slice

{
  since => '4.11',
}

=example-1 slice

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $slice = $map->slice(0, 1);

  # [2, 4]

=cut

$test->for('example', 1, 'slice', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2,4];

  $result
});

=example-2 slice

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $slice = $map->slice(3, 1);

  # [8, 4]

=cut

$test->for('example', 2, 'slice', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [8,4];

  $result
});

=method sort

The sort method returns an array reference containing the values in the array
sorted alphanumerically.

=signature sort

  sort() (hashref)

=metadata sort

{
  since => '4.11',
}

=example-1 sort

  package main;

  use Venus::Map;

  my $map = Venus::Map->new({1 => 'a', 2 => 'b', 3 => 'c', 4 => 'd'});

  my $sort = $map->sort;

  # ["a".."d"]

=cut

$test->for('example', 1, 'sort', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["a".."d"];

  $result
});

=method subset

The subset method returns true if all the values provided already exist in the
source.

=signature subset

  subset(hashref | Venus::Hash | Venus::Map $data) (boolean)

=metadata subset

{
  since => '4.11',
}

=cut

=example-1 subset

  # given: synopsis

  package main;

  my $subset = $map->subset({1..6});

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

  my $subset = $map->subset({1..10});

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

  my $subset = $map->subset({1,2});

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

  superset(hashref | Venus::Hash | Venus::Map $data) (boolean)

=metadata superset

{
  since => '4.11',
}

=cut

=example-1 superset

  # given: synopsis

  package main;

  my $superset = $map->superset({1..10});

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

  my $superset = $map->superset({1..6});

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

  my $superset = $map->superset({1..8});

  # true

=cut

$test->for('example', 1, 'superset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method tail

The tail method returns the bottommost elements, limited by the desired size
specified.

=signature tail

  tail(number $size) (hashref)

=metadata tail

{
  since => '4.11',
}

=example-1 tail

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail;

  # [8]

=cut

$test->for('example', 1, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [8];

  $result
});

=example-2 tail

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail(1);

  # [8]

=cut

$test->for('example', 2, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [8];

  $result
});

=example-3 tail

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail(2);

  # [6,8]

=cut

$test->for('example', 3, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [6,8];

  $result
});

=example-4 tail

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail(4);

  # [2,4,6,8]

=cut

$test->for('example', 4, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2,4,6,8];

  $result
});

=example-5 tail

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $tail = $map->tail(20);

  # [2,4,6,8]

=cut

$test->for('example', 5, 'tail', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [2,4,6,8];

  $result
});

=method unshift

The unshift method prepends the array by pushing the agruments onto it and
returns itself.

=signature unshift

  unshift(any @data) (hashref)

=metadata unshift

{
  since => '4.11',
}

=example-1 unshift

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->set(1..8);

  my $unshift = $map->unshift(9,10,11,12);

  # {1..12}

=cut

$test->for('example', 1, 'unshift', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {1..12};

  $result
});

=example-2 unshift

  package main;

  use Venus::Map;

  my $map = Venus::Map->new;

  $map->do('set', 1..8);

  # my $unshift = $map->unshift(9,10,11,12);

  # {1..12}

  # $map->keys;

  # [9,11,1,3,5,7]

=cut

$test->for('example', 2, 'unshift', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  $result->unshift(9,10,11,12);
  is_deeply $result->keys, [9,11,1,3,5,7];

  $result
});

=method values

The values method returns an array reference consisting of all the values in
the hash.

=signature values

  values() (arrayref)

=metadata values

{
  since => '4.15',
}

=example-1 values

  # given: synopsis;

  my $values = $map->values;

  # [2, 4, 6, 8]

=cut

$test->for('example', 1, 'values', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [sort @{$result}], [2, 4, 6, 8];

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Map.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
