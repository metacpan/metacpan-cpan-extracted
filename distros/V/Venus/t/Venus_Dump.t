package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Dump

=cut

$test->for('name');

=tagline

Dump Class

=cut

$test->for('tagline');

=abstract

Dump Class for Perl 5

=cut

$test->for('abstract');

=includes

method: decode
method: encode
method: new

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Dump;

  my $dump = Venus::Dump->new(
    value => { name => ['Ready', 'Robot'], version => 0.12, stable => !!1, }
  );

  # $dump->encode;

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=description

This package provides methods for reading and writing dumped (i.e.
stringified) Perl data.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Accessible
Venus::Role::Buildable
Venus::Role::Explainable
Venus::Role::Valuable

=cut

$test->for('integrates');

=attributes

decoder: rw, opt, CodeRef
encoder: rw, opt, CodeRef

=cut

$test->for('attributes');

=method decode

The decode method decodes the Perl string, sets the object value, and returns
the decoded value.

=signature decode

  decode(string $text) (any)

=metadata decode

{
  since => '0.01',
}

=example-1 decode

  # given: synopsis;

  my $decode = $dump->decode('{codename=>["Ready","Robot"],stable=>!!1}');

  # { codename => ["Ready", "Robot"], stable => 1 }

=cut

$test->for('example', 1, 'decode', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, { codename => ["Ready", "Robot"], stable => 1 };

  $result
});

=method encode

The encode method encodes the objects value as a Perl string and returns the
encoded string.

=signature encode

  encode() (string)

=metadata encode

{
  since => '0.01',
}

=example-1 encode

  # given: synopsis;

  my $encode = $dump->encode;

  # '{name => ["Ready","Robot"], stable => !!1, version => "0.12"}'

=cut

$test->for('example', 1, 'encode', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  $result =~ s/[\n\s]//g;
  ok $result eq '{name=>["Ready","Robot"],stable=>bless({},\'Venus::True\'),version=>"0.12"}';

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Dump)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Dump;

  my $new = Venus::Dump->new;

  # bless(..., "Venus::Dump")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Dump');

  $result
});

=example-2 new

  package main;

  use Venus::Dump;

  my $new = Venus::Dump->new({password => 'secret'});

  # bless(..., "Venus::Dump")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Dump');
  is_deeply $result->value, {password => 'secret'};

  $result
});

=example-3 new

  package main;

  use Venus::Dump;

  my $new = Venus::Dump->new(value => {password => 'secret'});

  # bless(..., "Venus::Dump")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Dump');
  is_deeply $result->value, {password => 'secret'};

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Dump.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
