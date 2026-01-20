package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Text

=cut

$test->for('name');

=tagline

Text Class

=cut

$test->for('tagline');

=abstract

Text Class for Perl 5

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

  use Venus::Text;

  my $text = Venus::Text->new('t/data/sections');

  # $text->find(undef, 'name');

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Text');

  $result
});

=description

This package provides methods for extracting C<DATA> sections and POD blocks
from any file or package. The package can be configured to parse either POD or
DATA blocks, and it defaults to being configured for POD blocks.

+=head2 DATA syntax

  __DATA__

  # data syntax

  @@ name

  Example Name

  @@ end

  @@ titles #1

  Example Title #1

  @@ end

  @@ titles #2

  Example Title #2

  @@ end

+=head2 DATA syntax (nested)

  __DATA__

  # data syntax (nested)

  @@ nested

  Example Nested

  +@@ demo

  blah blah blah

  +@@ end

  @@ end

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
  since => '0.01',
}

=example-1 count

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my $count = $text->count;

  # 7

=cut

$test->for('example', 1, 'count', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 7;

  $result
});

=example-2 count

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $count = $text->count;

  # 3

=cut

$test->for('example', 2, 'count', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 3;

  $result
});

=method data

The data method returns the contents of the L</file> to be parsed.

=signature data

  data() (string)

=metadata data

{
  since => '0.01',
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
  since => '0.01',
}

=example-1 find

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

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

  $text->stag('=');

  $text->etag('=cut');

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

=example-3 find

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $find = $text->find(undef, 'name');

  # [
  #   { data => ["Example Name"], index => 1, list => undef, name => "name" },
  # ]

=cut

$test->for('example', 3, 'find', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    { data => ["Example Name"], index => 1, list => undef, name => "name" },
  ];

  $result
});

=example-4 find

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $find = $text->find('titles', '#1');

  # [
  #   { data => ["Example Title #1"], index => 2, list => "titles", name => "#1" },
  # ]

=cut

$test->for('example', 4, 'find', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    { data => ["Example Title #1"], index => 2, list => "titles", name => "#1" },
  ];

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Text)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Text;

  my $new = Venus::Text->new;

  # bless(..., "Venus::Text")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Text');

  $result
});

=example-2 new

  package main;

  use Venus::Text;

  my $new = Venus::Text->new('t/data/sections');

  # bless(..., "Venus::Text")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Text');
  is $result->file, 't/data/sections';

  $result
});

=example-3 new

  package main;

  use Venus::Text;

  my $new = Venus::Text->new(file => 't/data/sections');

  # bless(..., "Venus::Text")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Text');
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
  since => '0.01',
}

=example-1 search

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

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

  $text->stag('=');

  $text->etag('=cut');

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

=example-3 search

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $find = $text->search({list => undef, name => 'name'});

  # [
  #   { data => ["Example Name"], index => 1, list => undef, name => "name" },
  # ]

=cut

$test->for('example', 3, 'search', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    { data => ["Example Name"], index => 1, list => undef, name => "name" },
  ];

  $result
});

=example-4 search

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $search = $text->search({list => 'titles', name => '#1'});

  # [
  #   { data => ["Example Title #1"], index => 2, list => "titles", name => "#1" },
  # ]

=cut

$test->for('example', 4, 'search', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    { data => ["Example Title #1"], index => 2, list => "titles", name => "#1" },
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
  since => '1.67',
}

=example-1 string

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

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

  $text->stag('=');

  $text->etag('=cut');

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

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $string = $text->string(undef, 'name');

  # "Example Name"

=cut

$test->for('example', 3, 'string', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "Example Name";

  $result
});

=example-4 string

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $string = $text->string('titles', '#1');

  # "Example Title #1"

=cut

$test->for('example', 4, 'string', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "Example Title #1";

  $result
});

=example-5 string

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my @string = $text->string('head1', 'NAME');

  # ("Example #1", "Example #2")

=cut

$test->for('example', 5, 'string', sub {
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

$test->render('lib/Venus/Text.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
