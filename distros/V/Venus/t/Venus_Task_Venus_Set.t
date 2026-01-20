package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Task::Venus::Set

=cut

$test->for('name');

=tagline

vns set

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

  use Venus::Task::Venus::Set;

  my $task = Venus::Task::Venus::Set->new;

  # bless(..., "Venus::Task::Venus::Set")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Set');

  $result
});

=description

This package is a task class for the C<vns-set> CLI, and C<vns set>
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

  new(any @args) (Venus::Task::Venus::Set)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Task::Venus::Set;

  my $task = Venus::Task::Venus::Set->new;

  # bless({...}, 'Venus::Task::Venus::Set')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Set');
  ok $result->isa('Venus::Task');

  $result
});

=method perform

The perform method executes the CLI logic.

=signature perform

  perform() (Venus::Task::Venus::Set)

=metadata perform

{
  since => '4.15',
}

=example-1 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl.perl', '$PERL');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Set')

=cut

$test->for('example', 1, 'perform', sub {
  my ($tryable) = @_;
  require Venus::Path;
  my $path = Venus::Path->new('t/conf/.vns.pl');
  my $temp = Venus::Path->new->mktemp_dir->child('.vns.pl');
  $path->copy($temp);
  local $ENV{VENUS_FILE} = "$temp";
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Set');
  my $value = $result->output;
  is $value, '$PERL';
  $temp->unlink;

  $result
});

=example-2 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl.prove', '$PROVE');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Set')

=cut

$test->for('example', 2, 'perform', sub {
  my ($tryable) = @_;
  require Venus::Path;
  my $path = Venus::Path->new('t/conf/.vns.pl');
  my $temp = Venus::Path->new->mktemp_dir->child('.vns.pl');
  $path->copy($temp);
  local $ENV{VENUS_FILE} = "$temp";
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Set');
  my $value = $result->output;
  is $value, '$PROVE';
  $temp->unlink;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

$test->render('lib/Venus/Task/Venus/Set.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;