package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Task::Venus::Gen

=cut

$test->for('name');

=tagline

vns gen

=cut

$test->for('tagline');

=abstract

Task Class for Venus CLI

=cut

$test->for('abstract');

=includes

method: new
method: perform

=cut

=synopsis

  package main;

  use Venus::Task::Venus::Gen;

  my $task = Venus::Task::Venus::Gen->new;

  # bless(.., 'Venus::Task::Venus::Gen')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result
});

=description

This package is a task class for the C<vns-gen> CLI, and C<vns gen>
sub-command.

=cut

$test->for('description');

=inherits

Venus::Task::Venus

=cut

$test->for('inherits');

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Task::Venus::Gen)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Task::Venus::Gen;

  my $task = Venus::Task::Venus::Gen->new;

  # bless({...}, 'Venus::Task::Venus::Gen')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Gen');
  ok $result->isa('Venus::Task');

  $result
});

=method perform

The perform method executes the CLI logic.

=signature perform

  perform() (Venus::Task::Venus::Gen)

=metadata perform

{
  since => '4.15',
}

=example-1 perform

  # given: synopsis

  package main;

  $task->prepare;

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

=cut

$test->for('example', 1, 'perform', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Gen');
  ok !$result->output;

  $result
});

=example-2 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('--stdout', '--class');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

  # ...

=cut

$test->for('example', 2, 'perform', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $output = <<'EOF';
package Example;

use 5.018;

use strict;
use warnings;

# VENUS

use Venus::Class;

1;
EOF
  chomp $output;
  ok $result->isa('Venus::Task::Venus::Gen');
  is $result->output, $output;

  $result
});

=example-3 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('--stdout', '--class', '--name', 'MyApp');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

  # ...

=cut

$test->for('example', 3, 'perform', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $output = <<'EOF';
package MyApp;

use 5.018;

use strict;
use warnings;

# VENUS

use Venus::Class;

1;
EOF
  chomp $output;
  ok $result->isa('Venus::Task::Venus::Gen');
  is $result->output, $output;

  $result
});

=example-4 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('-pc', '--name', 'MyApp', '--method', 'execute');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

  # ...

=cut

$test->for('example', 4, 'perform', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $output = <<'EOF';
package MyApp;

use 5.018;

use strict;
use warnings;

# VENUS

use Venus::Class;

# METHODS

sub execute {
  my ($self, @args) = @_;

  return $self;
}

1;
EOF
  chomp $output;
  ok $result->isa('Venus::Task::Venus::Gen');
  is $result->output, $output;

  $result
});

=example-5 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('-pc', '--name', 'MyApp', '--attr', 'domain', '--method', 'execute');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

  # ...

=cut

$test->for('example', 5, 'perform', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $output = <<'EOF';
package MyApp;

use 5.018;

use strict;
use warnings;

# VENUS

use Venus::Class 'attr';

# ATTRIBUTES

attr 'domain';

# METHODS

sub execute {
  my ($self, @args) = @_;

  return $self;
}

1;
EOF
  chomp $output;
  ok $result->isa('Venus::Task::Venus::Gen');
  is $result->output, $output;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

$test->render('lib/Venus/Task/Venus/Gen.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;