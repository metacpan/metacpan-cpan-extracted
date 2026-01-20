package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Search

=cut

$test->for('name');

=tagline

Search Class

=cut

$test->for('tagline');

=abstract

Search Class for Perl 5

=cut

$test->for('abstract');

=includes

method: captures
method: evaluate
method: explain
method: get
method: count
method: initial
method: last_match_end
method: last_match_start
method: matched
method: named_captures
method: new
method: prematched
method: postmatched
method: set

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Search;

  my $search = Venus::Search->new(
    string => 'hello world',
    regexp => '(hello)',
  );

  # $search->captures;

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=description

This package provides methods for manipulating regexp search data.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Encaseable
Venus::Role::Explainable

=cut

$test->for('integrates');

=attributes

flags: rw, opt, Str, C<''>
regexp: rw, opt, Regexp, C<qr//>
string: rw, opt, Str, C<''>

=cut

$test->for('attributes');

=method captures

The captures method returns the capture groups from the result object which
contains information about the results of the regular expression operation.
This method can return a list of values in list-context.

=signature captures

  captures() (arrayref)

=metadata captures

{
  since => '0.01',
}

=example-1 captures

  # given: synopsis;

  my $captures = $search->captures;

  # ["hello"]

=cut

$test->for('example', 1, 'captures', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["hello"];

  $result
});

=method evaluate

The evaluate method performs the regular expression operation and returns an
arrayref representation of the results.

=signature evaluate

  evaluate() (arrayref)

=metadata evaluate

{
  since => '0.01',
}

=example-1 evaluate

  # given: synopsis;

  my $evaluate = $search->evaluate;

  # ["(hello)", "hello world", 1, [0, 0], [5, 5], {}, "hello world"]

=cut

$test->for('example', 1, 'evaluate', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["(hello)", "hello world", 1, [0, 0], [5, 5], {}, "hello world"];

  $result
});

=example-2 evaluate

  package main;

  use Venus::Search;

  my $search = Venus::Search->new(
    string => 'hello world',
    regexp => 'hello:)',
  );

  my $evaluate = $search->evaluate;

  # Exception! (isa Venus::Search::Error) (see error_on_evaluate)

=cut

$test->for('example', 2, 'evaluate', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok $error->isa('Venus::Search::Error');
  ok $error->isa('Venus::Error');

  $result
});

=method explain

The explain method returns the subject of the regular expression operation and
is used in stringification operations.

=signature explain

  explain() (string)

=metadata explain

{
  since => '0.01',
}

=example-1 explain

  # given: synopsis;

  my $explain = $search->explain;

  # "hello world"

=cut

$test->for('example', 1, 'explain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "hello world";

  $result
});

=method get

The get method returns the subject of the regular expression operation.

=signature get

  get() (string)

=metadata get

{
  since => '0.01',
}

=example-1 get

  # given: synopsis;

  my $get = $search->get;

  # "hello world"

=cut

$test->for('example', 1, 'get', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "hello world";

  $result
});

=method count

The count method returns the number of matches found in the result object which
contains information about the results of the regular expression operation.

=signature count

  count() (number)

=metadata count

{
  since => '0.01',
}

=example-1 count

  # given: synopsis;

  my $count = $search->count;

  # 1

=cut

$test->for('example', 1, 'count', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method initial

The initial method returns the unaltered string from the result object which
contains information about the results of the regular expression operation.

=signature initial

  initial() (string)

=metadata initial

{
  since => '0.01',
}

=example-1 initial

  # given: synopsis;

  my $initial = $search->initial;

  # "hello world"

=cut

$test->for('example', 1, 'initial', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "hello world";

  $result
});

=method last_match_end

The last_match_end method returns an array of offset positions into the string
where the capture(s) stopped matching from the result object which contains
information about the results of the regular expression operation.

=signature last_match_end

  last_match_end() (maybe[within[arrayref, number]])

=metadata last_match_end

{
  since => '0.01',
}

=example-1 last_match_end

  # given: synopsis;

  my $last_match_end = $search->last_match_end;

  # [5, 5]

=cut

$test->for('example', 1, 'last_match_end', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [5, 5];

  $result
});

=method last_match_start

The last_match_start method returns an array of offset positions into the
string where the capture(s) matched from the result object which contains
information about the results of the regular expression operation.

=signature last_match_start

  last_match_start() (maybe[within[arrayref, number]])

=metadata last_match_start

{
  since => '0.01',
}

=example-1 last_match_start

  # given: synopsis;

  my $last_match_start = $search->last_match_start;

  # [0, 0]

=cut

$test->for('example', 1, 'last_match_start', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [0, 0];

  $result
});

=method matched

The matched method returns the portion of the string that matched from the
result object which contains information about the results of the regular
expression operation.

=signature matched

  matched() (maybe[string])

=metadata matched

{
  since => '0.01',
}

