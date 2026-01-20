package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Task::Venus::Get

=cut

$test->for('name');

=tagline

vns get

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

  use Venus::Task::Venus::Get;

  my $task = Venus::Task::Venus::Get->new;

  # bless(..., "Venus::Task::Venus::Get")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Get');

  $result
});

=description

This package is a task class for the C<vns-get> CLI, and C<vns get>
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

  new(any @args) (Venus::Task::Venus::Get)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Task::Venus::Get;

  my $task = Venus::Task::Venus::Get->new;

  # bless({...}, 'Venus::Task::Venus::Get')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Get');
  ok $result->isa('Venus::Task');

  $result
});

=method perform

The perform method executes the CLI logic.

=signature perform

  perform() (Venus::Task::Venus::Get)

=metadata perform

{
  since => '4.15',
}

=example-1 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl.perl');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Get')

=cut

$test->for('example', 1, 'perform', sub {
  my ($tryable) = @_;
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Get');
  my $value = $result->output;
  is $value, 'perl';

  $result
});

=example-2 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl.prove');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Get')

=cut

$test->for('example', 2, 'perform', sub {
  my ($tryable) = @_;
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Get');
  my $value = $result->output;
  is $value, 'prove';

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

$test->render('lib/Venus/Task/Venus/Get.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;