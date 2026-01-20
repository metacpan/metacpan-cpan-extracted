package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Range

=cut

$test->for('name');

=tagline

Range Class

=cut

$test->for('tagline');

=abstract

Range Class for Perl 5

=cut

$test->for('abstract');

=includes

method: after
method: before
method: iterate
method: new
method: parse
method: partition
method: select
method: split

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Range;

  my $range = Venus::Range->new(['a'..'i']);

  # $array->parse('0:2');

  # ['a', 'b', 'c']

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Range');

  $result
});

=description

This package provides methods for selecting elements from an arrayref using
range expressions. A "range expression" is a string that specifies a subset of
elements in an array or arrayref, defined by a start, stop, and an optional
step value, separated by colons. For example, the expression '1:4' will select
elements starting from index 1 to index 4 (both inclusive). The components of
the range expression are:

+=over 4

+=item * B<Start>: The beginning index of the selection. If this value is
negative, it counts from the end of the array, where -1 is the last element.

+=item * B<Stop>: The ending index of the selection. This value is also
inclusive, meaning the element at this index will be included in the selection.
Negative values count from the end of the array.

+=item * B<Step>: An optional value that specifies the interval between
selected elements. For instance, a step of 2 will select every second element.
If not provided, the default step is 1.

+=back

This package uses inclusive start and stop indices, meaning both bounds are
included in the selection. This differs from some common conventions where the
stop value is exclusive. The package also gracefully handles out-of-bound
indices. If the start or stop values exceed the length of the array, they are
adjusted to fit within the valid range without causing errors. Negative indices
are also supported, allowing for easy reverse indexing from the end of the
array.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Valuable

=cut

$test->for('integrates');

=attribute start

The start attribute is read-write, accepts C<(number)> values, and is
optional.

=signature start

  start(number $start) (number)

=metadata start

{
  since => '4.15',
}

=cut

=example-1 start

  # given: synopsis

  package main;

  my $start = $range->start(0);

  # 0

=cut

$test->for('example', 1, 'start', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 start

  # given: synopsis

  # given: example-1 start

  package main;

  $start = $range->start;

  # 0

=cut

$test->for('example', 2, 'start', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=attribute stop

The stop attribute is read-write, accepts C<(number)> values, and is
optional.

=signature stop

  stop(number $stop) (number)

=metadata stop

{
  since => '4.15',
}

=cut

=example-1 stop

  # given: synopsis

  package main;

  my $stop = $range->stop(9);

  # 9

=cut

$test->for('example', 1, 'stop', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 9;

  $result
});

=example-2 stop

  # given: synopsis

  # given: example-1 stop

  package main;

  $stop = $range->stop;

  # 9

=cut

$test->for('example', 2, 'stop', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 9;

  $result
});

=attribute step

The step attribute is read-write, accepts C<(number)> values, and is
optional.

=signature step

  step(number $step) (number)

=metadata step

{
  since => '4.15',
}

=cut

=example-1 step

  # given: synopsis

  package main;

  my $step = $range->step(1);

  # 1

=cut

