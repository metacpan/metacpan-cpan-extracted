package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Collect

=cut

$test->for('name');

=tagline

Collect Class

=cut

$test->for('tagline');

=abstract

Collect Class for Perl 5

=cut

$test->for('abstract');

=includes

method: execute
method: new

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new([1..4]);

  # bless({value => [1..4], 'Venus::Collect')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Collect');
  is_deeply $result->value, [1..4];

  $result
});

=description

This package provides a generic collection utility class designed to provide a
unified interface for working with data collections in Perl. It can wrap native
Perl arrayrefs and hashrefs, as well as compatible objects (e.g.,
L<Venus::Array>, L<Venus::Hash>, L<Venus::Set>, etc.), and apply functional
transformations through callbacks.

This class allows you to create a collection object, then use the C<execute>
method to iterate over the contents and selectively transform or filter the
data. The method supports both list-like and hash-like data structures,
handling key/value iteration when applicable.

It's especially useful in scenarios where you need to apply consistent
processing logic across various collection types without writing boilerplate
code for each type.

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

=method execute

The execute method accepts a callback (i.e. coderef) and executes the callback
for each key/value pair in the L</value>. For each iteration, the C<$_>
variable is set to the value (in the key/value pair). The callback will be
passed the key and values as arguments, made available via the C<@_> variable.
The callback must return a tuple, i.e. a list with the key and value, to be
returned as a result. This method returns a new instance of L</value> provided
consisting of only the key/value pairs returned from the callback.

=signature execute

  execute(coderef $code) (any)

=metadata execute

{
  since => '4.15',
}

=example-1 execute

  # given: synopsis

  package main;

  my $execute = $collect->execute;

  # [1..4]

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..4];

  $result
});

=example-2 execute

  # given: synopsis

  package main;

  my $execute = $collect->execute(sub{});

  # []

=cut

$test->for('example', 2, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-3 execute

  # given: synopsis

  package main;

  my $execute = $collect->execute(sub{$_});

  # []

=cut

$test->for('example', 3, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-4 execute

  # given: synopsis

  package main;

  my $execute = $collect->execute(sub{@_});

  # [1..4]

=cut

$test->for('example', 4, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..4];

  $result
});

=example-5 execute

  # given: synopsis

  package main;

  my $execute = $collect->execute(sub{$_%2==0 ? (@_) : ()});

  # [2,4]

=cut

$test->for('example', 5, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2,4];

  $result
});

=example-6 execute

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute;

  # {1..8}

=cut

$test->for('example', 6, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {1..8};

  $result
});

=example-7 execute

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute(sub{});

  # {}

=cut

$test->for('example', 7, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-8 execute

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute(sub{$_});

  # {}

=cut

$test->for('example', 8, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-9 execute

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute(sub{@_});

  # {1..8}

=cut

$test->for('example', 9, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {1..8};

  $result
});

=example-10 execute

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute(sub{$_%6==0 ? (@_) : ()});

  # {5,6}

=cut

$test->for('example', 10, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {5,6};

  $result
});

=example-11 execute

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({value => [1..4], 'Venus::Array')

=cut

$test->for('example', 11, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Array');
  is_deeply $result->value, [1..4];

  $result
});

=example-12 execute

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({value => [], 'Venus::Array')

=cut

$test->for('example', 12, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Array');
  is_deeply $result->value, [];

  $result
});

=example-13 execute

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({value => [], 'Venus::Array')

=cut

$test->for('example', 13, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Array');
  is_deeply $result->value, [];

  $result
});

=example-14 execute

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({value => [1..4], 'Venus::Array')

=cut

$test->for('example', 14, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Array');
  is_deeply $result->value, [1..4];

  $result
});

=example-15 execute

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%2==0 ? (@_) : ()});

  # bless({value => [2,4], 'Venus::Array')

=cut

$test->for('example', 15, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Array');
  is_deeply $result->value, [2,4];

  $result
});

=example-16 execute

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({value => [1..4], 'Venus::Set')

=cut

$test->for('example', 16, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->value, [1..4];

  $result
});

=example-17 execute

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({value => [], 'Venus::Set')

=cut

$test->for('example', 17, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->value, [];

  $result
});

