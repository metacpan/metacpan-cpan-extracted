package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Text::Pod

=cut

$test->for('name');

=tagline

Text (Pod) Class

=cut

$test->for('tagline');

=abstract

Text (Pod) Class for Perl 5

=cut

$test->for('abstract');

=includes

method: count
method: data
method: find
method: new
method: search
method: string

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Text::Pod;

  my $text = Venus::Text::Pod->new('t/data/sections');

  # $text->find(undef, 'name');

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Text::Pod');

  $result
});

=description

This package provides methods for extracting POD blocks from any file or
package.

+=head2 POD syntax

  # pod syntax

  =head1 NAME

  Example #1

  =cut

  =head1 NAME

  Example #2

  =cut

  # pod-ish syntax

  =name

  Example #1

  =cut

  =name

  Example #2

  =cut

+=head2 POD syntax (nested)

  # pod syntax (nested)

  =nested

  Example #1

  +=head1 WHY?

  blah blah blah

  +=cut

  More information on the same topic as was previously mentioned in the
  previous section demonstrating the topic, obviously from said section.

  =cut

=cut

$test->for('description');

=method count

The count method uses the criteria provided to L</search> for and return the
number of blocks found.

=signature count

  count(hashref $criteria) (number)

=metadata count

{
  since => '4.15',
}

=example-1 count

  # given: synopsis;

  my $count = $text->count;

  # 7

=cut

$test->for('example', 1, 'count', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 7;

  $result
});

=method data

The data method returns the contents of the L</file> to be parsed.

=signature data

  data() (string)

=metadata data

{
  since => '4.15',
}

=example-1 data

  # given: synopsis;

  $text = $text->data;

  # ...

=cut

$test->for('example', 1, 'data', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=method find

The find method is a wrapper around L</search> as shorthand for searching by
C<list> and C<name>.

=signature find

  find(maybe[string] $list, maybe[string] $name) (arrayref)

=metadata find

{
  since => '4.15',
}

=example-1 find

  # given: synopsis;

  my $find = $text->find(undef, 'name');

  # [
  #   { data => ["Example #1"], index => 4, list => undef, name => "name" },
  #   { data => ["Example #2"], index => 5, list => undef, name => "name" },
  # ]

=cut

$test->for('example', 1, 'find', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    { data => ["Example #1"], index => 5, list => undef, name => "name" },
    { data => ["Example #2"], index => 6, list => undef, name => "name" },
  ];

  $result
});

=example-2 find

  # given: synopsis;

  my $find = $text->find('head1', 'NAME');

  # [
  #   { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
  #   { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  # ]

=cut

$test->for('example', 2, 'find', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
    { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  ];

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Text::Pod)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Text::Pod;

  my $new = Venus::Text::Pod->new;

  # bless(..., "Venus::Text::Pod")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Text::Pod');

  $result
});

=example-2 new

  package main;

  use Venus::Text::Pod;

  my $new = Venus::Text::Pod->new('t/data/sections');

  # bless(..., "Venus::Text::Pod")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Text::Pod');
  is $result->file, 't/data/sections';

  $result
});

=example-3 new

  package main;

  use Venus::Text::Pod;

  my $new = Venus::Text::Pod->new(file => 't/data/sections');

  # bless(..., "Venus::Text::Pod")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Text::Pod');
  is $result->file, 't/data/sections';

  $result
});

=method search

The search method returns the set of blocks matching the criteria provided.
This method can return a list of values in list-context.

=signature search

  find(hashref $criteria) (arrayref)

=metadata search

{
  since => '4.15',
}

=example-1 search

  # given: synopsis;

  my $search = $text->search({list => undef, name => 'name'});

  # [
  #   { data => ["Example #1"], index => 4, list => undef, name => "name" },
  #   { data => ["Example #2"], index => 5, list => undef, name => "name" },
  # ]

=cut

$test->for('example', 1, 'search', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    { data => ["Example #1"], index => 5, list => undef, name => "name" },
    { data => ["Example #2"], index => 6, list => undef, name => "name" },
  ];

  $result
});

=example-2 search

  # given: synopsis;

  my $search = $text->search({list => 'head1', name => 'NAME'});

  # [
  #   { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
  #   { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  # ]

=cut

$test->for('example', 2, 'search', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
    { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  ];

  $result
});

=method string

The string method is a wrapper around L</find> as shorthand for searching by
C<list> and C<name>, returning only the strings found.

=signature string

  string(maybe[string] $list, maybe[string] $name) (string)

=metadata string

{
  since => '4.15',
}

=example-1 string

  # given: synopsis;

  my $string = $text->string(undef, 'name');

  # "Example #1\nExample #2"

=cut

$test->for('example', 1, 'string', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "Example #1\nExample #2";

  $result
});

=example-2 string

  # given: synopsis;

  my $string = $text->string('head1', 'NAME');

  # "Example #1\nExample #2"

=cut

$test->for('example', 2, 'string', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "Example #1\nExample #2";

  $result
});

=example-3 string

  # given: synopsis;

  my @string = $text->string('head1', 'NAME');

  # ("Example #1", "Example #2")

=cut

$test->for('example', 3, 'string', sub {
  my ($tryable) = @_;
  ok my $result = [$tryable->result];
  is_deeply $result, ["Example #1", "Example #2"];

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Text/Pod.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