$test->for('example', 1, 'step', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-2 step

  # given: synopsis

  # given: example-1 step

  package main;

  $step = $range->step;

  # 1

=cut

$test->for('example', 2, 'step', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method after

The after method selects the elements after the index provided and returns the
selection using L</select>. The selection is not inclusive.

=signature after

  after(number $index) (arrayref)

=metadata after

{
  since => '4.15',
}

=cut

=example-1 after

  # given: synopsis

  package main;

  my $after = $range->after;

  # []

=cut

$test->for('example', 1, 'after', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 after

  # given: synopsis

  package main;

  my $after = $range->after(5);

  # ['g', 'h', 'i']

=cut

$test->for('example', 2, 'after', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['g', 'h', 'i'];

  $result
});

=method before

The before method selects the elements before the index provided and returns the
selection using L</select>. The selection is not inclusive.

=signature before

  before(number $index) (arrayref)

=metadata before

{
  since => '4.15',
}

=cut

=example-1 before

  # given: synopsis

  package main;

  my $before = $range->before;

  # []

=cut

$test->for('example', 1, 'before', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 before

  # given: synopsis

  package main;

  my $before = $range->before(5);

  # ['a'..'e']

=cut

$test->for('example', 2, 'before', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['a'..'e'];

  $result
});

=method iterate

The iterate method returns an iterator which uses L</select> to iteratively
return each element of the selection.

=signature iterate

  iterate( ) (coderef)

=metadata iterate

{
  since => '4.15',
}

=cut

=example-1 iterate

  # given: synopsis

  package main;

  my $iterate = $range->iterate;

  # sub{...}

=cut

$test->for('example', 1, 'iterate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'CODE';
  is $result->(), 'a';
  is $result->(), 'b';
  is $result->(), 'c';
  is $result->(), 'd';
  is $result->(), 'e';
  is $result->(), 'f';
  is $result->(), 'g';
  is $result->(), 'h';
  is $result->(), 'i';
  is $result->(), undef;

  $result
});

=example-2 iterate

  package main;

  my $range = Venus::Range->parse('4:', ['a'..'i']);

  my $iterate = $range->iterate;

  # sub{...}

=cut

$test->for('example', 2, 'iterate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'CODE';
  is $result->(), 'e';
  is $result->(), 'f';
  is $result->(), 'g';
  is $result->(), 'h';
  is $result->(), 'i';
  is $result->(), undef;

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Range)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Range;

  my $range = Venus::Range->new;

  # bless(..., 'Venus::Range')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is_deeply $result->value, [];

  $result
});

=example-2 new

  package main;

  use Venus::Range;

  my $range = Venus::Range->new(['a'..'d']);

  # bless(..., 'Venus::Range')

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is_deeply $result->value, ['a'..'d'];

  $result
});

=example-3 new

  package main;

  use Venus::Range;

  my $range = Venus::Range->new(value => ['a'..'d']);

  # bless(..., 'Venus::Range')

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is_deeply $result->value, ['a'..'d'];

  $result
});


=method parse

The parse method parses the "range expression" provided and returns a new
instance of L<Venus::Range> representing the range expression, optionally
accepting and setting the arrayref to be used as the selection source. This
method can also be used as a class method.

=signature parse

  parse(string $expr, arrayref $data) (Venus::Range)

=metadata parse

{
  since => '4.15',
}

=cut

=example-1 parse

  # given: synopsis

  package main;

  my $parse = $range->parse('4:');

  # bless(..., "Venus::Range")

  # $parse->start
  # 4

  # $parse->stop
  # -1

  # $parse->step
  # 1

=cut

$test->for('example', 1, 'parse', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is $result->start, 4;
  is $result->stop, -1;
  is $result->step, 1;
  is_deeply $result->value, [];

  $result
});

=example-2 parse

  # given: synopsis

  package main;

  my $parse = $range->parse('0:1');

  # bless(..., "Venus::Range")

  # $parse->start
  # 0

  # $parse->stop
  # 1

  # $parse->step
  # 1

=cut

$test->for('example', 2, 'parse', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is $result->start, 0;
  is $result->stop, 1;
  is $result->step, 1;
  is_deeply $result->value, [];

  $result
});

=example-3 parse

  # given: synopsis

  package main;

  my $parse = $range->parse('1:0');

  # bless(..., "Venus::Range")

  # $parse->start
  # 1

  # $parse->stop
  # 0

  # $parse->step
  # 1

=cut

$test->for('example', 3, 'parse', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is $result->start, 1;
  is $result->stop, 0;
  is $result->step, 1;
  is_deeply $result->value, [];

  $result
});

=example-4 parse

  # given: synopsis

  package main;

  my $parse = $range->parse('2::2');

  # bless(..., "Venus::Range")

  # $parse->start
  # 2

  # $parse->stop
  # -1

  # $parse->step
  # 2

=cut

$test->for('example', 4, 'parse', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is $result->start, 2;
  is $result->stop, -1;
  is $result->step, 2;
  is_deeply $result->value, [];

  $result
});

=example-5 parse

  # given: synopsis

  package main;

  my $parse = $range->parse(':4');

  # bless(..., "Venus::Range")

  # $parse->start
  # 0

  # $parse->stop
  # 4

  # $parse->step
  # 1

=cut

$test->for('example', 5, 'parse', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is $result->start, 0;
  is $result->stop, 4;
  is $result->step, 1;
  is_deeply $result->value, [];

  $result
});