=example-18 execute

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({value => [], 'Venus::Set')

=cut

$test->for('example', 18, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->value, [];

  $result
});

=example-19 execute

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({value => [1..4], 'Venus::Set')

=cut

$test->for('example', 19, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->value, [1..4];

  $result
});

=example-20 execute

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%2==0 ? (@_) : ()});

  # bless({value => [2,4], 'Venus::Set')

=cut

$test->for('example', 20, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->value, [2,4];

  $result
});

=example-21 execute

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({value => {1..8}, 'Venus::Hash')

=cut

$test->for('example', 21, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Hash');
  is_deeply $result->value, {1..8};

  $result
});

=example-22 execute

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({value => {}, 'Venus::Hash')

=cut

$test->for('example', 22, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Hash');
  is_deeply $result->value, {};

  $result
});

=example-23 execute

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({value => {}, 'Venus::Hash')

=cut

$test->for('example', 23, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Hash');
  is_deeply $result->value, {};

  $result
});

=example-24 execute

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({value => {1..8}, 'Venus::Hash')

=cut

$test->for('example', 24, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Hash');
  is_deeply $result->value, {1..8};

  $result
});

=example-25 execute

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%6==0 ? (@_) : ()});

  # bless({value => {5,6}, 'Venus::Hash')

=cut

$test->for('example', 25, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Hash');
  is_deeply $result->value, {5,6};

  $result
});

=example-26 execute

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({value => {1..8}, 'Venus::Map')

=cut

$test->for('example', 26, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->value, {1..8};

  $result
});

=example-27 execute

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({value => {}, 'Venus::Map')

=cut

$test->for('example', 27, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->value, {};

  $result
});

=example-28 execute

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({value => {}, 'Venus::Map')

=cut

$test->for('example', 28, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->value, {};

  $result
});

=example-29 execute

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({value => {1..8}, 'Venus::Map')

=cut

$test->for('example', 29, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->value, {1..8};

  $result
});

=example-30 execute

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%6==0 ? (@_) : ()});

  # bless({value => {5,6}, 'Venus::Map')

=cut

$test->for('example', 30, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->value, {5,6};

  $result
});

=example-31 execute

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless([1..4], 'Example')

=cut

$test->for('example', 31, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, [1..4];

  $result
});

=example-32 execute

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless([], 'Example')

=cut

$test->for('example', 32, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, [];

  $result
});

=example-33 execute

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless([], 'Example')

=cut

$test->for('example', 33, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, [];

  $result
});

=example-34 execute

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless([1..4], 'Example')

=cut

$test->for('example', 34, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, [1..4];

  $result
});

=example-35 execute

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%2==0 ? (@_) : ()});

  # bless([2,4], 'Example')

=cut

$test->for('example', 35, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, [2,4];

  $result
});

=example-36 execute

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({1..8}, 'Example')

=cut

$test->for('example', 36, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, {1..8};

  $result
});

=example-37 execute

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({}, 'Example')

=cut

$test->for('example', 37, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, {};

  $result
});

=example-38 execute

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({}, 'Example')

=cut

$test->for('example', 38, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, {};

  $result
});

=example-39 execute

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({1..8}, 'Example')

=cut

$test->for('example', 39, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, {1..8};

  $result
});

=example-40 execute

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%6==0 ? (@_) : ()});

  # bless({5,6}, 'Example')

=cut

$test->for('example', 40, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is_deeply $result, {5,6};

  $result
});

=method new

The new method returns a new instance.

=signature new

  new(any @args) (Venus::Collect)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Collect;

  my $new = Venus::Collect->new;

  # bless({value => undef}, 'Venus::Collect')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Collect');
  is $result->value, undef;

  $result
});

=example-2 new

  package main;

  use Venus::Collect;

  my $new = Venus::Collect->new([1..4]);

  # bless({value => [1..4]}, 'Venus::Collect')

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Collect');
  is_deeply $result->value, [1..4];

  $result
});

=example-3 new

  package main;

  use Venus::Collect;

  my $new = Venus::Collect->new(value => [1..4]);

  # bless({value => [1..4]}, 'Venus::Collect')

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Collect');
  is_deeply $result->value, [1..4];

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Collect.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;