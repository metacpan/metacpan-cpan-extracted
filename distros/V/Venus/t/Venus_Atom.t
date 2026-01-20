package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Atom

=cut

$test->for('name');

=tagline

Atom Class

=cut

$test->for('tagline');

=abstract

Atom Class for Perl 5

=cut

$test->for('abstract');

=includes

method: get
method: set
method: new

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Atom;

  my $atom = Venus::Atom->new;

  # $atom->get;

  # undef

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Atom');

  !$result
});

=description

This package provides a write-once object representing a constant value.

=cut

$test->for('description');

=inherits

Venus::Sealed

=cut

$test->for('inherits');

=method get

The get method can be used to get the underlying constant value set during
instantiation.

=signature get

  get() (any)

=metadata get

{
  since => '3.55',
}

=cut

=example-1 get

  # given: synopsis

  package main;

  my $get = $atom->get;

  # undef

=cut

$test->for('example', 1, 'get', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-2 get

  # given: synopsis

  package main;

  $atom->set("hello");

  my $get = $atom->get;

  # "hello"

=cut

$test->for('example', 2, 'get', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, "hello";

  $result
});

=method set

The set method can be used to set the underlying constant value set during
instantiation or via this method. An atom can only be set once, either at
instantiation of via this method. Any attempt to re-set the atom will result in
an error.

=signature set

  set(any $data) (any)

=metadata set

{
  since => '3.55',
}

=cut

=example-1 set

  # given: synopsis

  package main;

  my $set = $atom->set("hello");

  # "hello"

=cut

$test->for('example', 1, 'set', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, "hello";

  $result
});

=raise set Venus::Atom::Error on.set

  # given: synopsis

  package main;

  my $set = $atom->set("hello");

  $atom->set("hello");

  # Error! (on.set)

=cut

$test->for('raise', 'set', 'Venus::Atom::Error', 'on.set', sub {
  my ($tryable) = @_;

  $test->is_error(my $error = $tryable->error->result);

  $error
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Atom)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Atom;

  my $new = Venus::Atom->new;

  # bless(..., "Venus::Atom")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Atom');
  ok $result->{scope};

  !$result
});

=example-2 new

  package main;

  use Venus::Atom;

  my $new = Venus::Atom->new('Important');

  # bless(..., "Venus::Atom")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Atom');
  ok $result->{scope};

  $result
});

=example-3 new

  package main;

  use Venus::Atom;

  my $new = Venus::Atom->new(value => 'Important');

  # bless(..., "Venus::Atom")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Atom');
  ok $result->{scope};

  $result
});

=operator ("")

This package overloads the C<""> operator.

=cut

$test->for('operator', '("")');

=example-1 ("")

  # given: synopsis;

  my $result = "$atom";

  # ""

=cut

$test->for('example', 1, '("")', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 ("")

  # given: synopsis;

  $atom->set("hello");

  my $result = "$atom";

  # "hello"

=cut

$test->for('example', 2, '("")', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "hello";

  $result
});

=operator (eq)

This package overloads the C<eq> operator.

=cut

$test->for('operator', '(eq)');

=example-1 (eq)

  # given: synopsis;

  my $result = $atom eq "";

  # 1

=cut

$test->for('example', 1, '(eq)', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 (eq)

  # given: synopsis;

  $atom->set("hello");

  my $result = $atom eq "hello";

  # 1

=cut

$test->for('example', 1, '(eq)', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result == 1;

  $result
});

=operator (ne)

This package overloads the C<ne> operator.

=cut

$test->for('operator', '(ne)');

=example-1 (ne)

  # given: synopsis;

  my $result = $atom ne "";

  # 0

=cut

$test->for('example', 1, '(ne)', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !$result;

  !$result
});

=example-2 (ne)

  # given: synopsis;

  $atom->set("hello");

  my $result = $atom ne "";

  # 1

=cut

$test->for('example', 2, '(ne)', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result == 1;

  $result
});

=operator (qr)

This package overloads the C<qr> operator.

=cut

$test->for('operator', '(qr)');

=example-1 (qr)

  # given: synopsis;

  my $test = 'hello' =~ qr/$atom/;

  # 1

=cut

$test->for('example', 1, '(qr)', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result == 1;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Atom.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