=example-6 parse

  # given: synopsis

  package main;

  my $parse = $range->parse(':4:1');

  # bless(..., "Venus::Range")

  # $parse->start
  # 0

  # $parse->stop
  # 4

  # $parse->step
  # 1

=cut

$test->for('example', 6, 'parse', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is $result->start, 0;
  is $result->stop, 4;
  is $result->step, 1;
  is_deeply $result->value, [];

  $result
});

=example-7 parse

  # given: synopsis

  package main;

  my $parse = $range->parse(':-2', ['a'..'i']);

  # bless(..., "Venus::Range")

  # $parse->start
  # 0

  # $parse->stop
  # -2

  # $parse->step
  # 1

=cut

$test->for('example', 7, 'parse', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Range');
  is $result->start, 0;
  is $result->stop, -2;
  is $result->step, 1;
  is_deeply $result->value, ['a'..'i'];

  $result
});

=method partition

The partition method splits the elements into two sets of elements at the index
specific and returns a tuple of two arrayrefs. The first arrayref will include
everything L<"before"|/before> the index provided, and the second tuple will
include everything at and L<"after"|/after> the index provided.

=signature partition

  partition(number $index) (tuple[arrayref, arrayref])

=metadata partition

{
  since => '4.15',
}

=cut

=example-1 partition

  # given: synopsis

  package main;

  my $partition = $range->partition;

  # [[], ['a'..'i']]

=cut

$test->for('example', 1, 'partition', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [[], ['a'..'i']];

  $result
});

=example-2 partition

  # given: synopsis

  package main;

  my $partition = $range->partition(0);

  # [[], ['a'..'i']]

=cut

$test->for('example', 2, 'partition', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [[], ['a'..'i']];

  $result
});

=example-3 partition

  # given: synopsis

  package main;

  my $partition = $range->partition(5);

  # [['a'..'e'], ['f'..'i']]

=cut

$test->for('example', 3, 'partition', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['a'..'e'], ['f'..'i']];

  $result
});

=method select

The select method uses the start, stop, and step attributes to select elements
from the arrayref and returns the selection. Returns a list in list context.

=signature select

  select() (arrayref)

=metadata select

{
  since => '4.15',
}

=cut

=example-1 select

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse('4:', ['a'..'i']);

  my $select = $range->select;

  # ['e'..'i']

=cut

$test->for('example', 1, 'select', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['e'..'i'];

  $result
});

=example-2 select

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse('0:1', ['a'..'i']);

  my $select = $range->select;

  # ['a', 'b']

=cut

$test->for('example', 2, 'select', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['a', 'b'];

  $result
});

=example-3 select

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse('0:', ['a'..'i']);

  my $select = $range->select;

  # ['a'..'i']

=cut

$test->for('example', 3, 'select', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['a'..'i'];

  $result
});

=example-4 select

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse(':-2', ['a'..'i']);

  my $select = $range->select;

  # ['a'..'h']

=cut

$test->for('example', 4, 'select', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['a'..'h'];

  $result
});

=example-5 select

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse('2:8:2', ['a'..'i']);

  my $select = $range->select;

  # ['c', 'e', 'g', 'i']

=cut

$test->for('example', 5, 'select', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['c', 'e', 'g', 'i'];

  $result
});

=method split

The split method splits the elements into two sets of elements at the index
specific and returns a tuple of two arrayrefs. The first arrayref will include
everything L<"before"|/before> the index provided, and the second tuple will
include everything L<"after"|/after> the index provided. This operation will
always exclude the element at the index the elements are split on. See
L</partition> for an inclusive split operation.

=signature split

  split(number $index) (tuple[arrayref, arrayref])

=metadata split

{
  since => '4.15',
}

=cut

=example-1 split

  # given: synopsis

  package main;

  my $split = $range->split;

  # [[], ['b'..'i']]

=cut

$test->for('example', 1, 'split', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [[], ['b'..'i']];

  $result
});

=example-2 split

  # given: synopsis

  package main;

  my $split = $range->split(0);

  # [[], ['a'..'i']]

=cut

$test->for('example', 2, 'split', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [[], ['b'..'i']];

  $result
});

=example-3 split

  # given: synopsis

  package main;

  my $split = $range->split(5);

  # [['a'..'e'], ['g'..'i']]

=cut

$test->for('example', 3, 'split', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['a'..'e'], ['g'..'i']];

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Range.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
