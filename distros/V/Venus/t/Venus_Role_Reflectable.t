package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Role::Reflectable

=cut

$test->for('name');

=tagline

Reflectable Role

=cut

$test->for('tagline');

=abstract

Reflectable Role for Perl 5

=cut

$test->for('abstract');

=includes

method: class
method: clone
method: meta
method: reify
method: space
method: what

=cut

$test->for('includes');

=synopsis

  package Example;

  use Venus::Class;

  with 'Venus::Role::Reflectable';

  sub test {
    true
  }

  package main;

  my $example = Example->new;

  # $example->space;

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Reflectable');

  $result
});

=description

This package modifies the consuming package and provides methods for
introspecting the object and its underlying package.

=cut

$test->for('description');

=method class

The class method returns the class name for the given class or object.

=signature class

  class() (string)

=metadata class

{
  since => '0.01',
}

=example-1 class

  # given: synopsis;

  my $class = $example->class;

  # "Example"

=cut

$test->for('example', 1, 'class', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "Example";

  $result
});

=method clone

The clone method clones the invocant and returns the result.

=signature clone

  clone() (object)

=metadata clone

{
  since => '4.15',
}

=cut

=example-1 clone

  # given: synopsis

  package main;

  my $clone = $example->clone;

  # bless(..., "Example")

=cut

$test->for('example', 1, 'clone', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa("Example");

  require Scalar::Util;
  isnt Scalar::Util::refaddr($result), Scalar::Util::refaddr($result->clone);

  $result
});

=method meta

The meta method returns a L<Venus::Meta> object for the given object.

=signature meta

  meta() (Venus::Meta)

=metadata meta

{
  since => '1.23',
}

=example-1 meta

  # given: synopsis;

  my $meta = $example->meta;

  # bless({name => "Example"}, "Venus::Meta")

=cut

$test->for('example', 1, 'meta', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa("Venus::Meta");

  $result
});

=method reify

The reify method dispatches the method call or executes the callback and
returns the result as a value object.

=signature reify

  reify(string | coderef $code, any @args) (object)

=metadata reify

{
  since => '1.23',
}

=example-1 reify

  # given: synopsis

  package main;

  my $reify = $example->reify;

  # bless({}, "Example")

=cut

$test->for('example', 1, 'reify', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');

  $result
});

=example-2 reify

  # given: synopsis

  package main;

  my $reify = $example->reify('class');

  # bless({value => "Example"}, "Venus::String")

=cut

$test->for('example', 2, 'reify', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::String');
  ok $result->value eq 'Example';

  $result
});

=example-3 reify

  # given: synopsis

  package main;

  my $reify = $example->reify('test');

  # bless({value => 1}, "Venus::Boolean")

=cut

$test->for('example', 3, 'reify', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Boolean');
  ok $result->value == 1;

  $result
});

=method space

The space method returns a L<Venus::Space> object for the given object.

=signature space

  space() (Venus::Space)

=metadata space

{
  since => '0.01',
}

=example-1 space

  # given: synopsis;

  my $space = $example->space;

  # bless({ value => "Example" }, "Venus::Space")

=cut

$test->for('example', 1, 'space', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Space');

  $result
});

=method what

The what method dispatches the method call or executes the callback and returns
the result as a L<Venus::What> object.

=signature what

  what(string | coderef $code, any @args) (Venus::What)

=metadata what

{
  since => '0.01',
}

=example-1 what

  # given: synopsis;

  my $what = $example->what;

  # bless({ value => bless({}, "Example") }, "Venus::What")

=cut

$test->for('example', 1, 'what', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::What');
  ok $result->value->isa('Example');

  $result
});

=example-2 what

  # given: synopsis;

  my $what = $example->what('class');

  # bless({ value => "Example" }, "Venus::What")

=cut

$test->for('example', 2, 'what', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::What');
  ok $result->value eq 'Example';

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Role/Reflectable.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
