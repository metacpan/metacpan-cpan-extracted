package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

if (require Venus::Yaml && not Venus::Yaml->package) {
  diag 'No suitable YAML library found' if $ENV{VENUS_DEBUG};
  goto SKIP;
}

my $test = test(__FILE__);

=name

Venus::Yaml

=cut

$test->for('name');

=tagline

Yaml Class

=cut

$test->for('tagline');

=abstract

Yaml Class for Perl 5

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

  use Venus::Yaml;

  my $yaml = Venus::Yaml->new(
    value => { name => ['Ready', 'Robot'], version => 0.12, stable => !!1, }
  );

  # $yaml->encode;

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Yaml');

  $result
});

=description

This package provides methods for reading and writing L<YAML|https://yaml.org>
data. B<Note:> This package requires that a suitable YAML library is installed,
currently either C<YAML::XS> C<0.67+>, C<YAML::PP::LibYAML> C<0.004+>, or
C<YAML::PP> C<0.23+>. You can use the C<VENUS_YAML_PACKAGE> environment
variable to include or prioritize your preferred YAML library.

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

The decode method decodes the YAML string, sets the object value, and returns
the decoded value.

=signature decode

  decode(string $yaml) (any)

=metadata decode

{
  since => '0.01',
}

=example-1 decode

  # given: synopsis;

  my $decode = $yaml->decode("codename: ['Ready','Robot']\nstable: true");

  # { codename => ["Ready", "Robot"], stable => 1 }

=cut

$test->for('example', 1, 'decode', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, { codename => ["Ready", "Robot"], stable => 1 };

  $result
});

=method encode

The encode method encodes the objects value as a YAML string and returns the
encoded string.

=signature encode

  encode() (string)

=metadata encode

{
  since => '0.01',
}

=example-1 encode

  # given: synopsis;

  my $encode = $yaml->encode;

  # "---\nname:\n- Ready\n- Robot\nstable: true\nversion: 0.12\n"

=cut

$test->for('example', 1, 'encode', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "---\nname:\n- Ready\n- Robot\nstable: true\nversion: 0.12\n";

  $result
});

=raise new Venus::Yaml::Error on.config

  package main;

  use Venus::Yaml;

  local $ENV{VENUS_YAML_PACKAGE} = 'Fake::Yaml';

  my $new = Venus::Yaml->new;

  # Error! (on.config)

=cut

$test->for('raise', 'new', 'Venus::Yaml::Error', 'on.config', sub {
  my ($tryable) = @_;

  $test->type(my $result = $tryable->result, 'Venus::Yaml');

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Yaml)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Yaml;

  my $new = Venus::Yaml->new;

  # bless(..., "Venus::Yaml")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Yaml');

  $result
});

=example-2 new

  package main;

  use Venus::Yaml;

  my $new = Venus::Yaml->new(value => {password => 'secret'});

  # bless(..., "Venus::Yaml")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Yaml');
  is_deeply $result->value, {password => 'secret'};

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Yaml.pod') if $ENV{VENUS_RENDER};

SKIP:
ok 1 and done_testing;