=example-1 matched

  # given: synopsis;

  my $matched = $search->matched;

  # "hello"

=cut

$test->for('example', 1, 'matched', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "hello";

  $result
});

=method named_captures

The named_captures method returns a hash containing the requested named regular
expressions and captured string pairs from the result object which contains
information about the results of the regular expression operation.

=signature named_captures

  named_captures() (hashref)

=metadata named_captures

{
  since => '0.01',
}

=example-1 named_captures

  # given: synopsis;

  my $named_captures = $search->named_captures;

  # {}

=cut

$test->for('example', 1, 'named_captures', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 named_captures

  package main;

  use Venus::Search;

  my $search = Venus::Search->new(
    string => 'hello world',
    regexp => '(?<locale>world)',
  );

  my $named_captures = $search->named_captures;

  # { locale => ["world"] }

=cut

$test->for('example', 2, 'named_captures', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, { locale => ["world"] };

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Search)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Search;

  my $new = Venus::Search->new;

  # bless(..., "Venus::Search")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Search');
  is $result->string, '';
  is $result->regexp, qr//;

  !$result
});

=example-2 new

  package main;

  use Venus::Search;

  my $new = Venus::Search->new(
    string => 'hello world',
    regexp => '(hello)',
  );

  # bless(..., "Venus::Search")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Search');
  is $result->string, 'hello world';
  is $result->regexp, '(hello)';

  $result
});

=method prematched

The prematched method returns the portion of the string before the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

=signature prematched

  prematched() (maybe[string])

=metadata prematched

{
  since => '0.01',
}

=example-1 prematched

  # given: synopsis;

  my $prematched = $search->prematched;

  # ""

=cut

$test->for('example', 1, 'prematched', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result eq '';

  !$result
});

=method postmatched

The postmatched method returns the portion of the string after the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

=signature postmatched

  postmatched() (maybe[string])

=metadata postmatched

{
  since => '0.01',
}

=example-1 postmatched

  # given: synopsis;

  my $postmatched = $search->postmatched;

  # " world"

=cut

$test->for('example', 1, 'postmatched', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq " world";

  $result
});

=method set

The set method sets the subject of the regular expression operation.

=signature set

  set(string $string) (string)

=metadata set

{
  since => '0.01',
}

=example-1 set

  # given: synopsis;

  my $set = $search->set('hello universe');

  # "hello universe"

=cut

$test->for('example', 1, 'set', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "hello universe";

  $result
});

=raise evaluate Venus::Search::Error on.evaluate

  package main;

  use Venus::Search;

  my $search = Venus::Search->new(
    string => 'hello world',
    regexp => 'world',
    flags => 'i',
  );

  $search->evaluate;

  $search->flags('q');

  $search->evaluate;

  # Error! (on.evaluate)

=cut

$test->for('raise', 'evaluate', 'Venus::Search::Error', 'on.evaluate', sub {
  my ($tryable) = @_;

  $test->is_error(my $error = $tryable->error->result);

  $error
});

=operator (.)

This package overloads the C<.> operator.

=cut

$test->for('operator', '(.)');

=example-1 (.)

  # given: synopsis;

  my $result = $search . ', welcome';

  # "hello world, welcome"

=cut

$test->for('example', 1, '(.)', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "hello world, welcome";

  $result
});

=operator (eq)

This package overloads the C<eq> operator.

=cut

$test->for('operator', '(eq)');

=example-1 (eq)

  # given: synopsis;

  my $result = $search eq 'hello world';

  # 1

=cut

$test->for('example', 1, '(eq)', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=operator (ne)

This package overloads the C<ne> operator.

=cut

$test->for('operator', '(ne)');

=example-1 (ne)

  # given: synopsis;

  my $result = $search ne 'Hello world';

  # 1

=cut

$test->for('example', 1, '(ne)', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=operator (qr)

This package overloads the C<qr> operator.

=cut

$test->for('operator', '(qr)');

=example-1 (qr)

  # given: synopsis;

  my $result = 'hello world, welcome' =~ qr/$search/;

  # 1

=cut

$test->for('example', 1, '(qr)', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=operator ("")

This package overloads the C<""> operator.

=cut

$test->for('operator', '("")');

=example-1 ("")

  # given: synopsis;

  my $result = "$search";

  # "hello world"

=cut

$test->for('example', 1, '("")', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'hello world';

  $result
});

=example-2 ("")

  # given: synopsis;

  my $result = "$search, $search";

  # "hello world, hello world"

=cut

$test->for('example', 2, '("")', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'hello world, hello world';

  $result
});

=operator (~~)

This package overloads the C<~~> operator.

=cut

$test->for('operator', '(~~)');

=example-1 (~~)

  # given: synopsis;

  my $result = $search ~~ 'hello world';

  # 1

=cut

$test->for('example', 1, '(~~)', sub {
  1;
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Search.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;