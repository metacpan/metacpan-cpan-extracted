package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus::Space;
use Venus;

my $test = test(__FILE__);

=name

Venus::Task::Venus

=cut

$test->for('name');

=tagline

vns

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

  use Venus::Task::Venus;

  my $task = Venus::Task::Venus->new;

  # bless({...}, 'Venus::Task::Venus')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus');

  $result
});

=description

This package is the task class for the C<vns> CLI.

=cut

$test->for('description');

=inherits

Venus::Task

=cut

$test->for('inherits');

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Task::Venus)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Task::Venus;

  my $task = Venus::Task::Venus->new;

  # bless({...}, 'Venus::Task::Venus')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus');
  ok $result->isa('Venus::Task');

  $result
});

=method perform

The perform method executes the CLI logic.

=signature perform

  perform() (Venus::Task::Venus)

=metadata perform

{
  since => '4.15',
}

=example-1 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('');

  my $perform = $task->perform;

  # bless({...}, 'Venus::Task::Venus')

  # ''

=cut

$test->for('example', 1, 'perform', sub {
  my ($tryable) = @_;
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus');
  # Empty string shows help (no actual command to run)
  ok $result->has_output;

  $result
});

=example-2 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('die');

  my $perform = $task->perform;

  # bless({...}, 'Venus::Task::Venus')

  # ''

=cut

$test->for('example', 2, 'perform', sub {
  my ($tryable) = @_;
  my $handled = [];
  require Venus::Task::Venus::Run;
  my $patched_perform = Venus::Space->new('Venus::Task::Venus::Run')->patch('perform', sub {
    my ($code, $task, @args) = @_; $handled = [@{$task->data}]; return $task;
  });
  my $patched_exit = Venus::Space->new('Venus::Cli')->patch('exit', sub {
    my ($code, $self, @args) = @_; return $self;
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus');
  ok !$result->has_output_error_events;
  my $error = $result->output_error_events;
  is_deeply $error, [];
  is_deeply $handled, ['die'];
  $patched_exit->unpatch;
  $patched_perform->unpatch;

  $result
});

=example-3 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('gen', '--stdout', '--class');

  my $perform = $task->perform;

  # bless({...}, 'Venus::Task::Venus')

  # '...'

=cut

$test->for('example', 3, 'perform', sub {
  my ($tryable) = @_;
  my $handled = [];
  require Venus::Task::Venus::Gen;
  my $patched_perform = Venus::Space->new('Venus::Task::Venus::Gen')->patch('perform', sub {
    my ($code, $task, @args) = @_; $handled = [@{$task->data}]; return $task;
  });
  my $patched_exit = Venus::Space->new('Venus::Cli')->patch('exit', sub {
    my ($code, $self, @args) = @_; return $self;
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus');
  ok !$result->has_output_error_events;
  my $error = $result->output_error_events;
  is_deeply $error, [];
  is_deeply $handled, ['--stdout', '--class'];
  $patched_exit->unpatch;
  $patched_perform->unpatch;

  $result
});

=example-4 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('get', 'perl.repl');

  my $perform = $task->perform;

  # bless({...}, 'Venus::Task::Venus')

  # '...'

=cut

$test->for('example', 4, 'perform', sub {
  my ($tryable) = @_;
  my $handled = [];
  require Venus::Task::Venus::Get;
  my $patched_perform = Venus::Space->new('Venus::Task::Venus::Get')->patch('perform', sub {
    my ($code, $task, @args) = @_; $handled = [@{$task->data}]; return $task;
  });
  my $patched_exit = Venus::Space->new('Venus::Cli')->patch('exit', sub {
    my ($code, $self, @args) = @_; return $self;
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus');
  ok !$result->has_output_error_events;
  my $error = $result->output_error_events;
  is_deeply $error, [];
  is_deeply $handled, ['perl.repl'];
  $patched_exit->unpatch;
  $patched_perform->unpatch;

  $result
});

=example-5 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('new', 'yaml');

  my $perform = $task->perform;

  # bless({...}, 'Venus::Task::Venus')

  # '...'

=cut

$test->for('example', 5, 'perform', sub {
  my ($tryable) = @_;
  my $handled = [];
  require Venus::Task::Venus::New;
  my $patched_perform = Venus::Space->new('Venus::Task::Venus::New')->patch('perform', sub {
    my ($code, $task, @args) = @_; $handled = [@{$task->data}]; return $task;
  });
  my $patched_exit = Venus::Space->new('Venus::Cli')->patch('exit', sub {
    my ($code, $self, @args) = @_; return $self;
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus');
  ok !$result->has_output_error_events;
  my $error = $result->output_error_events;
  is_deeply $error, [];
  is_deeply $handled, ['yaml'];
  $patched_exit->unpatch;
  $patched_perform->unpatch;

  $result
});

=example-6 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('run', 'okay', 't/Venus.t');

  my $perform = $task->perform;

  # bless({...}, 'Venus::Task::Venus')

  # '...'

=cut

$test->for('example', 6, 'perform', sub {
  my ($tryable) = @_;
  my $handled = [];
  require Venus::Task::Venus::Run;
  my $patched_perform = Venus::Space->new('Venus::Task::Venus::Run')->patch('perform', sub {
    my ($code, $task, @args) = @_; $handled = [@{$task->data}]; return $task;
  });
  my $patched_exit = Venus::Space->new('Venus::Cli')->patch('exit', sub {
    my ($code, $self, @args) = @_; return $self;
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus');
  ok !$result->has_output_error_events;
  my $error = $result->output_error_events;
  is_deeply $error, [];
  is_deeply $handled, ['okay', 't/Venus.t'];
  $patched_exit->unpatch;
  $patched_perform->unpatch;

  $result
});

=example-7 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('set', 'perl.repl', '$PERL -dE0');

  my $perform = $task->perform;

  # bless({...}, 'Venus::Task::Venus')

  # '...'

=cut

$test->for('example', 7, 'perform', sub {
  my ($tryable) = @_;
  my $handled = [];
  require Venus::Task::Venus::Set;
  my $patched_perform = Venus::Space->new('Venus::Task::Venus::Set')->patch('perform', sub {
    my ($code, $task, @args) = @_; $handled = [@{$task->data}]; return $task;
  });
  my $patched_exit = Venus::Space->new('Venus::Cli')->patch('exit', sub {
    my ($code, $self, @args) = @_; return $self;
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus');
  ok !$result->has_output_error_events;
  my $error = $result->output_error_events;
  is_deeply $error, [];
  is_deeply $handled, ['perl.repl', '$PERL -dE0'];
  $patched_exit->unpatch;
  $patched_perform->unpatch;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

$test->render('lib/Venus/Task/Venus.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
